# ITL Kubernetes Cluster API (CAPI) Helm Chart

[![Test Chart](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/test-chart.yml/badge.svg)](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/test-chart.yml)
[![Release Chart](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/release-chart.yml/badge.svg)](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/release-chart.yml)
[![Dependency Updates](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/dependency-updates.yml/badge.svg)](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/dependency-updates.yml)

This Helm chart deploys vcluster using Cluster API (CAPI) for creating lightweight, isolated Kubernetes clusters within your main cluster.

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.0+
- Cluster API (CAPI) installed with vcluster provider
- kubectl configured to access your management cluster

## Installation

### 1. Initialize Cluster API (One-time setup)

```bash
# Install clusterctl (if not already installed)
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/latest/download/clusterctl-windows-amd64.exe -o clusterctl.exe

# Initialize Cluster API with vcluster provider
clusterctl init --infrastructure vcluster

# Verify installation
kubectl get pods -n capi-system
kubectl get pods -n capi-vcluster-system
```

### 2. Deploy the Helm Chart

#### Development Deployment

```bash
# Create namespace
kubectl create namespace vcluster-dev

# Deploy for development
helm install dev-vcluster . \
  --namespace vcluster-dev \
  --values values-development.yaml \
  --wait

# Get kubeconfig for the vcluster
kubectl get secret dev-workload-kubeconfig -n vcluster-dev -o jsonpath='{.data.kubeconfig}' | base64 -d > dev-kubeconfig.yaml
export KUBECONFIG=dev-kubeconfig.yaml
```

#### Production Deployment

```bash
# Create namespace
kubectl create namespace vcluster-prod

# Deploy for production
helm install prod-vcluster . \
  --namespace vcluster-prod \
  --values values-production.yaml \
  --wait

# Get kubeconfig for the vcluster
kubectl get secret prod-workload-kubeconfig -n vcluster-prod -o jsonpath='{.data.kubeconfig}' | base64 -d > prod-kubeconfig.yaml
export KUBECONFIG=prod-kubeconfig.yaml
```

### 3. Custom Deployment

```bash
# Create your own values file
cp values.yaml my-values.yaml

# Edit my-values.yaml with your specific configuration
# Then deploy
helm install my-vcluster . \
  --namespace my-namespace \
  --values my-values.yaml \
  --wait
```

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.environment` | Environment name | `production` |
| `vcluster.name` | Name of the vcluster | `workload-cluster` |
| `vcluster.namespace` | Namespace for vcluster | `vcluster-system` |
| `vcluster.cluster.kubernetesVersion` | Kubernetes version | `v1.31.2` |
| `externalAccess.enabled` | Enable external access | `false` |
| `externalAccess.type` | Service type for external access | `LoadBalancer` |
| `monitoring.enabled` | Enable monitoring | `false` |
| `highAvailability.enabled` | Enable HA configuration | `false` |

### Storage Configuration

```yaml
vcluster:
  helmRelease:
    values:
      storage:
        persistence: true
        size: "20Gi"
        storageClass: "premium-ssd"
```

### External Access via Ingress

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

### High Availability

```yaml
highAvailability:
  enabled: true
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

## Monitoring

Enable monitoring to integrate with Prometheus:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
```

## Troubleshooting

### Check Cluster Status

```bash
# Check clusters
kubectl get clusters -n <namespace>

# Check vclusters
kubectl get vclusters -n <namespace>

# Check pods
kubectl get pods -n <namespace>
```

### View Logs

```bash
# View vcluster controller logs
kubectl logs -n capi-vcluster-system -l control-plane=controller-manager

# View specific vcluster logs
kubectl logs -n <namespace> -l app=vcluster
```

### Access vcluster

```bash
# Get kubeconfig
kubectl get secret <cluster-name>-kubeconfig -n <namespace> -o jsonpath='{.data.kubeconfig}' | base64 -d > vcluster-kubeconfig.yaml

# Use the kubeconfig
export KUBECONFIG=vcluster-kubeconfig.yaml
kubectl get nodes
```

## Upgrading

```bash
# Upgrade the chart
helm upgrade <release-name> . \
  --namespace <namespace> \
  --values <values-file> \
  --wait

# Check upgrade status
helm status <release-name> -n <namespace>
```

## Uninstalling

```bash
# Uninstall the chart
helm uninstall <release-name> -n <namespace>

# Clean up resources (if needed)
kubectl delete namespace <namespace>
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the changes
5. Submit a pull request

## Support

For issues and questions:
- Create an issue in the repository
- Contact: info@itlusions.com
