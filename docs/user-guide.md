# User Guide

This comprehensive guide covers everything you neapiVersion: operator.cluster.x-k8s.io/v1alpha2
kind: CoreProvider
metadata:
  name: cluster-api
  namespace: capi-operator-system
spec:
  version: v1.8.5
---
apiVersion: operator.cluster.x-k8s.io/v1alpha2
kind: InfrastructureProvider
metadata:
  name: vcluster
  namespace: capi-operator-system
spec:
  version: v0.2.2t deploying and managing vclusters using the ITL K8s CAPI Helm chart.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Managing vclusters](#managing-vclusters)
- [Monitoring](#monitoring)
- [Security](#security)
- [Backup and Recovery](#backup-and-recovery)
- [Troubleshooting](#troubleshooting)

## Overview

The ITL K8s CAPI Helm chart provides a production-ready way to deploy and manage vclusters using Cluster API. vclusters are lightweight, isolated Kubernetes environments that run within your main cluster, offering:

- **Resource Isolation**: Each vcluster has its own namespace and resource boundaries
- **API Server Isolation**: Complete Kubernetes API separation
- **Cost Efficiency**: Share underlying infrastructure while maintaining isolation
- **Multi-tenancy**: Perfect for development, testing, and multi-tenant scenarios

## Prerequisites

### System Requirements

- **Kubernetes Cluster**: Version 1.19 or later
- **CPU**: Minimum 2 cores per vcluster
- **Memory**: Minimum 4GB RAM per vcluster
- **Storage**: 20GB per vcluster (configurable)

### Required Tools

- `kubectl` (version 1.19+)
- `helm` (version 3.0+)
- Administrative access to install Cluster API

### Network Requirements

- Pod-to-pod communication within the cluster
- Access to external container registries (if using custom images)
- DNS resolution for cluster services

## Installation

### 1. Cluster API Setup

#### Option A: Using Helm (Recommended)

```bash
# Add and update the CAPI operator repository
helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm repo update

# Install the Cluster API operator
helm install cluster-api-operator capi-operator/cluster-api-operator \
  --create-namespace \
  --namespace capi-operator-system \
  --wait

# Install providers
kubectl apply -f - <<EOF
apiVersion: operator.cluster.x-k8s.io/v1alpha2
kind: CoreProvider
metadata:
  name: cluster-api
  namespace: capi-operator-system
spec:
  version: v1.8.5
---
apiVersion: operator.cluster.x-k8s.io/v1alpha2
kind: InfrastructureProvider
metadata:
  name: vcluster
  namespace: capi-operator-system
spec:
  version: v0.19.2
EOF
```

#### Option B: Using clusterctl

```bash
# Install clusterctl
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/latest/download/clusterctl-linux-amd64 -o clusterctl
chmod +x clusterctl
sudo mv clusterctl /usr/local/bin/

# Initialize Cluster API
clusterctl init --infrastructure vcluster
```

### 2. Verify Installation

```bash
# Check CAPI components
kubectl get pods -n capi-system
kubectl get pods -n capi-vcluster-system

# Verify providers are ready
kubectl get coreprovider,infrastructureprovider -n capi-operator-system
```

### 3. Deploy vcluster

Choose your deployment scenario:

#### Development Environment

```bash
kubectl create namespace k8s-tst-dev
helm install k8s-tst-dev . \
  --namespace k8s-tst-dev \
  --values values-development.yaml \
  --wait
```

#### Production Environment

```bash
kubectl create namespace k8s-tst-prod
helm install k8s-tst-prod . \
  --namespace k8s-tst-prod \
  --values values-production.yaml \
  --wait
```

## Configuration

### Environment-Specific Configurations

#### Development Configuration
The development configuration (`values-development.yaml`) includes:
- Minimal resource requests
- Single replica
- Simplified networking
- Debug logging enabled

#### Production Configuration
The production configuration (`values-production.yaml`) includes:
- High availability setup
- Resource limits and requests
- Persistent storage
- Security hardening
- Monitoring enabled

### Key Configuration Areas

#### Resource Management

```yaml
vcluster:
  helmRelease:
    values:
      resources:
        requests:
          cpu: 500m
          memory: 1Gi
        limits:
          cpu: 2000m
          memory: 4Gi
```

#### Storage Configuration

```yaml
vcluster:
  helmRelease:
    values:
      storage:
        persistence: true
        size: "50Gi"
        storageClass: "premium-ssd"
        accessMode: ReadWriteOnce
```

#### High Availability

```yaml
highAvailability:
  enabled: true
  replicas: 3
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - vcluster
        topologyKey: kubernetes.io/hostname
```

## Managing vclusters

### Accessing Your vcluster

1. **Get the kubeconfig**:
```bash
kubectl get secret <cluster-name>-kubeconfig -n <namespace> \
  -o jsonpath='{.data.kubeconfig}' | base64 -d > vcluster-kubeconfig.yaml
```

2. **Use the vcluster**:
```bash
export KUBECONFIG=vcluster-kubeconfig.yaml
kubectl get nodes
```

### Scaling vclusters

Update the number of replicas:

```bash
helm upgrade <release-name> . \
  --namespace <namespace> \
  --set highAvailability.replicas=5 \
  --wait
```

### Upgrading vclusters

```bash
# Update to new chart version
helm upgrade <release-name> . \
  --namespace <namespace> \
  --values <values-file> \
  --wait

# Check upgrade status
kubectl get clusters,vclusters -n <namespace>
```

## Monitoring

### Enable Monitoring

Add monitoring configuration to your values file:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
    interval: 30s
    path: /metrics
    labels:
      app: vcluster
```

### Metrics Available

- CPU and memory usage
- API server metrics
- etcd metrics (if enabled)
- Custom vcluster metrics

### Integration with Prometheus

The chart creates ServiceMonitor resources for Prometheus scraping:

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n monitoring

# View metrics in Prometheus
# Query: vcluster_api_requests_total
```

## Security

### RBAC Configuration

The chart creates minimal RBAC resources:

```yaml
security:
  rbac:
    enabled: true
    serviceAccount:
      create: true
      name: vcluster-sa
```

### Network Policies

Enable network policies for enhanced security:

```yaml
security:
  networkPolicy:
    enabled: true
    ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              name: allowed-namespace
```

### Pod Security Standards

Configure pod security context:

```yaml
vcluster:
  helmRelease:
    values:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
```

## Backup and Recovery

### Automated Backups

Configure automated etcd backups:

```yaml
vcluster:
  helmRelease:
    values:
      backups:
        enabled: true
        schedule: "0 2 * * *"  # Daily at 2 AM
        retention: "7d"
        storage:
          type: "s3"
          bucket: "vcluster-backups"
```

### Manual Backup

```bash
# Create a manual backup
kubectl exec -n <namespace> <vcluster-pod> -- \
  etcdctl snapshot save /backup/manual-backup-$(date +%Y%m%d).db
```

### Recovery Process

1. **Stop the vcluster**:
```bash
kubectl scale deployment <vcluster-deployment> --replicas=0 -n <namespace>
```

2. **Restore from backup**:
```bash
kubectl exec -n <namespace> <vcluster-pod> -- \
  etcdctl snapshot restore /backup/backup-file.db
```

3. **Restart the vcluster**:
```bash
kubectl scale deployment <vcluster-deployment> --replicas=1 -n <namespace>
```

## External Access

### LoadBalancer Service

```yaml
externalAccess:
  enabled: true
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

### Ingress Configuration

```yaml
externalAccess:
  enabled: true
  type: Ingress
  ingress:
    enabled: true
    host: vcluster.example.com
    tls:
      enabled: true
      secretName: vcluster-tls
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
```

### NodePort Service

```yaml
externalAccess:
  enabled: true
  type: NodePort
  nodePort: 30443
```

## Troubleshooting

### Common Issues

1. **vcluster not starting**: Check resource limits and storage availability
2. **Can't access vcluster**: Verify network policies and service configuration
3. **Performance issues**: Monitor resource usage and consider scaling

### Diagnostic Commands

```bash
# Check cluster status
kubectl get clusters,vclusters -n <namespace>

# View controller logs
kubectl logs -n capi-vcluster-system -l control-plane=controller-manager

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Describe resources
kubectl describe cluster <cluster-name> -n <namespace>
kubectl describe vcluster <vcluster-name> -n <namespace>
```

For more detailed troubleshooting, see the [Troubleshooting Guide](troubleshooting.md).

## Best Practices

### Resource Planning
- Plan resource allocation based on workload requirements
- Use resource quotas to prevent resource exhaustion
- Monitor resource usage regularly

### Security
- Enable RBAC and network policies
- Use least privilege principle
- Regularly update chart and component versions

### High Availability
- Use anti-affinity rules for production deployments
- Configure persistent storage
- Enable monitoring and alerting

### Lifecycle Management
- Use GitOps for configuration management
- Implement automated backup strategies
- Plan upgrade procedures

## Support

For additional help:
- Review the [FAQ](faq.md)
- Check [Troubleshooting](troubleshooting.md)
- Open an issue in the repository
- Contact: info@itlusions.com
