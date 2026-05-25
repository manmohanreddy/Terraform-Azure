# Azure Enterprise Infrastructure Architecture

## Overview

This Terraform configuration deploys a production-ready enterprise infrastructure on Microsoft Azure with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────────────────────────────────────────────┐   │
│  │               Virtual Network (10.0.0.0/16)           │   │
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐   │   │
│  │  │ AKS Subnet   │  │ AppGW Subnet │  │ Private   │   │   │
│  │  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │  │ Endpoints │   │   │
│  │  │              │  │              │  │           │   │   │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌───────┐ │   │   │
│  │  │ │ AKS      │ │  │ │AppGateway│ │  │ │DbSvr  │ │   │   │
│  │  │ │ Cluster  │ │  │ │(WAF)     │ │  │ │Storage│ │   │   │
│  │  │ │ 3-20     │ │  │ │2-10 scale│ │  │ │Keys   │ │   │   │
│  │  │ │ nodes    │ │  │ │          │ │  │ │       │ │   │   │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └───────┘ │   │   │
│  │  └──────────────┘  └──────────────┘  └───────────┘   │   │
│  │                                                       │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐   │   │
│  │ PostgreSQL    │  │ MySQL        │  │ Storage      │   │   │
│  │ Flexible      │  │ Flexible     │  │ Account      │   │   │
│  │ Server        │  │ Server       │  │              │   │   │
│  │ (HA)          │  │ (HA)         │  │ Containers   │   │   │
│  │               │  │              │  │ File Shares  │   │   │
│  └───────────────┘  └──────────────┘  └──────────────┘   │   │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Security & Monitoring                   │   │
│  │                                                     │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │   │
│  │  │ Key      │  │ Log      │  │ Application      │  │   │
│  │  │ Vault    │  │Analytics │  │ Insights         │  │   │
│  │  │ (Secrets)│  │ (Logs)   │  │ (Monitoring)     │  │   │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. **Virtual Networking**

**Module**: `modules/networking`

- **Virtual Network**: 10.0.0.0/16 (configurable)
  - AKS Subnet: 10.0.1.0/24 - Hosts AKS worker nodes
  - App Gateway Subnet: 10.0.2.0/24 - Ingress controller
  - Private Endpoints Subnet: 10.0.3.0/24 - Database and service connections

- **Network Security Groups (NSGs)**:
  - AKS NSG: Restricts cluster communication
  - App Gateway NSG: Allows HTTP/HTTPS, denies inbound by default
  
- **Route Tables**: Manages traffic within the VNet

**Best Practices Implemented**:
- Private DNS zones for databases
- Service endpoints for Azure services
- Network policies for pod-to-pod communication
- Deny-by-default security posture

### 2. **Azure Kubernetes Service (AKS)**

**Module**: `modules/aks`

- **Cluster Configuration**:
  - Latest stable Kubernetes version (1.29)
  - Azure CNI network plugin
  - Azure Network Policy for pod security
  - Pod Identity for secure workload authentication
  
- **Node Pool**:
  - Autoscaling: 3-20 nodes (configurable per environment)
  - Zone-redundant across 3 availability zones
  - Standard_D2s_v3 (2 CPU, 8GB RAM) - scalable
  - Enable host encryption

- **Built-in Add-ons**:
  - Azure Policy
  - Container Insights (monitoring)
  - Pod Security Standards

- **Advanced Features**:
  - Automatic patching and node pool management
  - Graceful shutdown
  - Flexible RBAC configuration

**High Availability**:
- Multi-zone node distribution
- Pod Disruption Budgets (PDBs)
- Horizontal Pod Autoscaling (HPA)
- Cluster Autoscaling

### 3. **Database Services**

**Module**: `modules/database`

#### PostgreSQL (Flexible Server)
- **High Availability**: Zone-redundant with automatic failover
- **Version**: 15 (latest stable)
- **SKU**: B_Standard_B1ms to B4ms depending on environment
- **Storage**: 32GB (dev) to 128GB (prod)
- **Backup**: 7-day retention with point-in-time recovery
- **Security**: Private endpoint, encryption, SSL required

#### MySQL (Flexible Server)
- **Configuration**: Similar to PostgreSQL
- **Version**: 8.0.37
- **Features**: Zone redundancy, automatic backup, private network

**Security Features**:
- Stored in Azure Key Vault (admin passwords)
- Private DNS zones for name resolution
- No public endpoints (private only)
- SSL/TLS encryption enforced

### 4. **Storage**

**Module**: `modules/storage`

- **Storage Account**: Geo-redundant (GRS)
- **Containers**:
  - `appdata`: Application data storage
  - `backups`: Database and application backups
  - `logs`: Application and system logs
  
- **File Shares**: Azure Files for persistent volumes
  
- **Lifecycle Management**:
  - Auto-delete logs after 90 days
  - Auto-archive backups after 30 days
  
- **Security**:
  - HTTPS only
  - Soft delete enabled
  - Blob versioning enabled
  - Private endpoints

### 5. **Security**

**Module**: `modules/security`

- **Azure Key Vault**:
  - Standard/Premium SKU
  - Secrets: Database credentials, API keys
  - Keys: Encryption keys
  - Certificates: SSL/TLS certificates
  
