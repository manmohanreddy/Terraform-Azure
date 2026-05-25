# Quick Reference Guide - Azure Infrastructure Commands

## Essential Commands for Daily Use

### Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Show current account
az account show
```

### Terraform Operations

```bash
# Initialize (first time only)
terraform init

# Check syntax
terraform validate

# Format code
terraform fmt -recursive

# Show what will change
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy everything (careful!)
terraform destroy

# Show current state
terraform show

# Get specific output
terraform output kubernetes_cluster_name
```

### Kubernetes Access

```bash
# Get credentials
az aks get-credentials --resource-group RG_NAME --name CLUSTER_NAME

# View cluster info
kubectl cluster-info

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context CONTEXT_NAME
```

### Pod Management

```bash
# List all pods
kubectl get pods -A

# List pods in namespace
kubectl get pods -n NAMESPACE

# Describe pod
kubectl describe pod POD_NAME -n NAMESPACE

# View logs
kubectl logs POD_NAME -n NAMESPACE

# Follow logs
kubectl logs -f POD_NAME -n NAMESPACE

# Execute command in pod
kubectl exec -it POD_NAME -n NAMESPACE -- /bin/bash

# Port forward
kubectl port-forward POD_NAME 8080:8080 -n NAMESPACE
```

### Deployments

```bash
# List deployments
kubectl get deployments -n NAMESPACE

# Describe deployment
kubectl describe deployment DEPLOYMENT_NAME -n NAMESPACE

# Scale deployment
kubectl scale deployment DEPLOYMENT_NAME --replicas=5 -n NAMESPACE

# Update image
kubectl set image deployment/DEPLOYMENT_NAME \
  CONTAINER_NAME=IMAGE:TAG -n NAMESPACE

# Rollout status
kubectl rollout status deployment/DEPLOYMENT_NAME -n NAMESPACE

# Rollout history
kubectl rollout history deployment/DEPLOYMENT_NAME -n NAMESPACE

# Rollback
kubectl rollout undo deployment/DEPLOYMENT_NAME -n NAMESPACE
```

### Services & Networking

```bash
# List services
kubectl get svc -n NAMESPACE

# Expose deployment
kubectl expose deployment DEPLOYMENT_NAME --port=80 --type=LoadBalancer -n NAMESPACE

# Port forward to service
kubectl port-forward svc/SERVICE_NAME 8080:80 -n NAMESPACE

# Get external IP
kubectl get svc SERVICE_NAME -n NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Secrets & ConfigMaps

```bash
# List secrets
kubectl get secrets -n NAMESPACE

# Create secret
kubectl create secret generic SECRET_NAME \
  --from-literal=key=value \
  -n NAMESPACE

# Create secret from file
kubectl create secret generic SECRET_NAME \
  --from-file=./secret.txt \
  -n NAMESPACE

# View secret (base64 encoded)
kubectl get secret SECRET_NAME -n NAMESPACE -o yaml

# Delete secret
kubectl delete secret SECRET_NAME -n NAMESPACE

# Create config map
kubectl create configmap CONFIG_NAME \
  --from-literal=key=value \
  -n NAMESPACE

# List config maps
kubectl get configmaps -n NAMESPACE
```

### Namespaces

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace NAMESPACE_NAME

# Delete namespace
kubectl delete namespace NAMESPACE_NAME

# Set default namespace
kubectl config set-context --current --namespace=NAMESPACE_NAME

# Get pods in all namespaces
kubectl get pods -A
```

### Node Management

```bash
# List nodes
kubectl get nodes

# Describe node
kubectl describe node NODE_NAME

# View resource usage
kubectl top nodes
kubectl top pods -n NAMESPACE

# Cordon node (no new pods)
kubectl cordon NODE_NAME

# Drain node (remove existing pods)
kubectl drain NODE_NAME --ignore-daemonsets

# Uncordon node
kubectl uncordon NODE_NAME
```

### Cluster Info

```bash
# Get cluster info
kubectl cluster-info

# Get all resources
kubectl api-resources

# Get events
kubectl get events -A

# Get events in namespace
kubectl get events -n NAMESPACE

# View persistent volumes
kubectl get pv

# View persistent volume claims
kubectl get pvc -n NAMESPACE
```

### Azure CLI Commands

```bash
# List resource groups
az group list -o table

# List AKS clusters
az aks list -o table

# Get cluster details
az aks show --name CLUSTER_NAME --resource-group RG_NAME

# List container registries
az acr list -o table

# Build and push image
az acr build --registry REGISTRY_NAME --image IMAGE:TAG .

# List storage accounts
az storage account list -o table

# List databases
az postgres flexible-server list -o table
az mysql flexible-server list -o table

# Restart node pool
az aks nodepool scale \
  --resource-group RG_NAME \
  --cluster-name CLUSTER_NAME \
  --name default \
  --node-count 3
```

### Database Access

```bash
# PostgreSQL
psql -h SERVER.postgres.database.azure.com \
  -U username@SERVER \
  -d database_name

# MySQL
mysql -h SERVER.mysql.database.azure.com \
  -u username@SERVER \
  -p \
  -D database_name

# Get connection string from Terraform
terraform output postgresql_server_fqdn
```

### Monitoring & Logs

```bash
# Get application logs
kubectl logs -f deployment/APP_NAME -n NAMESPACE

# Get container logs (previous crash)
kubectl logs POD_NAME -n NAMESPACE --previous

# Describe pod for events
kubectl describe pod POD_NAME -n NAMESPACE

