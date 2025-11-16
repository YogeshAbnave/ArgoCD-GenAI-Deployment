# 🚀 ArgoCD Setup Guide for Flask Weather App

Complete guide to deploy the Flask Weather App using ArgoCD on Kubernetes.

## 📋 Prerequisites

- Kubernetes cluster (Minikube, EKS, GKE, AKS, or any K8s cluster)
- kubectl installed and configured
- Git repository access

## 🎯 Quick Setup

### Step 1: Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Step 2: Access ArgoCD UI

**Option A: Port Forward (Quick)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Access at: https://localhost:8080

**Option B: NodePort (For Minikube)**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
minikube service argocd-server -n argocd
```

**Option C: LoadBalancer (For Cloud)**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd
```

### Step 3: Get Admin Password

```bash
# Get initial admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo
```

**Login credentials:**
- Username: `admin`
- Password: (output from above command)

### Step 4: Create Application in ArgoCD

**Via UI:**

1. Login to ArgoCD UI
2. Click **"+ NEW APP"**
3. Fill in the details:

```
General:
  Application Name: flask-weather-app
  Project: default
  Sync Policy: Automatic
  
Source:
  Repository URL: https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment.git
  Revision: main
  Path: k8s
  
Destination:
  Cluster URL: https://kubernetes.default.svc
  Namespace: default
  
Sync Options:
  ☑ Auto-Create Namespace
  ☑ Prune Resources
  ☑ Self Heal
```

4. Click **"CREATE"**
5. Click **"SYNC"** to deploy

**Via CLI:**

```bash
# Install ArgoCD CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Login to ArgoCD
argocd login localhost:8080 --username admin --password <your-password> --insecure

# Create application
argocd app create flask-weather-app \
  --repo https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Sync application
argocd app sync flask-weather-app
```

## 📊 Verify Deployment

```bash
# Check ArgoCD application status
argocd app get flask-weather-app

# Check Kubernetes resources
kubectl get all -l app=flask-weather-app

# Check pods
kubectl get pods -l app=flask-weather-app

# Check service
kubectl get svc flask-weather-service
```

## 🌐 Access the Application

### Option 1: NodePort (Minikube)

```bash
# Get the URL
minikube service flask-weather-service

# Or manually
kubectl get svc flask-weather-service
# Access at: http://<NODE-IP>:30008
```

### Option 2: Port Forward

```bash
kubectl port-forward svc/flask-weather-service 5000:5000
```
Access at: http://localhost:5000

### Option 3: Ingress (if configured)

```bash
# Add to /etc/hosts
echo "$(minikube ip) weather.local" | sudo tee -a /etc/hosts

# Access at
http://weather.local
```

## 🔄 GitOps Workflow

Once ArgoCD is set up, the deployment is fully automated:

1. **Developer pushes code** to GitHub
2. **GitHub Actions** builds Docker image and pushes to Docker Hub
3. **GitHub Actions** updates `k8s/deployment.yaml` with new image tag
4. **ArgoCD** detects the change and automatically syncs
5. **Kubernetes** rolls out the new version

## 📁 Repository Structure

```
ArgoCD-GenAI-Deployment/
├── k8s/                    # ← ArgoCD watches this folder
│   ├── deployment.yaml     # Kubernetes Deployment
│   ├── service.yaml        # Kubernetes Service
│   └── ingress.yaml        # Kubernetes Ingress (optional)
├── app.py                  # Flask application
├── requirements.txt        # Python dependencies
├── Dockerfile              # Docker image definition
└── .github/workflows/      # CI/CD pipeline
    └── main.yml
```

## 🔧 ArgoCD Configuration

### Enable Auto-Sync

```bash
argocd app set flask-weather-app --sync-policy automated
```

### Enable Auto-Prune

```bash
argocd app set flask-weather-app --auto-prune
```

### Enable Self-Heal

```bash
argocd app set flask-weather-app --self-heal
```

## 📊 Monitoring

### View Application Status

```bash
# ArgoCD CLI
argocd app get flask-weather-app

# Kubernetes
kubectl get all -l app=flask-weather-app
```

### View Logs

```bash
# Application logs
kubectl logs -l app=flask-weather-app -f

# ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f
```

### View Events

```bash
kubectl get events --sort-by='.lastTimestamp' -l app=flask-weather-app
```

## 🐛 Troubleshooting

### ArgoCD can't find manifests

**Error:** `app path does not exist`

**Solution:** Verify the path in ArgoCD matches your repo structure:
```bash
# Check your repo
git clone https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment.git
cd ArgoCD-GenAI-Deployment
ls -la k8s/
```

The path should be: `k8s`

### Application stuck in "Progressing"

```bash
# Check ArgoCD application
argocd app get flask-weather-app

# Check pod status
kubectl describe pod -l app=flask-weather-app

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Image pull errors

```bash
# Check if image exists
docker pull genaiyogeshabnave/demo-app:v20251115210847

# Update deployment with correct image
kubectl set image deployment/flask-weather-app flask-weather-app=genaiyogeshabnave/demo-app:latest
```

### Service not accessible

```bash
# Check service
kubectl get svc flask-weather-service

# Check endpoints
kubectl get endpoints flask-weather-service

# Test from within cluster
kubectl run test --rm -it --image=busybox -- wget -O- http://flask-weather-service:5000
```

## 🔒 Security Best Practices

### Use Private Repository

```bash
# Add private repo credentials
argocd repo add https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment.git \
  --username <username> \
  --password <token>
```

### Use RBAC

```bash
# Create read-only user
argocd account update-password --account readonly --new-password <password>
```

### Enable SSO

Configure SSO in `argocd-cm` ConfigMap for enterprise authentication.

## 📞 Support

- GitHub: https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment
- Issues: https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment/issues
- ArgoCD Docs: https://argo-cd.readthedocs.io/

## 🎓 Next Steps

1. ✅ Set up monitoring with Prometheus/Grafana
2. ✅ Configure alerts for deployment failures
3. ✅ Implement blue-green or canary deployments
4. ✅ Add resource quotas and limits
5. ✅ Set up backup and disaster recovery
