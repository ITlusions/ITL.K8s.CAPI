# Helm Chart Summary

## Helm Chart Structure

Based on the analysis of the ITL.K8s.Capi Helm chart templates, here's the complete structure and configuration:

### Core Templates

#### `_helpers.tpl`
- **Purpose**: Template helper functions for consistent naming and labeling
- **Key Functions**:
  - `itl-k8s-capi.name`: Chart name with override support
  - `itl-k8s-capi.fullname`: Full qualified app name
  - `itl-k8s-capi.vclusterName`: vcluster resource name (defaults to `<release>-vcluster` or uses `vcluster.name`)
  - `itl-k8s-capi.vclusterNamespace`: Target namespace (defaults to release namespace or uses `vcluster.namespace`)
  - `itl-k8s-capi.labels`: Common labels including environment and custom labels
  - `itl-k8s-capi.selectorLabels`: Pod selector labels

#### `vcluster.yaml`
- **Purpose**: Main CAPI resources for vcluster deployment
- **Resources Created**:
  - `Cluster` (cluster.x-k8s.io/v1beta1): CAPI cluster resource
  - `VCluster` (infrastructure.cluster.x-k8s.io/v1alpha1): vcluster infrastructure resource
- **Key Configuration**:
  - Cluster networking (pods: 10.244.0.0/16, services: 10.96.0.0/16)
  - Kubernetes version from `vcluster.cluster.kubernetesVersion`
  - Helm release configuration with chart details and values

#### `service.yaml`
- **Purpose**: External access via LoadBalancer
- **Conditions**: Only created when `externalAccess.enabled=true` and `externalAccess.type="LoadBalancer"`
- **Configuration**: 
  - Service type: LoadBalancer
  - Port mapping: 443 → 8443
  - Selector: `app=vcluster, release=<vcluster-name>`

#### `ingress.yaml`
- **Purpose**: External access via Ingress
- **Conditions**: Created when `externalAccess.enabled=true` and `externalAccess.ingress.enabled=true`
- **Features**:
  - TLS support with configurable secret
  - Custom annotations support
  - Path-based routing to vcluster service

#### `servicemonitor.yaml`
- **Purpose**: Prometheus monitoring integration
- **Conditions**: Created when `monitoring.enabled=true` and `monitoring.serviceMonitor.enabled=true`
- **Configuration**:
  - Targets vcluster pods with `app=vcluster` label
  - Metrics endpoint on `/metrics` path
  - 30s scrape interval

#### `capi-providers.yaml`
- **Purpose**: Cluster API provider definitions
- **Resources**:
  - `CoreProvider`: cluster-api v1.8.5
  - `InfrastructureProvider`: vcluster v0.2.2
- **Namespace**: capi-operator-system

### Current Configuration Values

#### Default Values (values.yaml)
```yaml
vcluster:
  name: workload-cluster                    # Default cluster name
  namespace: vcluster-system               # Default namespace
  cluster:
    kubernetesVersion: "v1.31.2"           # K8s version
  helmRelease:
    chart:
      name: vcluster                        # vcluster chart name
      repo: https://charts.loft.sh          # Chart repository
      version: 0.22.1                      # vcluster chart version
    values:
      vcluster:
        image: rancher/k3s:v1.31.2-k3s1     # K3s image
      resources:
        limits: { cpu: "2", memory: "4Gi" }
        requests: { cpu: "500m", memory: "1Gi" }
      storage:
        persistence: true
        size: "10Gi"
```

#### Development Values (values-development.yaml)
```yaml
vcluster:
  name: dev-workload                        # Development cluster name
  namespace: vcluster-dev                   # Development namespace
  helmRelease:
    values:
      resources:
        limits: { cpu: "1", memory: "2Gi" }
        requests: { cpu: "200m", memory: "512Mi" }
      storage:
        persistence: false                   # No persistence for dev
      service:
        type: NodePort                      # NodePort for dev access
```

#### Production Values (values-production.yaml)
```yaml
vcluster:
  name: prod-workload                       # Production cluster name
  namespace: vcluster-prod                  # Production namespace
  controlPlane:
    replicas: 3                             # HA setup
  helmRelease:
    values:
      resources:
        limits: { cpu: "4", memory: "8Gi" }
        requests: { cpu: "1", memory: "2Gi" }
      storage:
        persistence: true
        size: "50Gi"
        storageClass: "premium-ssd"
```

### Updated Documentation Changes

#### 1. Cluster Naming Convention
- **Old**: Generic examples (my-cluster, dev-cluster, prod-cluster)
- **New**: Standardized k8s-tst naming convention
  - Development: `k8s-tst-dev`
  - Production: `k8s-tst-prod`
  - Namespaces: `k8s-tst-dev`, `k8s-tst-prod`

#### 2. Version Updates
- **CAPI Core Provider**: v1.8.5 (confirmed in templates)
- **CAPI vcluster Provider**: v0.2.2 (updated from incorrect v0.19.2/v0.20.0)
- **vcluster Chart Version**: 0.22.1 (from values.yaml)
- **Kubernetes Version**: v1.31.2 (consistent across all configs)
- **K3s Image**: rancher/k3s:v1.31.2-k3s1

#### 3. Template Structure Documentation
- Added complete template analysis
- Documented helper functions and their purposes
- Clarified resource creation conditions
- Updated configuration examples to match actual template structure

#### 4. Resource Configuration Alignment
- Updated resource limits to match actual values.yaml defaults
- Corrected storage sizes (10Gi default, 50Gi prod)
- Added missing helm chart configuration (name, repo, version)
- Updated service selector labels to match template logic

### Key Insights from Template Analysis

1. **Conditional Resource Creation**: Templates use proper conditionals for optional resources
2. **Consistent Labeling**: Helper functions ensure consistent labeling across resources
3. **Flexible Naming**: Support for custom cluster names while providing sensible defaults
4. **Production Ready**: Proper resource management, monitoring, and external access options
5. **CAPI Integration**: Full integration with Cluster API lifecycle management

### Recommendations

1. **Use Actual Values**: All documentation now reflects actual template configurations
2. **Follow Naming Conventions**: Use k8s-tst prefix for consistency
3. **Version Alignment**: Ensure CAPI provider version v0.2.2 is used (not older versions)
4. **Template Testing**: Validate templates with `helm template` before deployment
5. **Resource Planning**: Use the documented resource requirements for capacity planning
