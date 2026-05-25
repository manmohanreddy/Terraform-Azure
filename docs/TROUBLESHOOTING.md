# Troubleshooting Guide

Common issues and their solutions.

## Authentication & Access

### Issue: "unauthorized: authentication required"

**Error Message:**
```
Error: Error building resource: [unknown (code: 401)]
```

**Solution:**
```bash
# Re-authenticate with Azure
az login

# Verify subscription
az account show

# Set correct subscription
az account set --subscription "<subscription-id>"

# Check credentials
echo "ARM_CLIENT_ID: $ARM_CLIENT_ID"
echo "ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID"
```

### Issue: Insufficient Permissions

**Error Message:**
```
Error: Insufficient privileges to complete the operation.
```

**Solution:**
1. Ensure your Azure account has Contributor or Owner role
2. Check role assignment:
   ```bash
   az role assignment list --assignee <your-email> --output table
   ```
3. Request elevated permissions from Azure admin

### Issue: kubeconfig Not Found

**Error Message:**
```
The path /home/user/.kube/config does not exist
```

**Solution:**
```bash
# Generate kubeconfig
az aks get-credentials \
  --resource-group <resource-group> \
  --name <cluster-name>

# Verify
kubectl cluster-info
```

## Terraform Issues

### Issue: "Error: Backend initialization required"

**Error Message:**
```
Error: Backend initialization required, please run "terraform init"
```

**Solution:**
```bash
# Initialize Terraform
terraform init

# If state is locked
terraform force-unlock <lock-id>
```

### Issue: State Lock Timeout

**Error Message:**
```
Error acquiring the state lock: timeout while waiting for state lock
```

**Solution:**
```bash
# List locks
terraform force-unlock <lock-id>

# Check Azure Storage for lock
az storage blob list --account-name tfstatestg --container-name tfstate

# Release lock from Azure Portal if necessary
```

### Issue: Resource Already Exists

**Error Message:**
```
Error: A resource with the ID "<resource-id>" already exists
```

**Solution:**
```bash
# Import existing resource
terraform import azurerm_kubernetes_cluster.main <resource-id>

# Or remove from state and reimport
terraform state rm azurerm_kubernetes_cluster.main
terraform import azurerm_kubernetes_cluster.main <resource-id>
```

### Issue: Azure Quota Exceeded

**Error Message:**
```
Error: MissingSubscriptionRegistration: The subscription is not registered
for the resource type 'Microsoft.Compute/virtualMachines'
```

**Solution:**
```bash
# Register required providers
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.DBforPostgreSQL

# Check quotas
az vm list-usage --location "East US" -o table

# Request quota increase through Azure Portal
```

## AKS Issues

### Issue: Nodes Not Ready

**Symptoms:**
```
kubectl get nodes
# Output shows NotReady status
```

**Debugging:**
```bash
# Check node status
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system

# Check kubelet logs (via Azure Portal)
# -> AKS cluster -> Insights -> Containers -> Logs

# Query:
KubeletLog
| where LogLevel contains "error"
| order by TimeGenerated desc
```

**Solutions:**
```bash
# Restart node pool
az aks nodepool scale \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --name default \
  --node-count 3

# Cordon and drain node
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets

# Uncordon when ready
kubectl uncordon <node-name>
```

### Issue: Pods Pending (ImagePullBackOff)

**Error Message:**
```
kubectl describe pod <pod-name>
# Output: ImagePullBackOff, Failed to pull image
```

**Solution:**
```bash
# Check image exists in registry
az acr repository list --name <registry-name>

# Check credentials
kubectl get secrets -n <namespace>

# Recreate secret if needed
kubectl delete secret acr-secret -n myapp
kubectl create secret docker-registry acr-secret \
  --docker-server=<registry>.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password> \
  -n myapp

# Update pod to use secret
kubectl set serviceaccount deployment/myapp myapp -n myapp
```

### Issue: Service Not Accessible

