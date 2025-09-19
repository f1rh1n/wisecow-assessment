# Wisecow Deployment Guide

This comprehensive guide covers all deployment scenarios for the Wisecow application, from local development to production environments.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Production Deployment](#production-deployment)
- [Cloud Platform Specific Instructions](#cloud-platform-specific-instructions)
- [Security Configuration](#security-configuration)
- [Monitoring Setup](#monitoring-setup)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

## 🔧 Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 20.10+ | Container runtime |
| kubectl | 1.25+ | Kubernetes CLI |
| Helm | 3.8+ | Package manager (for KubeArmor) |
| kind | 0.18+ | Local Kubernetes (optional) |
| Git | 2.30+ | Version control |

### Required Resources

**Minimum System Requirements:**
- CPU: 2 cores
- Memory: 4GB RAM
- Disk: 10GB free space
- Network: Internet connectivity

**Kubernetes Cluster Requirements:**
- Kubernetes 1.25+
- At least 2 worker nodes (recommended)
- CNI plugin installed
- Ingress controller support

## 🏠 Local Development Setup

### Option 1: Automated Setup with Kind

The easiest way to get started is using the provided setup script:

```bash
# Clone the repository
git clone <repository-url>
cd wisecow-assessment

# Make setup script executable
chmod +x setup.sh

# Run automated setup
./setup.sh
```

**What the setup script does:**
1. Installs kind (if not present)
2. Creates a local Kubernetes cluster
3. Installs NGINX Ingress Controller
4. Installs KubeArmor for security policies
5. Builds and deploys the Wisecow application
6. Applies security policies
7. Sets up monitoring scripts

### Option 2: Manual Kind Setup

```bash
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

# Create cluster
kind create cluster --config kind-config.yaml

# Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
```

### Option 3: Docker Compose (Simplified)

For simple testing without Kubernetes:

```yaml
# docker-compose.yml
version: '3.8'
services:
  wisecow:
    build: .
    ports:
      - "4499:4499"
    restart: unless-stopped
```

```bash
# Run with Docker Compose
docker-compose up -d

# Access at http://localhost:4499
```

## 🚀 Production Deployment

### Step 1: Prepare the Environment

```bash
# Create namespace
kubectl create namespace wisecow

# Create secrets for TLS (if using custom certificates)
kubectl create secret tls wisecow-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n wisecow
```

### Step 2: Configure Environment-Specific Settings

**Update ingress configuration:**

```yaml
# k8s-manifests/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wisecow-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - your-domain.com  # Update with your domain
    secretName: wisecow-tls
  rules:
  - host: your-domain.com  # Update with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wisecow-service
            port:
              number: 80
```

### Step 3: Deploy the Application

```bash
# Build and push Docker image
docker build -t your-registry/wisecow:v1.0.0 .
docker push your-registry/wisecow:v1.0.0

# Update image in deployment
sed -i 's|wisecow:latest|your-registry/wisecow:v1.0.0|g' k8s-manifests/deployment.yaml

# Deploy application
kubectl apply -f k8s-manifests/ -n wisecow

# Verify deployment
kubectl get all -n wisecow
```

### Step 4: Install and Configure KubeArmor

```bash
# Add KubeArmor Helm repository
helm repo add kubearmor https://kubearmor.github.io/charts
helm repo update

# Install KubeArmor
helm upgrade --install kubearmor-operator kubearmor/kubearmor-operator \
  -n kubearmor --create-namespace

# Wait for KubeArmor to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=kubearmor-operator \
  -n kubearmor --timeout=300s

# Apply security policies
kubectl apply -f kubearmor/security-policies.yaml -n wisecow
```

### Step 5: Verification

```bash
# Run deployment tests
chmod +x test-deployment.sh
./test-deployment.sh

# Check application health
kubectl get pods -n wisecow
kubectl logs -f deployment/wisecow-deployment -n wisecow
```

## ☁️ Cloud Platform Specific Instructions

### Amazon EKS

```bash
# Create EKS cluster
eksctl create cluster --name wisecow-cluster --region us-west-2

# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

# Update ingress for ALB
cat <<EOF > k8s-manifests/ingress-eks.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wisecow-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  rules:
  - host: wisecow.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wisecow-service
            port:
              number: 80
EOF
```

### Google GKE

```bash
# Create GKE cluster
gcloud container clusters create wisecow-cluster \
  --zone us-central1-a \
  --num-nodes 3

# Get credentials
gcloud container clusters get-credentials wisecow-cluster --zone us-central1-a

# Deploy with Google Cloud Load Balancer
# Use the standard ingress configuration
```

### Azure AKS

```bash
# Create AKS cluster
az aks create \
  --resource-group wisecow-rg \
  --name wisecow-cluster \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group wisecow-rg --name wisecow-cluster

# Install NGINX Ingress for Azure
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

## 🔒 Security Configuration

### TLS Configuration

**Option 1: cert-manager with Let's Encrypt**

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

**Option 2: Custom Certificates**

```bash
# Create TLS secret
kubectl create secret tls wisecow-tls \
  --cert=server.crt \
  --key=server.key \
  -n wisecow
```

### Network Policies

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: wisecow-network-policy
  namespace: wisecow
spec:
  podSelector:
    matchLabels:
      app: wisecow
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 4499
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

### RBAC Configuration

```yaml
# rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: wisecow-sa
  namespace: wisecow
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: wisecow
  name: wisecow-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: wisecow-rolebinding
  namespace: wisecow
subjects:
- kind: ServiceAccount
  name: wisecow-sa
  namespace: wisecow
roleRef:
  kind: Role
  name: wisecow-role
  apiGroup: rbac.authorization.k8s.io
```

## 📊 Monitoring Setup

### Prometheus and Grafana

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

# Create ServiceMonitor for Wisecow
cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: wisecow-metrics
  namespace: wisecow
spec:
  selector:
    matchLabels:
      app: wisecow
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
EOF
```

### Application Monitoring

```bash
# Set up monitoring scripts
chmod +x scripts/system_health_monitor.sh
chmod +x scripts/app_health_checker.py

# Install Python dependencies
pip3 install requests

# Create systemd service for continuous monitoring
sudo tee /etc/systemd/system/wisecow-monitor.service > /dev/null <<EOF
[Unit]
Description=Wisecow Health Monitor
After=network.target

[Service]
Type=simple
User=monitor
WorkingDirectory=/opt/wisecow
ExecStart=/usr/bin/python3 /opt/wisecow/scripts/app_health_checker.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl enable wisecow-monitor
sudo systemctl start wisecow-monitor
```

### Log Aggregation

```bash
# Install Fluentd for log collection
kubectl apply -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/elasticsearch/fluent-bit-ds.yaml

# Configure log forwarding to your log aggregation service
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n wisecow

# Describe pod for events
kubectl describe pod <pod-name> -n wisecow

# Check logs
kubectl logs <pod-name> -n wisecow

# Common fixes:
# 1. Resource constraints
kubectl describe node

# 2. Image pull issues
kubectl describe pod <pod-name> -n wisecow | grep -A 10 Events

# 3. Configuration errors
kubectl get configmap -n wisecow
kubectl get secret -n wisecow
```

#### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl describe ingress wisecow-ingress -n wisecow

# Check service endpoints
kubectl get endpoints -n wisecow

# Test internal connectivity
kubectl run test-pod --image=curlimages/curl -it --rm -- \
  curl http://wisecow-service.wisecow.svc.cluster.local
```

#### KubeArmor Issues

```bash
# Check KubeArmor status
kubectl get pods -n kubearmor

# Check policy status
kubectl get kubearmor-policies -n wisecow

# View KubeArmor logs
kubectl logs -n kubearmor -l app.kubernetes.io/name=kubearmor

# Debug policy violations
kubectl logs -n kubearmor -l app.kubernetes.io/name=kubearmor | grep wisecow
```

#### Performance Issues

```bash
# Check resource usage
kubectl top pods -n wisecow
kubectl top nodes

# Check metrics
kubectl get --raw /metrics | grep wisecow

# Analyze logs for errors
kubectl logs deployment/wisecow-deployment -n wisecow --tail=100
```

### Health Check Debugging

```bash
# Manual health check
kubectl exec -it deployment/wisecow-deployment -n wisecow -- \
  curl -f http://localhost:4499

# Check health probe configuration
kubectl describe deployment wisecow-deployment -n wisecow | \
  grep -A 10 -B 10 Probe

# Test external accessibility
kubectl port-forward service/wisecow-service 8080:80 -n wisecow &
curl http://localhost:8080
```

## 🔄 Maintenance

### Updates and Upgrades

```bash
# Update application
docker build -t your-registry/wisecow:v1.1.0 .
docker push your-registry/wisecow:v1.1.0

# Rolling update
kubectl set image deployment/wisecow-deployment \
  wisecow=your-registry/wisecow:v1.1.0 -n wisecow

# Monitor rollout
kubectl rollout status deployment/wisecow-deployment -n wisecow

# Rollback if needed
kubectl rollout undo deployment/wisecow-deployment -n wisecow
```

### Backup and Recovery

```bash
# Backup Kubernetes resources
kubectl get all -n wisecow -o yaml > wisecow-backup.yaml

# Backup PVCs (if any)
kubectl get pvc -n wisecow -o yaml > wisecow-pvc-backup.yaml

# Restore from backup
kubectl apply -f wisecow-backup.yaml
```

### Scaling

```bash
# Horizontal scaling
kubectl scale deployment wisecow-deployment --replicas=5 -n wisecow

# Vertical scaling (update resources)
kubectl patch deployment wisecow-deployment -n wisecow -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"wisecow","resources":{"requests":{"cpu":"500m","memory":"128Mi"},"limits":{"cpu":"1000m","memory":"256Mi"}}}]}}}}'

# Horizontal Pod Autoscaler
kubectl autoscale deployment wisecow-deployment \
  --cpu-percent=70 --min=2 --max=10 -n wisecow
```

### Log Rotation and Cleanup

```bash
# Clean up old logs
kubectl logs deployment/wisecow-deployment -n wisecow --tail=0 --follow=false

# Set up log rotation for monitoring scripts
sudo logrotate -f /etc/logrotate.d/wisecow
```

## 📋 Deployment Checklist

### Pre-deployment

- [ ] Infrastructure requirements verified
- [ ] DNS records configured
- [ ] TLS certificates prepared
- [ ] Container registry access configured
- [ ] Backup strategy defined

### Deployment

- [ ] Application deployed
- [ ] Services accessible
- [ ] Ingress configured
- [ ] Security policies applied
- [ ] Monitoring enabled

### Post-deployment

- [ ] Health checks passing
- [ ] Performance baseline established
- [ ] Alerts configured
- [ ] Documentation updated
- [ ] Team notified

## 🆘 Support and Escalation

### Monitoring Alerts

Set up alerts for:
- Pod crashes or restarts
- High resource usage
- Failed health checks
- Security policy violations
- Certificate expiration

### Escalation Procedures

1. **Level 1**: Check application logs and basic Kubernetes resources
2. **Level 2**: Investigate infrastructure and network issues
3. **Level 3**: Deep dive into security policies and performance analysis

For additional support, refer to the main [README.md](README.md) and check the application logs.