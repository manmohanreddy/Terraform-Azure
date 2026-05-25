# Contributing Guide

Guidelines for contributing to this Terraform Azure infrastructure project.

## Code of Conduct

Be respectful, inclusive, and professional in all interactions.

## Getting Started

1. Clone the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make changes and test thoroughly
4. Submit a pull request

## Development Workflow

### 1. Create Feature Branch

```bash
# Update main branch
git checkout master
git pull origin master

# Create feature branch
git checkout -b feature/add-redis-cache
```

### 2. Make Changes

### 3. Validate Code

```bash
# Format Terraform code
terraform fmt -recursive

# Validate syntax
terraform validate

# Lint with tflint (install first: https://github.com/terraform-linters/tflint)
tflint --init
tflint

# Plan changes
terraform plan -out=tfplan -var-file=environments/dev/terraform.tfvars
```

### 4. Test in Dev Environment

```bash
# Apply to dev environment
terraform apply tfplan

# Verify changes work as expected
terraform show

# Destroy to clean up
terraform destroy -var-file=environments/dev/terraform.tfvars
```

### 5. Commit Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: add Redis cache cluster for session storage

- Implement Azure Cache for Redis module
- Configure private endpoint connectivity
- Update networking for Redis subnet
- Add connection string to Key Vault"

# Push to remote
git push origin feature/add-redis-cache
```

## Commit Message Format

Use conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no logic change)
- `refactor`: Code restructuring (no feature change)
- `perf`: Performance improvement
- `test`: Test additions
- `chore`: Build, dependencies, tooling

### Scope
- `aks`: Kubernetes cluster changes
- `network`: Networking infrastructure
- `database`: Database services
- `security`: Security components
- `monitoring`: Monitoring and logging
- `storage`: Storage services
- `core`: Root configuration

### Examples

```
feat(aks): enable pod security standards

docs(setup): update kubeconfig instructions

fix(network): correct NSG rules for database access

refactor(modules): consolidate similar configurations
```

## Pull Request Process

### Before Submitting

1. Ensure all tests pass
2. Update documentation if needed
3. Add/update examples if adding features
4. Ensure code is formatted: `terraform fmt -recursive`

### PR Description

Include:
- What changes were made
- Why the changes are needed
- How to test the changes
- Any breaking changes

### Example PR Description

```markdown
## Description
Adds Redis cache cluster for session management to improve application performance and reduce database load.

## Changes
- New module: `modules/redis`
- Updated networking to include Redis subnet
- Added private endpoint for secure connection
- Connection string stored in Key Vault

## Motivation
Sessions currently stored in database causing I/O bottleneck during peak usage.

## Testing
1. Deploy to dev environment
2. Verify Redis connectivity from AKS pods
3. Test application session management
4. Monitor performance metrics

## Checklist
- [x] Code formatted with `terraform fmt`
- [x] `terraform validate` passes
- [x] tflint passes
- [x] Documentation updated
- [x] No sensitive data in code
```

## Code Standards

### Naming Conventions

```hcl
# Variables: snake_case
variable "enable_monitoring" {
  # ...
}

# Resources: short_descriptive_name
resource "azurerm_postgresql_flexible_server" "main" {
  # ...
}

# Local values: descriptive
locals {
  resource_prefix = "${lower(var.company_name)}-${lower(var.project_name)}"
}

# Outputs: descriptive with _id/_name suffix
output "kubernetes_cluster_id" {
  # ...
}
```

### Module Structure

```
modules/mycomponent/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── README.md        # Module documentation
```

### Documentation

Always include:
- What the module creates
- Input variables explanation
- Output values
- Example usage
- Notes and considerations

```hcl
# Example module header
/*
MyComponent Module

Creates Azure resources for XYZ functionality including:
- Resource type A
- Resource type B

Resources are configured for:
- High availability across zones
- Private network connectivity
- Encryption at rest and in transit
*/
```

### Resource Configuration Best Practices

```hcl
# Use descriptive names
resource "azurerm_resource_group" "main" {
  name       = "${var.environment_prefix}-rg"
  location   = var.location
  tags       = var.tags
}

# Group related arguments
resource "azurerm_kubernetes_cluster" "main" {
  # Identification
  name                = "${var.environment_prefix}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Configuration
  kubernetes_version  = var.kubernetes_version
  
  # Feature blocks
  default_node_pool {
    # ...
  }
  
  network_profile {
    # ...
  }
}

# Use dynamic blocks for optional configurations
dynamic "addon_profile" {
  for_each = var.enable_monitoring ? [1] : []
  content {
    # ...
  }
}
```

## Testing

### Plan Testing

```bash
# Test in dev environment
terraform plan -out=tfplan -var-file=environments/dev/terraform.tfvars

# Verify no unexpected changes
terraform show tfplan | grep "Plan:"

# Check for specific resources
terraform show tfplan | grep "azurerm_kubernetes_cluster"
```

### Integration Testing

```bash
# Apply and verify
terraform apply tfplan

# Test connectivity
kubectl get nodes

# Verify services
az aks show --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)

# Cleanup
terraform destroy -var-file=environments/dev/terraform.tfvars
```

## Documentation Updates

When adding features or modules, update:

1. **Module README**: Document the module's purpose and usage
2. **ARCHITECTURE.md**: Update architecture diagrams and descriptions
3. **SETUP_GUIDE.md**: Add setup steps if applicable
4. **DEPLOYMENT.md**: Add deployment guidance if applicable
5. **TROUBLESHOOTING.md**: Add common issues and solutions
6. **Main README.md**: Update feature list if applicable

## Security Guidelines

### Secrets Management

✅ DO:
```hcl
# Store in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  value        = random_password.db.result
  key_vault_id = azurerm_key_vault.main.id
}
```

❌ DON'T:
```hcl
# Never hardcode secrets
resource "azurerm_resource_group" "main" {
  # ...
}

locals {
  db_password = "MySecretPassword123!"  # NEVER DO THIS
}
```

### Sensitive Output

```hcl
output "database_password" {
  value     = random_password.db.result
  sensitive = true  # Prevents logging
}
```

### No Credentials in Code

- Never commit .env files
- Never hardcode API keys
- Use managed identities
- Use Azure Key Vault

## Reporting Issues

### Bug Report

Include:
- Description of the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment (Azure region, resource sizes, etc.)
- Terraform version
- Azure provider version

### Feature Request

Include:
- Description of desired feature
- Use case and motivation
- Proposed implementation (if known)
- Alternatives considered
- Estimated effort

## Review Process

### Code Review Checklist

Reviewers look for:
- [ ] Follows naming conventions
- [ ] Variables have descriptions
- [ ] Outputs are clearly named
- [ ] No hardcoded values
- [ ] No secrets in code
- [ ] `terraform validate` passes
- [ ] `terraform fmt` applied
- [ ] Documentation updated
- [ ] Backward compatible (or breaking change noted)
- [ ] Appropriate for environment

### Approval Process

- At least one approval required for merge
- All CI checks must pass
- No merge conflicts
- Documentation is updated

## Deployment to Production

### Approval Workflow

1. Feature branch created and tested
2. Pull request submitted
3. Code review and approval
4. Plan reviewed: `terraform plan`
5. Staging deployment approved
6. Staging verification complete
7. Production `terraform apply` approval
8. Production deployment

### Production Safeguards

- Feature branch policies enforce reviews
- Terraform plans require approval
- Resource locks prevent accidental deletion
- State is backed up automatically
- Tagging enforces cost tracking

## Questions & Support

- Check existing documentation
- Search for similar issues
- Ask in pull request discussion
- Open an issue with clear description

## Recognition

Contributors will be recognized in:
- Git commit history
- Project README (if desired)
- Release notes

---

Thank you for contributing to this project!

For more details, see the main README and documentation files.
