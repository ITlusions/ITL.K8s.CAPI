# Examples

This directory contains example configurations and use cases for the ITL K8s CAPI Helm chart.

## Available Examples

### Basic Examples
- **[Development Environment](development-environment.yaml)** - Minimal setup for local development
- **[Production Environment](production-environment.yaml)** - Production-ready configuration with HA
- **[Multi-Tenant Setup](multi-tenant-setup.yaml)** - Configuration for multiple teams/projects

### Advanced Examples
- **[External Access Examples](external-access/)** - Various ways to expose vclusters externally
- **[Monitoring Setup](monitoring-setup.yaml)** - Complete monitoring configuration
- **[Security Hardening](security-hardening.yaml)** - Enhanced security configuration
- **[Backup Configuration](backup-configuration.yaml)** - Automated backup setup

### Integration Examples
- **[GitOps Integration](gitops/)** - ArgoCD and Flux integration examples
- **[CI/CD Pipeline](cicd-pipeline.yaml)** - Automated deployment pipeline
- **[Service Mesh](service-mesh.yaml)** - Integration with Istio/Linkerd

### Use Case Examples
- **[Development Teams](use-cases/development-teams.md)** - Per-team isolated environments
- **[Testing Environments](use-cases/testing-environments.md)** - Automated testing setups
- **[Disaster Recovery](use-cases/disaster-recovery.md)** - Backup and recovery scenarios

## How to Use Examples

1. **Copy the example** that matches your use case
2. **Customize values** for your environment
3. **Test in development** first
4. **Deploy to production** with appropriate values

## Contributing Examples

To contribute new examples:

1. Create a new YAML file or directory
2. Include comprehensive comments explaining the configuration
3. Add usage instructions in comments or README
4. Test the example in a real environment
5. Submit a pull request with your example

## Example Template

```yaml
# Example: [Brief Description]
# Use Case: [What this example demonstrates]
# Prerequisites: [What needs to be installed/configured first]
# Usage: helm install example . -f this-file.yaml

global:
  environment: "example"
  labels:
    example: "true"

# Configuration with explanatory comments
vcluster:
  name: "example-cluster"
  # ... rest of configuration
```
