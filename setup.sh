#!/bin/bash

# Wisecow Assessment Setup Script
# This script sets up the complete environment for the Wisecow application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="wisecow"
IMAGE_NAME="wisecow"
IMAGE_TAG="latest"
KUBEARMOR_VERSION="v1.1.0"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check if running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        warning "This script is designed for Linux. Some features may not work on other platforms."
    fi

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        info "kubectl not found. Installing kubectl..."
        install_kubectl
    fi

    # Check if kind is available (for local Kubernetes)
    if ! command -v kind &> /dev/null; then
        info "kind not found. Installing kind..."
        install_kind
    fi

    log "Prerequisites check completed"
}

# Install kubectl
install_kubectl() {
    log "Installing kubectl..."

    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    # Make kubectl executable
    chmod +x kubectl

    # Move to system path
    sudo mv kubectl /usr/local/bin/

    # Verify installation
    kubectl version --client

    log "kubectl installed successfully"
}

# Install kind (Kubernetes in Docker)
install_kind() {
    log "Installing kind..."

    # Download kind
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

    # Make kind executable
    chmod +x ./kind

    # Move to system path
    sudo mv ./kind /usr/local/bin/kind

    log "kind installed successfully"
}

# Create local Kubernetes cluster
create_cluster() {
    log "Creating local Kubernetes cluster..."

    # Check if cluster already exists
    if kind get clusters | grep -q "wisecow-cluster"; then
        warning "Cluster 'wisecow-cluster' already exists. Skipping creation."
        return
    fi

    # Create kind cluster configuration
    cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: wisecow-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF

    # Create the cluster
    kind create cluster --config kind-config.yaml

    # Wait for cluster to be ready
    kubectl wait --for=condition=Ready nodes --all --timeout=300s

    log "Kubernetes cluster created successfully"
}

# Install NGINX Ingress Controller
install_ingress() {
    log "Installing NGINX Ingress Controller..."

    # Apply NGINX Ingress Controller manifests
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

    # Wait for ingress controller to be ready
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s

    log "NGINX Ingress Controller installed successfully"
}

# Install KubeArmor
install_kubearmor() {
    log "Installing KubeArmor..."

    # Add KubeArmor Helm repository
    if ! command -v helm &> /dev/null; then
        info "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    # Add KubeArmor repository
    helm repo add kubearmor https://kubearmor.github.io/charts
    helm repo update

    # Install KubeArmor
    helm upgrade --install kubearmor-operator kubearmor/kubearmor-operator -n kubearmor --create-namespace

    # Wait for KubeArmor to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kubearmor-operator -n kubearmor --timeout=300s

    log "KubeArmor installed successfully"
}

# Create namespace
create_namespace() {
    log "Creating namespace '$NAMESPACE'..."

    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        warning "Namespace '$NAMESPACE' already exists"
    else
        kubectl create namespace "$NAMESPACE"
        log "Namespace '$NAMESPACE' created"
    fi
}

# Build Docker image
build_image() {
    log "Building Docker image..."

    # Make wisecow.sh executable
    chmod +x wisecow.sh

    # Build the Docker image
    docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

    # Load image into kind cluster
    kind load docker-image "$IMAGE_NAME:$IMAGE_TAG" --name wisecow-cluster

    log "Docker image built and loaded into cluster"
}

# Deploy application
deploy_application() {
    log "Deploying Wisecow application..."

    # Apply Kubernetes manifests
    kubectl apply -f k8s-manifests/ -n "$NAMESPACE"

    # Wait for deployment to be ready
    kubectl wait --for=condition=available deployment/wisecow-deployment -n "$NAMESPACE" --timeout=300s

    log "Application deployed successfully"
}

# Apply security policies
apply_security_policies() {
    log "Applying KubeArmor security policies..."

    # Wait a bit for KubeArmor to be fully ready
    sleep 30

    # Apply security policies
    kubectl apply -f kubearmor/security-policies.yaml -n "$NAMESPACE"

    log "Security policies applied successfully"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring scripts..."

    # Make scripts executable
    chmod +x scripts/system_health_monitor.sh
    chmod +x scripts/app_health_checker.py

    # Install Python dependencies for health checker
    if command -v pip3 &> /dev/null; then
        pip3 install requests
    elif command -v pip &> /dev/null; then
        pip install requests
    else
        warning "pip not found. Please install Python requests library manually"
    fi

    log "Monitoring setup completed"
}

# Display access information
display_access_info() {
    log "Setup completed successfully!"
    echo ""
    echo -e "${GREEN}=== Access Information ===${NC}"
    echo -e "${BLUE}Local access:${NC} http://localhost"
    echo -e "${BLUE}Namespace:${NC} $NAMESPACE"
    echo ""
    echo -e "${GREEN}=== Useful Commands ===${NC}"
    echo -e "${BLUE}Check pods:${NC} kubectl get pods -n $NAMESPACE"
    echo -e "${BLUE}Check services:${NC} kubectl get services -n $NAMESPACE"
    echo -e "${BLUE}Check ingress:${NC} kubectl get ingress -n $NAMESPACE"
    echo -e "${BLUE}View logs:${NC} kubectl logs -f deployment/wisecow-deployment -n $NAMESPACE"
    echo -e "${BLUE}Port forward:${NC} kubectl port-forward service/wisecow-service 8080:80 -n $NAMESPACE"
    echo ""
    echo -e "${GREEN}=== Health Monitoring ===${NC}"
    echo -e "${BLUE}System health:${NC} ./scripts/system_health_monitor.sh"
    echo -e "${BLUE}App health:${NC} python3 scripts/app_health_checker.py --url http://localhost"
    echo ""
    echo -e "${GREEN}=== Security ===${NC}"
    echo -e "${BLUE}KubeArmor policies:${NC} kubectl get kubearmor-policies -n $NAMESPACE"
    echo -e "${BLUE}Security logs:${NC} kubectl logs -n kubearmor -l app.kubernetes.io/name=kubearmor"
}

# Main execution
main() {
    log "Starting Wisecow Assessment Setup..."

    check_prerequisites
    create_cluster
    install_ingress
    install_kubearmor
    create_namespace
    build_image
    deploy_application
    apply_security_policies
    setup_monitoring
    display_access_info

    log "All setup tasks completed successfully!"
}

# Handle script interruption
trap 'error "Setup interrupted by user"' SIGINT SIGTERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi