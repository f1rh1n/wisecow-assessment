# Wisecow Assessment

A containerized web application that serves fortune cookies with cowsay, deployed on Kubernetes with comprehensive security policies and monitoring.

## 🐄 About Wisecow

Wisecow is a simple web server that combines the classic Unix `fortune` and `cowsay` commands to deliver wisdom with a touch of whimsy. The application serves fortune cookies displayed by ASCII cows through a web interface.

## ✨ Features

- 🌐 Web-based fortune cookie delivery
- 🐮 ASCII cow presentations via cowsay
- 🔒 Comprehensive security policies with KubeArmor
- 📊 Health monitoring and alerting
- 🚀 CI/CD pipeline with GitHub Actions
- 🔍 Vulnerability scanning with Trivy
- 📈 Resource management and limits
- 🛡️ Network policies and ingress with TLS

## 📁 Project Structure

```
wisecow-assessment/
├── Dockerfile                          # Container image definition
├── wisecow.sh                         # Main application script
├── setup.sh                          # Automated setup script
├── test-deployment.sh                 # Deployment testing script
├── k8s-manifests/                     # Kubernetes manifests
│   ├── deployment.yaml               # Application deployment
│   ├── service.yaml                  # Service definition
│   └── ingress.yaml                  # Ingress configuration
├── scripts/                          # Monitoring and utility scripts
│   ├── system_health_monitor.sh      # System health monitoring
│   └── app_health_checker.py         # Application health checker
├── kubearmor/                        # Security policies
│   └── security-policies.yaml       # KubeArmor security rules
├── .github/workflows/                # CI/CD pipeline
│   └── ci-cd.yaml                    # GitHub Actions workflow
├── README.md                         # This file
└── DEPLOYMENT_GUIDE.md               # Detailed deployment instructions
```

## 🚀 Quick Start

### Prerequisites

- Docker
- Kubernetes cluster (or use the included setup script for local development)
- kubectl
- Git

### Option 1: Automated Setup (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd wisecow-assessment

# Run the automated setup script
chmod +x setup.sh
./setup.sh
```

This will:
- Create a local Kubernetes cluster using kind
- Install required components (NGINX Ingress, KubeArmor)
- Build and deploy the application
- Apply security policies
- Set up monitoring

### Option 2: Manual Deployment

```bash
# Build the Docker image
docker build -t wisecow:latest .

# Deploy to Kubernetes
kubectl create namespace wisecow
kubectl apply -f k8s-manifests/ -n wisecow

# Apply security policies
kubectl apply -f kubearmor/security-policies.yaml -n wisecow
```

### Verification

Run the test suite to verify your deployment:

```bash
chmod +x test-deployment.sh
./test-deployment.sh
```

## 🌐 Accessing the Application

### Local Development

```bash
# Port forward to access locally
kubectl port-forward service/wisecow-service 8080:80 -n wisecow

# Visit in browser
open http://localhost:8080
```

### Production

Access via the configured ingress URL: `https://wisecow.example.com`

## 📊 Monitoring

### System Health Monitoring

```bash
# Run system health monitor
./scripts/system_health_monitor.sh
```

Monitors:
- CPU usage
- Memory usage
- Disk usage
- Service status
- Network connectivity

### Application Health Monitoring

```bash
# Check application health once
python3 scripts/app_health_checker.py --once --url http://localhost:8080

# Continuous monitoring
python3 scripts/app_health_checker.py --url http://localhost:8080
```

Features:
- HTTP health checks
- Response time monitoring
- Content validation
- Alerting for failures

## 🔒 Security

### KubeArmor Security Policies

The application includes comprehensive security policies:

- **Process Control**: Restricts executable processes
- **File System Protection**: Controls file access and modifications
- **Network Security**: Manages network traffic
- **Capability Management**: Limits container capabilities

### Security Features

- Container runs as non-root user
- Minimal base image (Ubuntu 20.04)
- Resource limits and requests
- Health probes for reliability
- Network policies for traffic control
- TLS termination at ingress

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `4499` | Application listening port |
| `NAMESPACE` | `wisecow` | Kubernetes namespace |

### Resource Configuration

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 250m | 500m |
| Memory | 64Mi | 128Mi |

## 🚀 CI/CD Pipeline

The GitHub Actions workflow includes:

1. **Test Stage**: Script validation and Kubernetes manifest testing
2. **Build & Push**: Multi-architecture Docker image build
3. **Security Scan**: Trivy vulnerability scanning
4. **Deploy Staging**: Automated staging deployment
5. **Deploy Production**: Production deployment with approval gates

### Pipeline Triggers

- Push to `main`/`master` branch
- Pull requests to `main`/`master` branch

## 🧪 Testing

### Automated Tests

```bash
# Run all deployment tests
./test-deployment.sh
```

Test coverage includes:
- Namespace verification
- Deployment status
- Pod health
- Service connectivity
- Ingress configuration
- Resource limits
- Health probes
- Security policies
- Application functionality
- Performance testing

### Manual Testing

```bash
# Test application directly
curl http://localhost:8080

# Check pod logs
kubectl logs -f deployment/wisecow-deployment -n wisecow

# Verify security policies
kubectl get kubearmor-policies -n wisecow
```

## 🛠️ Development

### Local Development

```bash
# Run locally with Docker
docker run -p 4499:4499 wisecow:latest

# Access at http://localhost:4499
```

### Building

```bash
# Build Docker image
docker build -t wisecow:latest .

# Build for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64 -t wisecow:latest .
```

## 📋 Maintenance

### Updating the Application

1. Modify the application code
2. Build new Docker image
3. Update Kubernetes deployment
4. Run tests to verify

### Monitoring Logs

```bash
# Application logs
kubectl logs -f deployment/wisecow-deployment -n wisecow

# Security logs
kubectl logs -n kubearmor -l app.kubernetes.io/name=kubearmor

# Ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Scaling

```bash
# Scale deployment
kubectl scale deployment wisecow-deployment --replicas=5 -n wisecow
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./test-deployment.sh`
5. Submit a pull request

## 📝 License

This project is part of a technical assessment and is provided as-is for educational purposes.

## 🆘 Troubleshooting

### Common Issues

**Application not accessible:**
```bash
# Check pod status
kubectl get pods -n wisecow

# Check service endpoints
kubectl get endpoints -n wisecow

# Check ingress
kubectl describe ingress wisecow-ingress -n wisecow
```

**Health checks failing:**
```bash
# Check pod logs
kubectl logs deployment/wisecow-deployment -n wisecow

# Test application directly
kubectl exec -it deployment/wisecow-deployment -n wisecow -- curl localhost:4499
```

**Security policies not working:**
```bash
# Verify KubeArmor installation
kubectl get pods -n kubearmor

# Check policy status
kubectl get kubearmor-policies -n wisecow -o yaml
```

For detailed deployment instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

## 📞 Contact - fk3205545@gmail.com

For issues and questions:
- Check the troubleshooting section above
- Review the deployment guide
- Check application logs
- Verify Kubernetes resources
## GitHub Actions Demo
