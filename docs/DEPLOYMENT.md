# Application Deployment Guide

This guide covers deploying containerized applications to your AKS cluster.

## Prerequisites

```bash
# Verify tools
kubectl version --client
helm version
docker --version

# Configure kubeconfig
az aks get-credentials --resource-group <resource-group> --name <cluster-name>

# Verify connection
kubectl get nodes
```

## Application Deployment Architecture

```
Developer Code
    ↓
Docker Image Build
    ↓
Container Registry (ACR)
    ↓
Kubernetes Manifest (YAML)
    ↓
kubectl apply
    ↓
AKS Cluster
    ├── Namespace
    ├── Deployment/StatefulSet
    ├── Service
    ├── Ingress
    └── ConfigMap/Secrets
```

## Step 1: Create Azure Container Registry (ACR)

```bash
# Create ACR
az acr create \
  --resource-group $(terraform output -raw resource_group_name) \
  --name mycompanyacr \
  --sku Basic

# Get login credentials
az acr credential show \
  --name mycompanyacr \
  --query "passwords[0].value" -o tsv
```

## Step 2: Build and Push Docker Image

```bash
# Build image
docker build -t myapp:1.0 .

# Tag image for ACR
docker tag myapp:1.0 mycompanyacr.azurecr.io/myapp:1.0

# Login to ACR
az acr login --name mycompanyacr

# Push image
docker push mycompanyacr.azurecr.io/myapp:1.0

# Verify
az acr repository list --name mycompanyacr
```

## Step 3: Create Kubernetes Namespace

```bash
# Create namespace
kubectl create namespace myapp

# Verify
kubectl get ns
kubectl describe ns myapp
```

## Step 4: Configure Secrets (Database Credentials)

### Option A: Using Key Vault (Recommended)

```bash
# Create secret in Key Vault
az keyvault secret set \
  --vault-name $(terraform output -raw key_vault_name) \
  --name db-password \
  --value "your-secure-password"

# Create secret reference (requires Azure Key Vault CSI driver)
# See kubectl manifests below
```

### Option B: Using Kubernetes Secrets

```bash
# Create secret
kubectl create secret generic db-credentials \
  --from-literal=username=dbadmin \
  --from-literal=password='your-secure-password' \
  -n myapp

# Verify
kubectl get secrets -n myapp
kubectl describe secret db-credentials -n myapp
```

## Step 5: Deploy Application

### Example 1: Simple Web Application

Create `kubernetes/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
  labels:
    app: myapp
    environment: prod
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      # Pod disruption budget for availability
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - myapp
              topologyKey: kubernetes.io/hostname

      containers:
      - name: myapp
        image: mycompanyacr.azurecr.io/myapp:1.0
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        
        # Environment variables
        env:
        - name: ENVIRONMENT
          value: "prod"
        - name: LOG_LEVEL
          value: "info"
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database-host
        - name: DATABASE_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password

        # Resource requests and limits
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi

        # Health checks
        livenessProbe:
          httpGet:
            path: /healthz
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2

        # Security context
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL

        # Volume mounts
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache

      # Service account for pod identity
      serviceAccountName: myapp

      # Image pull secret for ACR
      imagePullSecrets:
      - name: acr-secret

      # Pod security context
      securityContext:
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault

      # Restart policy
      restartPolicy: Always

      # DNS policy
      dnsPolicy: ClusterFirst

      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: myapp
  labels:
    app: myapp
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: myapp

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp
  namespace: myapp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
```

### Deploy the Application

```bash
# Create configmap
kubectl create configmap app-config \
  --from-literal=database-host="mydb.postgres.database.azure.com" \
  -n myapp

# Create image pull secret (if ACR is not integrated)
kubectl create secret docker-registry acr-secret \
  --docker-server=mycompanyacr.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password> \
  -n myapp

# Deploy application
kubectl apply -f kubernetes/deployment.yaml

# Verify deployment
kubectl get deployments -n myapp
kubectl get pods -n myapp
kubectl describe deployment myapp -n myapp
```

## Step 6: Configure Ingress

Create `kubernetes/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-network-policy
  namespace: myapp
spec:
  podSelector:
    matchLabels:
      app: myapp
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
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443  # For HTTPS
    - protocol: TCP
      port: 5432  # For PostgreSQL
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 53  # For DNS

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: myapp
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls-cert
```

```bash
# Deploy ingress
kubectl apply -f kubernetes/ingress.yaml

# Verify
kubectl get ingress -n myapp
```

## Step 7: Monitor Deployment

```bash
# Watch deployment progress
kubectl rollout status deployment/myapp -n myapp

# View logs
kubectl logs -f deployment/myapp -n myapp

# Get pod details
kubectl get pods -n myapp -o wide
kubectl describe pod <pod-name> -n myapp

# Check events
kubectl get events -n myapp

# Monitor resource usage
kubectl top pods -n myapp
```

## Step 8: Database Connection

### Connect from Pod

```bash
# Exec into pod
kubectl exec -it <pod-name> -n myapp -- /bin/bash

# Test connection
psql -h $(terraform output -raw postgresql_server_fqdn) \
  -U psqladmin \
  -d appdb
```

### Connection String

```
postgres://psqladmin:PASSWORD@server.postgres.database.azure.com:5432/appdb?sslmode=require
```

## Scaling Applications

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment myapp --replicas=5 -n myapp

# Verify
kubectl get deployment myapp -n myapp
```

### Automatic Scaling (HPA)

```bash
# View HPA status
kubectl get hpa -n myapp
kubectl describe hpa myapp -n myapp

# Check metrics
kubectl top pods -n myapp
```

## Updates and Rollbacks

### Rolling Update

```bash
# Update image
kubectl set image deployment/myapp \
  myapp=mycompanyacr.azurecr.io/myapp:2.0 \
  -n myapp

# Watch rollout
kubectl rollout status deployment/myapp -n myapp

# View rollout history
kubectl rollout history deployment/myapp -n myapp
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/myapp -n myapp

# Rollback to specific revision
kubectl rollout undo deployment/myapp --to-revision=1 -n myapp
```

## Debugging

### Check Pod Status

```bash
# Describe pod
kubectl describe pod <pod-name> -n myapp

# Get logs
kubectl logs <pod-name> -n myapp
kubectl logs <pod-name> -n myapp --previous  # Previous container run

# Exec into container
kubectl exec -it <pod-name> -n myapp -- /bin/sh
```

### Check Events

```bash
# Cluster events
kubectl get events -A --sort-by='.lastTimestamp'

# Namespace events
kubectl get events -n myapp
```

### Networking Issues

```bash
# Test DNS
kubectl run -it --rm debug --image=nicolaka/netshoot:latest -- nslookup kubernetes.default

# Test connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot:latest -- curl http://myapp.myapp.svc.cluster.local

# Check network policies
kubectl get networkpolicies -n myapp
kubectl describe networkpolicy <policy-name> -n myapp
```

## Best Practices

1. **Resource Requests**: Always define CPU and memory requests
2. **Health Checks**: Implement liveness and readiness probes
3. **Security**: Use Pod Security Standards, network policies
4. **Logging**: Send logs to stdout/stderr for Log Analytics
5. **Monitoring**: Add Prometheus annotations for metrics
6. **Updates**: Use rolling updates with PodDisruptionBudgets
7. **ConfigMaps**: Store configuration separately from code
8. **Secrets**: Use Key Vault integration for sensitive data
9. **RBAC**: Create appropriate service accounts and roles
10. **Namespace**: Isolate applications in separate namespaces

---

For architecture details, see `ARCHITECTURE.md`
For setup instructions, see `SETUP_GUIDE.md`
For troubleshooting, see `TROUBLESHOOTING.md`