- **Access Control**:
  - Role-based access control (RBAC)
  - Managed identities for services
  - Pod identity for applications
  
- **Encryption**:
  - TLS for data in transit
  - Encryption at rest for storage
  - Customer-managed keys (optional)

### 6. **Monitoring & Logging**

**Module**: `modules/monitoring`

- **Log Analytics Workspace**:
  - Central log aggregation
  - 7-30 day retention (environment-specific)
  - Container Insights for AKS
  - Key Vault analytics
  
- **Application Insights**:
  - APM (Application Performance Monitoring)
  - Request tracing
  - Dependency tracking
  - Exception tracking
  
- **Alerts**:
  - High CPU (>85%)
  - High Memory (>95%)
  - Pod crashes
  - Service unavailability

### 7. **Load Balancing & Ingress**

**Module**: `modules/loadbalancer`

- **Application Gateway**:
  - Standard_v2 tier (auto-scaling)
  - Web Application Firewall (WAF)
  - HTTPS/SSL termination
  - Path-based routing
  
- **Features**:
  - Health probes for backend monitoring
  - Session affinity
  - Multi-site hosting
  - Auto-scaling (2-10 capacity units)

## Data Flow

### Incoming Request
```
Internet → Application Gateway (WAF) → AKS Ingress Controller → Service → Pod
```

### Database Access
```
Pod → Private Endpoint → PostgreSQL/MySQL (Private VNet)
```

### Logging & Monitoring
```
Pod Logs → Log Analytics Workspace
Metrics → Application Insights
Pod → Log Agent → Log Analytics
```

## Network Security

### Network Policies
```yaml
default: Deny all ingress traffic
Allow:
  - System pods (kube-system, kube-node-lease)
  - Same namespace communication
  - Specific labeled pods
Deny: Everything else
```

### NSG Rules
- **AKS NSG**: Allow only kubelet communication (10250), deny inbound by default
- **App Gateway NSG**: Allow HTTP/HTTPS (80/443), gateway manager ports
- **Private Subnet NSG**: Allow Azure services, deny internet

## Disaster Recovery

### Backup Strategy
- **Databases**: Automatic daily backups, 7-day retention
- **Storage**: Geo-redundant replication
- **Configuration**: Version controlled in Git

### Recovery Time Objectives (RTO)
- Database failure: < 5 minutes (automatic failover)
- AKS node failure: < 2 minutes (auto-replacement)
- Storage failure: N/A (geo-replicated)

## Scaling Strategy

### Horizontal Scaling
- **AKS Nodes**: Autoscaler (min 3, max 20 for prod)
- **Pods**: HPA based on CPU/Memory metrics

### Vertical Scaling
- **VM SKU**: Update node_pool_config.vm_size
- **Database**: Update SKU_name in variables

## Cost Optimization

### Dev Environment
- Smaller node pool (2-5 nodes)
- B-series database SKU
- Standard storage tier
- Shorter log retention (7 days)

### Production Environment
- Larger node pool (5-20 nodes)
- Higher database SKU
- Premium storage tier
- Extended log retention (30 days)
- Resource locks (prevent accidental deletion)

## Security Posture

### Defense in Depth
1. **Network**: NSGs, Network Policies
2. **Access**: RBAC, Pod Identity, Key Vault
3. **Data**: Encryption in transit and at rest
4. **Visibility**: Audit logging, monitoring
5. **Compliance**: Tags, segregation by environment

### Compliance Features
- Audit logging enabled
- HTTPS/TLS enforced
- Key Vault for secret management
- Network isolation
- Data residency control (region selection)

## Module Dependencies

```
providers.tf
    ↓
main.tf (orchestration)
    ├── networking (creates VNet, subnets, NSGs)
    ├── security (creates Key Vault)
    ├── aks (depends on: networking)
    ├── database (depends on: networking, security)
    ├── storage (independent)
    ├── monitoring (independent)
    └── loadbalancer (depends on: networking, aks)
```

## State Management

- **Remote State**: Azure Storage Account (tfstate container)
- **State Locking**: Automatic via Azure Storage
- **Encryption**: Storage account encryption (Azure-managed by default)
- **Versioning**: Enabled for recovery

## Environment Stages

### Development
- Quick iteration
- Cost-conscious
- Minimal security overhead
- Central logging disabled

### Staging
- Production-like
- Moderate cost
- Full feature set
- Monitoring enabled

### Production
- High availability
- Premium resources
- Full security
- Comprehensive monitoring
- Resource locks
- Disaster recovery enabled

## Extending the Architecture

### Adding New Components

1. **New Module**: Create `modules/newcomponent/`
2. **Module Interface**: Define `variables.tf`, `main.tf`, `outputs.tf`
3. **Integration**: Add module block to `main.tf`
4. **Outputs**: Export in `outputs.tf`

### Custom Addons

- **Helm Charts**: Add via kubectl/helm provider
- **Pod Security**: Network policies, Pod Security Standards
- **Ingress Controller**: nginx-ingress, Traefik
- **Service Mesh**: Istio, Linkerd

---

For deployment instructions, see `SETUP_GUIDE.md`
For troubleshooting, see `TROUBLESHOOTING.md`