**Symptoms:**
```bash
kubectl get svc -n myapp
# ClusterIP shows, but external access fails
```

**Solution:**
```bash
# Check service configuration
kubectl get svc <service-name> -n myapp -o yaml

# Test internal connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot:latest \
  -n myapp -- curl http://<service-name>:80

# Check endpoints
kubectl get endpoints <service-name> -n myapp

# Verify pod is running
kubectl get pods -n myapp -o wide

# Check service selector
kubectl get pods --selector=app=myapp -n myapp
```

## Database Issues

### Issue: Cannot Connect to PostgreSQL

**Error Message:**
```
psql: error: could not translate host name "<server>.postgres.database.azure.com" to address: Name or service not known
```

**Solution:**
```bash
# Test DNS resolution
nslookup <server>.postgres.database.azure.com

# Test connectivity from pod
kubectl run -it --rm debug --image=postgres:15 -n myapp -- psql \
  -h <server>.postgres.database.azure.com \
  -U psqladmin \
  -d appdb

# Check firewall rules (Azure Portal)
# AKS cluster's outbound IP must be allowed

# Check private endpoint configuration
az network private-endpoint list --resource-group <rg>
```

### Issue: Database Password Not Working

**Error Message:**
```
psql: error: FATAL: authentication failed for user "psqladmin"
```

**Solution:**
```bash
# Retrieve password from Key Vault
az keyvault secret show \
  --vault-name $(terraform output -raw key_vault_name) \
  --name postgresql-admin-password

# Reset password (if needed)
az postgres flexible-server update \
  --resource-group <rg> \
  --name <server> \
  --admin-password '<new-password>'

# Update in Key Vault
az keyvault secret set \
  --vault-name $(terraform output -raw key_vault_name) \
  --name postgresql-admin-password \
  --value '<new-password>'
```

### Issue: Database Capacity Exceeded

**Error Message:**
```
ERROR: out of memory
```

**Solution:**
```bash
# Check storage usage
az postgres flexible-server show \
  --resource-group <rg> \
  --name <server> \
  --query "storage.storageSizeGB"

# Increase storage (can only increase, not decrease)
az postgres flexible-server update \
  --resource-group <rg> \
  --name <server> \
  --storage-size 131072  # Size in MB
```

## Networking Issues

### Issue: Pod Cannot Reach External Services

**Symptoms:**
```bash
kubectl exec -it <pod> -n myapp -- curl https://example.com
# Times out or connection refused
```

**Solution:**
```bash
# Check network policies
kubectl get networkpolicies -n myapp

# Check NSG rules
az network nsg rule list --resource-group <rg> --nsg-name <nsg-name>

# Temporarily remove network policy to test
kubectl delete networkpolicy <policy-name> -n myapp

# Check DNS
kubectl exec -it <pod> -n myapp -- nslookup example.com
```

### Issue: Service-to-Service Communication Fails

**Symptoms:**
```
Connection refused or timeout
```

**Solution:**
```bash
# Verify service DNS name
kubectl get svc -n myapp

# Test from another pod
kubectl run -it --rm debug --image=nicolaka/netshoot:latest \
  -n myapp -- curl http://<service-name>

# Check network policy
kubectl describe networkpolicy -n myapp

# Verify endpoints
kubectl get endpoints -n myapp
```

## Monitoring & Logging Issues

### Issue: No Logs in Log Analytics

**Symptoms:**
```bash
# Query returns no results
KubeletLog
| count
# Returns 0
```

**Solution:**
```bash
# Verify Log Analytics workspace
terraform output log_analytics_workspace_id

# Check Container Insights is enabled
kubectl get deployment -n kube-system | grep omsagent

# If missing, enable:
az aks enable-addons \
  --resource-group <rg> \
  --name <cluster> \
  --addons monitoring

# Wait 10-15 minutes for data to appear
```

### Issue: High Latency in Application Insights

