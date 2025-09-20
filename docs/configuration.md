# Configuration Reference

This document provides a complete reference for all configuration options available in the ITL K8s CAPI Helm chart.

## Table of Contents

- [Global Configuration](#global-configuration)
- [vcluster Configuration](#vcluster-configuration)
- [External Access](#external-access)
- [Monitoring](#monitoring)
- [High Availability](#high-availability)
- [Security](#security)
- [Backup](#backup)
- [Storage](#storage)
- [Networking](#networking)

## Global Configuration

### `global`

Global settings that apply to all components.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `global.environment` | Environment name (dev, staging, prod) | string | `"production"` |
| `global.labels` | Additional labels to apply to all resources | object | `{}` |
| `global.annotations` | Additional annotations to apply to all resources | object | `{}` |

**Example:**
```yaml
global:
  environment: "development"
  labels:
    team: "platform"
    cost-center: "engineering"
  annotations:
    managed-by: "helm"
```

## vcluster Configuration

### `vcluster`

Core vcluster configuration settings.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `vcluster.name` | Name of the vcluster | string | `"workload-cluster"` |
| `vcluster.namespace` | Target namespace for vcluster deployment | string | `"vcluster-system"` |
| `vcluster.cluster.kubernetesVersion` | Kubernetes version for the vcluster | string | `"v1.31.2"` |
| `vcluster.helmRelease.values` | Values passed to the vcluster Helm chart | object | See below |

### `vcluster.helmRelease.values`

Configuration passed directly to the vcluster Helm chart.

#### Resources

```yaml
vcluster:
  helmRelease:
    values:
      resources:
        requests:
          cpu: "500m"
          memory: "1Gi"
        limits:
          cpu: "2000m"
          memory: "4Gi"
```

#### Replica Configuration

```yaml
vcluster:
  helmRelease:
    values:
      replicas: 1  # Number of vcluster replicas
```

#### Storage Configuration

```yaml
vcluster:
  helmRelease:
    values:
      storage:
        persistence: true
        size: "20Gi"
        storageClass: "default"
        accessMode: "ReadWriteOnce"
```

#### Security Context

```yaml
vcluster:
  helmRelease:
    values:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      podSecurityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
```

#### Service Configuration

```yaml
vcluster:
  helmRelease:
    values:
      service:
        type: "ClusterIP"  # ClusterIP, NodePort, LoadBalancer
        port: 443
        targetPort: 8443
```

## External Access

### `externalAccess`

Configuration for external access to the vcluster.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `externalAccess.enabled` | Enable external access | boolean | `false` |
| `externalAccess.type` | Type of external access (LoadBalancer, Ingress, NodePort) | string | `"LoadBalancer"` |

### LoadBalancer Configuration

```yaml
externalAccess:
  enabled: true
  type: "LoadBalancer"
  loadBalancer:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    sourceRanges:
      - "10.0.0.0/8"
      - "192.168.0.0/16"
```

### Ingress Configuration

```yaml
externalAccess:
  enabled: true
  type: "Ingress"
  ingress:
    enabled: true
    className: "nginx"
    host: "vcluster.example.com"
    path: "/"
    pathType: "Prefix"
    tls:
      enabled: true
      secretName: "vcluster-tls"
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
```

### NodePort Configuration

```yaml
externalAccess:
  enabled: true
  type: "NodePort"
  nodePort: 30443
```

## Monitoring

### `monitoring`

Monitoring and observability configuration.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `monitoring.enabled` | Enable monitoring | boolean | `false` |
| `monitoring.serviceMonitor.enabled` | Create ServiceMonitor for Prometheus | boolean | `false` |
| `monitoring.serviceMonitor.namespace` | Namespace for ServiceMonitor | string | `"monitoring"` |
| `monitoring.serviceMonitor.interval` | Scrape interval | string | `"30s"` |
| `monitoring.serviceMonitor.path` | Metrics path | string | `"/metrics"` |

**Example:**
```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: "monitoring"
    interval: "15s"
    path: "/metrics"
    labels:
      app: "vcluster"
      environment: "production"
    annotations:
      prometheus.io/scrape: "true"
```

## High Availability

### `highAvailability`

High availability and resilience configuration.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `highAvailability.enabled` | Enable HA configuration | boolean | `false` |
| `highAvailability.replicas` | Number of replicas (when HA is enabled) | integer | `3` |

### Affinity Configuration

```yaml
highAvailability:
  enabled: true
  replicas: 3
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: "app"
            operator: "In"
            values:
            - "vcluster"
        topologyKey: "kubernetes.io/hostname"
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "node-type"
            operator: "In"
            values:
            - "compute"
```

### Pod Disruption Budget

```yaml
highAvailability:
  enabled: true
  podDisruptionBudget:
    enabled: true
    minAvailable: 2
    # OR
    # maxUnavailable: 1
```

## Security

### `security`

Security-related configuration options.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `security.rbac.enabled` | Enable RBAC resources | boolean | `true` |
| `security.rbac.serviceAccount.create` | Create service account | boolean | `true` |
| `security.rbac.serviceAccount.name` | Service account name | string | `""` |
| `security.networkPolicy.enabled` | Enable network policies | boolean | `false` |

### RBAC Configuration

```yaml
security:
  rbac:
    enabled: true
    serviceAccount:
      create: true
      name: "vcluster-sa"
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/vcluster-role"
    clusterRole:
      create: true
      rules:
        - apiGroups: [""]
          resources: ["nodes"]
          verbs: ["get", "list", "watch"]
```

### Network Policy Configuration

```yaml
security:
  networkPolicy:
    enabled: true
    policyTypes:
      - "Ingress"
      - "Egress"
    ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              name: "allowed-namespace"
        - podSelector:
            matchLabels:
              app: "allowed-app"
        ports:
        - protocol: "TCP"
          port: 8443
    egress:
      - to: []
        ports:
        - protocol: "TCP"
          port: 53
        - protocol: "UDP"
          port: 53
```

## Backup

### Backup Configuration

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM
  retention: "7d"
  storage:
    type: "s3"
    bucket: "vcluster-backups"
    region: "us-west-2"
    accessKey: "access-key"
    secretKey: "secret-key"
    # OR use existing secret
    existingSecret: "backup-credentials"
```

## Storage

### Persistent Volume Configuration

```yaml
storage:
  persistence:
    enabled: true
    storageClass: "premium-ssd"
    accessMode: "ReadWriteOnce"
    size: "50Gi"
    annotations:
      volume.beta.kubernetes.io/storage-provisioner: "kubernetes.io/aws-ebs"
  backup:
    enabled: true
    storageClass: "standard"
    size: "100Gi"
```

## Networking

### Service Configuration

```yaml
networking:
  service:
    type: "ClusterIP"
    port: 443
    targetPort: 8443
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "ssl"
  dns:
    enabled: true
    domain: "cluster.local"
  cni:
    enabled: true
    plugin: "flannel"  # flannel, calico, weave
```

## Environment-Specific Examples

### Development Environment

```yaml
global:
  environment: "development"

vcluster:
  name: "k8s-tst-dev"
  cluster:
    kubernetesVersion: "v1.31.2"
  helmRelease:
    chart:
      name: vcluster
      repo: https://charts.loft.sh
      version: 0.22.1
    values:
      resources:
        requests:
          cpu: "200m"
          memory: "512Mi"
        limits:
          cpu: "1"
          memory: "2Gi"
      storage:
        persistence: false

externalAccess:
  enabled: false

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: "monitoring"

highAvailability:
  enabled: false

security:
  rbac:
    enabled: true
  networkPolicy:
    enabled: false
```

### Production Environment

```yaml
global:
  environment: "production"

vcluster:
  name: "k8s-tst-prod"
  cluster:
    kubernetesVersion: "v1.31.2"
  controlPlane:
    replicas: 3
  helmRelease:
    chart:
      name: vcluster
      repo: https://charts.loft.sh
      version: 0.22.1
    values:
      resources:
        requests:
          cpu: "1"
          memory: "2Gi"
        limits:
          cpu: "4"
          memory: "8Gi"
      storage:
        persistence: true
        size: "50Gi"
        storageClass: "premium-ssd"

externalAccess:
  enabled: true
  type: "Ingress"
  ingress:
    enabled: true
    host: "vcluster.example.com"
    tls:
      enabled: true
      secretName: "vcluster-tls"

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: "monitoring"
    interval: "15s"

highAvailability:
  enabled: true
  replicas: 3
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: "app"
            operator: "In"
            values:
            - "vcluster"
        topologyKey: "kubernetes.io/hostname"

security:
  rbac:
    enabled: true
  networkPolicy:
    enabled: true
    ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              name: "monitoring"

backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: "30d"
```

## Validation

### Schema Validation

The chart includes JSON schema validation for configuration values. Invalid configurations will be rejected during installation.

### Required Values

Certain values are required depending on the configuration:

- When `externalAccess.type` is `"Ingress"`, `externalAccess.ingress.host` is required
- When `backup.enabled` is `true`, `backup.storage` configuration is required
- When `highAvailability.enabled` is `true`, `highAvailability.replicas` must be >= 2

### Value Dependencies

Some values have dependencies on others:

- `monitoring.serviceMonitor.enabled` requires `monitoring.enabled` to be `true`
- `security.networkPolicy` rules require `security.networkPolicy.enabled` to be `true`
- `backup.storage.existingSecret` takes precedence over individual credential fields