# Get all events
kubectl get events -A

# View metrics
kubectl top nodes
kubectl top pods -n NAMESPACE

# Port forward to dashboard
kubectl proxy
# Visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## Useful Aliases

Add to your `.bashrc`, `.zshrc`, or PowerShell profile:

```bash
# Bash/Zsh
alias k=kubectl
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias ka='kubectl apply'
alias kgn='kubectl get -n'
alias kdn='kubectl describe -n'
alias kcx='kubectl config use-context'

# One-liners
alias kgp='kubectl get pods -A'
alias kgs='kubectl get svc -A'
alias kgd='kubectl get deployments -A'
alias kga='kubectl get all -A'
```

```powershell
# PowerShell
Set-Alias -Name k -Value kubectl
function kg { kubectl get @args }
function kd { kubectl describe @args }
function kl { kubectl logs @args }
function ke { kubectl exec -it @args }
```

---

## Useful One-Liners

```bash
# Get all external IPs
kubectl get svc -A | grep -E 'LoadBalancer|pending'

# Delete all pods in namespace
kubectl delete pods --all -n NAMESPACE

# Get resource usage
kubectl top pods -n NAMESPACE --sort-by=memory

# Port forward to all services
for svc in $(kubectl get svc -n NAMESPACE | tail -n +2 | awk '{print $1}'); do
  kubectl port-forward svc/$svc $port:80 -n NAMESPACE &
done

# Export resource as YAML
kubectl get pod POD_NAME -n NAMESPACE -o yaml > pod.yaml

# Watch pod status
kubectl get pods -n NAMESPACE -w

# Get logs from last 1 hour
kubectl logs POD_NAME -n NAMESPACE --since=1h

# Get pod IP addresses
kubectl get pods -n NAMESPACE -o wide

# Check resource quotas
kubectl describe resourcequota -n NAMESPACE

# Get all PVC usage
kubectl get pvc -A
```

---

## Troubleshooting Quick Commands

```bash
# Pod won't start
kubectl describe pod POD_NAME -n NAMESPACE
kubectl logs POD_NAME -n NAMESPACE

# Connection refused
kubectl port-forward svc/SERVICE 8080:80 -n NAMESPACE
curl localhost:8080

# Database connection issues
kubectl exec -it POD_NAME -n NAMESPACE -- psql -h DB_HOST -U USER -d DB

# Network policy blocking traffic
kubectl get networkpolicies -n NAMESPACE
kubectl describe networkpolicy POLICY_NAME -n NAMESPACE

# Persistent volume not mounting
kubectl get pvc -n NAMESPACE
kubectl describe pvc PVC_NAME -n NAMESPACE
kubectl get pv

# DNS not working
kubectl run -it --rm debug --image=nicolaka/netshoot:latest -- nslookup kubernetes.default

# Check RBAC permissions
kubectl auth can-i list pods --as=system:serviceaccount:NAMESPACE:SA_NAME
```

---

## Common Files & Paths

```
Repository Structure:
├── main.tf                    # Main configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider setup
├── backend.tf                 # State configuration
├── terraform.tfvars           # Your values (DON'T COMMIT)
├── modules/                   # Reusable modules
│   ├── aks/
│   ├── networking/
│   ├── database/
│   ├── storage/
│   ├── security/
│   ├── monitoring/
│   └── loadbalancer/
├── environments/              # Environment configs
│   ├── dev/
│   ├── staging/
│   └── prod/
├── kubernetes/                # K8s manifests
└── docs/                      # Documentation
    ├── SETUP_GUIDE.md
    ├── ARCHITECTURE.md
    ├── DEPLOYMENT.md
    └── TROUBLESHOOTING.md

Kubeconfig location:
~/.kube/config                # Linux/macOS
C:\Users\USERNAME\.kube\config # Windows

Terraform state:
Azure Storage Account: tfstatestg
Container: tfstate
Key: azure-enterprise.tfstate
```

---

## Azure Portal Quick Navigation

| Resource | Path |
|----------|------|
| Resource Groups | Home > Resource groups |
| AKS Clusters | Home > Kubernetes services |
| Container Registries | Home > Container registries |
| Databases | Home > PostgreSQL servers / MySQL servers |
| Storage Accounts | Home > Storage accounts |
| Key Vaults | Home > Key vaults |
| Log Analytics | Home > Log Analytics workspaces |
| Insights | AKS Cluster > Insights |
| Cost Analysis | Home > Cost Management + Billing |
| Activity Log | Home > Activity log |

---

## Important Notes

⚠️ **Security**
- Never commit `terraform.tfvars` (contains sensitive data)
- Always use `terraform plan` before `apply`
- Rotate passwords regularly
- Use service accounts for CI/CD
- Enable MFA on Azure account

⚠️ **Cost Management**
- Monitor resource usage weekly
- Set budget alerts in Azure
- Delete unused deployments
- Use auto-shutdown for non-prod
- Review reserved instances quarterly

⚠️ **Backups**
- Database backups are automatic (7 days)
- Store important configs in Git
- Backup kubeconfig file
- Test restore procedures monthly

---

## Getting Help

1. **Check Documentation**: `docs/` folder in repository
2. **Check Kubernetes Docs**: https://kubernetes.io/docs/
3. **Check Azure Docs**: https://docs.microsoft.com/en-us/azure/
4. **Check Terraform Docs**: https://www.terraform.io/docs/
5. **Ask in Issues**: Create GitHub issue with details

---

**Version**: 1.0 | **Last Updated**: May 2026