**Solution:**
```bash
# Check application instrumentation
# Ensure Application Insights SDK is properly initialized

# View performance metrics
# Azure Portal -> Application Insights -> Performance

# Check dependencies
# Application Insights -> Application map
```

## Scaling Issues

### Issue: Autoscaling Not Working

**Symptoms:**
```bash
kubectl get hpa
# Shows 0/3 status
```

**Solution:**
```bash
# Verify metrics server
kubectl get deployment metrics-server -n kube-system

# Check HPA status
kubectl describe hpa myapp -n myapp

# View metrics
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1

# Enable metrics collection
kubectl top pods -n myapp
kubectl top nodes
```

### Issue: Cluster Scaling Stalled

**Symptoms:**
```bash
# Nodes not scaling up despite demand
```

**Solution:**
```bash
# Check node autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# Verify cluster autoscaler is running
kubectl get deployment -n kube-system cluster-autoscaler

# Check quotas
az vm list-usage --location "East US" -o table

# Verify node pool max count
az aks nodepool list \
  --resource-group <rg> \
  --cluster-name <cluster>
```

## Performance Issues

### Issue: High Pod CPU/Memory Usage

**Solution:**
```bash
# Identify resource hogs
kubectl top pods -n myapp --sort-by=cpu
kubectl top pods -n myapp --sort-by=memory

# Check pod resource requests/limits
kubectl describe pod <pod-name> -n myapp

# Update resource limits
kubectl set resources deployment myapp \
  -n myapp \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi
```

### Issue: Slow Application Response Time

**Solution:**
```bash
# Check latency in Application Insights
# Portal -> Application Insights -> Performance

# Profile application
# Portal -> Application Insights -> Profiler

# Check database query performance
# PostgreSQL: pg_stat_statements
# MySQL: Performance Schema

# Monitor network latency
kubectl exec -it <pod> -n myapp -- ping <service>
```

## Recovery Procedures

### Restore from Backup

```bash
# List available backups
az postgres flexible-server list-backups \
  --resource-group <rg> \
  --name <server>

# Restore from backup point
az postgres flexible-server restore \
  --resource-group <rg> \
  --name <new-server-name> \
  --source-server <original-server> \
  --restore-time "2024-01-15T10:30:00Z"
```

### Disaster Recovery

```bash
# Backup current state
terraform state pull > backup.tfstate
git commit -am "Backup state before DR"

# Recreate infrastructure
terraform destroy -auto-approve
terraform apply -auto-approve

# Restore application data
# From Azure Storage backups or snapshots
```

## Useful Debugging Commands

```bash
# Comprehensive cluster diagnostics
kubectl cluster-info dump

# All events in namespace
kubectl get events -n myapp --sort-by='.lastTimestamp'

# Pod debugging
kubectl run -it --rm debug --image=nicolaka/netshoot:latest

# Check RBAC
kubectl auth can-i list pods --as=system:serviceaccount:myapp:myapp

# Resource utilization
kubectl top nodes
kubectl top pods -A

# Pod logs
kubectl logs <pod> -n myapp
kubectl logs <pod> -n myapp --previous

# Exec into container
kubectl exec -it <pod> -n myapp -- /bin/bash
```

## Getting Help

1. **Check Azure Diagnostics**: Azure Portal → AKS Cluster → Diagnostics
2. **View Activity Log**: Azure Portal → Activity Log (filter by resource group)
3. **Container Insights**: Azure Portal → Cluster → Insights → Containers
4. **Community Support**: 
   - [Kubernetes Issues](https://github.com/kubernetes/kubernetes/issues)
   - [Azure Support](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)
5. **Documentation**:
   - [AKS Troubleshooting](https://docs.microsoft.com/en-us/azure/aks/troubleshooting)
   - [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

For setup help, see `SETUP_GUIDE.md`
For architecture details, see `ARCHITECTURE.md`
For deployment guide, see `DEPLOYMENT.md`
