# Frequently Asked Questions (FAQ)

This document answers common questions about the ITL K8s CAPI Helm chart.

## General Questions

### What is vcluster and why would I use it?

vcluster is a tool that creates fully functional virtual Kubernetes clusters inside existing Kubernetes clusters. Key benefits include:

- **Resource Efficiency**: Share underlying infrastructure while maintaining isolation
- **Multi-tenancy**: Provide isolated environments for different teams or applications
- **Development/Testing**: Create disposable clusters for testing without infrastructure overhead
- **Security**: Complete API server isolation for sensitive workloads
- **Cost Savings**: Reduce infrastructure costs by sharing physical resources

### How does this chart differ from the standard vcluster Helm chart?

Our chart adds several enterprise features:
- **Cluster API Integration**: Uses CAPI for standardized cluster lifecycle management
- **Production-Ready Defaults**: Optimized for production deployments
- **High Availability**: Built-in HA configuration options
- **Monitoring Integration**: Native Prometheus/Grafana support
- **Security Hardening**: Enhanced RBAC and network policies
- **Backup Support**: Automated backup configurations

### What are the system requirements?

**Minimum Requirements:**
- Kubernetes 1.19+
- 2 CPU cores per vcluster
- 4GB RAM per vcluster
- 20GB storage per vcluster

**Recommended for Production:**
- Kubernetes 1.24+
- 4+ CPU cores per vcluster
- 8GB+ RAM per vcluster
- SSD storage with 100GB+ per vcluster
- Multiple worker nodes for HA

## Installation Questions

### Do I need to install Cluster API manually?

No, the chart includes instructions for installing CAPI via Helm. You can use either:

1. **Helm Installation (Recommended)**:
```bash
helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm install cluster-api-operator capi-operator/cluster-api-operator \
  --create-namespace --namespace capi-operator-system
```

2. **clusterctl Installation**:
```bash
clusterctl init --infrastructure vcluster
```

### Can I install multiple vclusters in the same namespace?

While technically possible, it's not recommended. Each vcluster should have its own namespace to:
- Avoid resource conflicts
- Improve security isolation
- Simplify management and troubleshooting
- Enable proper RBAC boundaries

### Why is my vcluster taking so long to start?

Common causes and solutions:

1. **Resource Constraints**: Check if nodes have sufficient CPU/memory
2. **Storage Issues**: Ensure storage class is available and provisioning works
3. **Image Pulling**: Large Kubernetes images may take time to download
4. **Network Policies**: Restrictive policies might block initialization

**Quick diagnostic**:
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
kubectl describe cluster <cluster-name> -n <namespace>
```

## Configuration Questions

### How do I enable external access to my vcluster?

You have three options:

1. **LoadBalancer** (Recommended for cloud):
```yaml
externalAccess:
  enabled: true
  type: LoadBalancer
```

2. **Ingress** (Best for multiple clusters):
```yaml
externalAccess:
  enabled: true
  type: Ingress
  ingress:
    enabled: true
    host: vcluster.example.com
```

3. **NodePort** (For development):
```yaml
externalAccess:
  enabled: true
  type: NodePort
  nodePort: 30443
```

### Can I use my own storage class?

Yes, specify it in your values:

```yaml
vcluster:
  helmRelease:
    values:
      storage:
        storageClass: "my-premium-ssd"
        size: "100Gi"
```

### How do I configure high availability?

Enable HA in your values file:

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

### Can I customize the Kubernetes version in my vcluster?

Yes, set the version in your values:

```yaml
vcluster:
  cluster:
    kubernetesVersion: "v1.31.2"
  helmRelease:
    chart:
      name: vcluster
      repo: https://charts.loft.sh
      version: 0.22.1
    values:
      vcluster:
        image: "rancher/k3s:v1.31.2-k3s1"
```

## Operational Questions

### How do I access my vcluster once it's running?

1. **Get the kubeconfig**:
```bash
kubectl get secret <cluster-name>-kubeconfig -n <namespace> \
  -o jsonpath='{.data.kubeconfig}' | base64 -d > vcluster-kubeconfig.yaml
```

2. **Use the kubeconfig**:
```bash
export KUBECONFIG=vcluster-kubeconfig.yaml
kubectl get nodes
```

3. **Or use multiple contexts**:
```bash
kubectl config set-context vcluster --kubeconfig=vcluster-kubeconfig.yaml
kubectl config use-context vcluster
```

### How do I upgrade my vcluster?

Use Helm upgrade:

```bash
helm upgrade <release-name> . \
  --namespace <namespace> \
  --values <values-file> \
  --wait
```

For Kubernetes version upgrades, update both chart values and test thoroughly.

### Can I backup my vcluster?

Yes, enable backup in your values:

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM
  retention: "7d"
  storage:
    type: "s3"
    bucket: "vcluster-backups"
```

### How do I monitor my vclusters?

Enable monitoring in your values:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
```

This creates ServiceMonitor resources for Prometheus scraping.

### What happens if my vcluster pod crashes?

The vcluster will automatically restart thanks to Kubernetes' self-healing:
- Deployment controller recreates failed pods
- Persistent data is preserved (if persistence is enabled)
- Connections will temporarily fail but resume once the pod is ready

## Troubleshooting Questions

### My vcluster is stuck in "Provisioning" state. What should I check?

1. **Check events**:
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

2. **Check provider logs**:
```bash
kubectl logs -n capi-vcluster-system -l control-plane=controller-manager
```

3. **Verify resources**:
```bash
kubectl describe cluster <cluster-name> -n <namespace>
```

Common issues: insufficient resources, storage problems, or network policies.

### I can't connect to my vcluster. What's wrong?

1. **Check if cluster is ready**:
```bash
kubectl get clusters -n <namespace>
```

2. **Verify service is running**:
```bash
kubectl get svc -n <namespace>
```

3. **Test connectivity**:
```bash
kubectl port-forward svc/<vcluster-service> 8443:443 -n <namespace>
```

4. **Check kubeconfig**:
```bash
kubectl get secret <cluster-name>-kubeconfig -n <namespace>
```

### How do I debug template rendering issues?

Use Helm's debug capabilities:

```bash
# Debug template rendering
helm template debug-release . --debug

# Validate specific template
helm template test . --show-only templates/vcluster.yaml

# Dry run with validation
helm install test . --dry-run --validate
```

## Security Questions

### Is vcluster secure for multi-tenant environments?

vcluster provides strong isolation:
- **API Server Isolation**: Each vcluster has its own API server
- **Namespace Isolation**: Resources are scoped to specific namespaces
- **RBAC Separation**: Independent permission systems
- **Network Isolation**: Can be enhanced with network policies

However, consider additional security measures for highly sensitive workloads.

### How do I implement network policies?

Enable network policies in your values:

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

### Can I use my own TLS certificates?

Yes, provide them via Kubernetes secrets:

```yaml
externalAccess:
  ingress:
    tls:
      enabled: true
      secretName: my-tls-secret
```

## Performance Questions

### How many vclusters can I run on my cluster?

This depends on:
- **Node Resources**: CPU, memory, and storage capacity
- **Workload Requirements**: What applications run in each vcluster
- **Network Capacity**: Pod-to-pod communication overhead
- **Storage Performance**: I/O requirements

As a rough guideline:
- **Small vclusters**: 20-50 per cluster (development/testing)
- **Medium vclusters**: 5-20 per cluster (staging environments)
- **Large vclusters**: 2-10 per cluster (production workloads)

### How do I optimize performance?

1. **Use SSD storage**:
```yaml
vcluster:
  helmRelease:
    values:
      storage:
        storageClass: "premium-ssd"
```

2. **Allocate sufficient resources**:
```yaml
vcluster:
  helmRelease:
    values:
      resources:
        requests:
          cpu: "1000m"
          memory: "2Gi"
```

3. **Enable resource limits**:
```yaml
vcluster:
  helmRelease:
    values:
      resources:
        limits:
          cpu: "4000m"
          memory: "8Gi"
```

## Migration Questions

### Can I migrate from standalone vcluster to this chart?

Yes, but requires careful planning:

1. **Backup existing data** from your current vcluster
2. **Create new vcluster** using this chart
3. **Migrate applications** and data
4. **Update DNS/ingress** to point to new vcluster
5. **Verify functionality** before decommissioning old cluster

### How do I migrate between different chart versions?

1. **Backup current state**
2. **Review changelog** for breaking changes
3. **Update values** to match new schema
4. **Test in non-production** environment first
5. **Perform rolling upgrade**:
```bash
helm upgrade <release-name> . --values <updated-values.yaml>
```

## Integration Questions

### Can I integrate with GitOps tools?

Yes, this chart works well with:
- **ArgoCD**: Deploy and manage via ArgoCD applications
- **Flux**: Use HelmReleases to manage deployments
- **Tekton**: Integrate into CI/CD pipelines

Example ArgoCD application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vcluster-dev
spec:
  source:
    repoURL: <chart-repo>
    chart: itl-k8s-capi
    targetRevision: 1.0.0
    helm:
      valueFiles:
        - values-development.yaml
```

### Does this work with service mesh?

Yes, vclusters can integrate with service meshes like Istio or Linkerd. However, consider:
- **Cross-cluster communication** requirements
- **Certificate management** between clusters
- **Network policy** interactions
- **Performance overhead** of mesh proxy

### Can I use this with CI/CD pipelines?

Absolutely! Common patterns:
- **Ephemeral environments**: Create temporary vclusters for PR testing
- **Environment promotion**: Use different values files for dev/staging/prod
- **Automated testing**: Deploy applications to isolated vclusters

## Cost Questions

### How does vcluster reduce costs?

- **Infrastructure Sharing**: Multiple logical clusters on same physical infrastructure
- **Resource Efficiency**: Better resource utilization vs separate clusters
- **Operational Overhead**: Single cluster to maintain instead of many
- **Development Productivity**: Faster environment provisioning

### What are the resource overheads?

Each vcluster adds:
- **Control Plane**: ~200-500MB memory, 0.1-0.2 CPU cores
- **Storage**: ~1-5GB for system components
- **Network**: Minimal overhead for pod-to-pod communication

## Support Questions

### How do I get help?

1. **Check this FAQ** and documentation
2. **Review troubleshooting guide**
3. **Search existing issues** in the repository
4. **Open new issue** with detailed information
5. **Contact support**: info@itlusions.com

### What information should I include when reporting issues?

Include:
- Kubernetes and Helm versions
- Chart version and values used
- Complete error messages and logs
- Output of diagnostic commands
- Steps to reproduce the issue

### Is commercial support available?

Yes, ITlusions provides commercial support including:
- **Professional Services**: Implementation and migration assistance
- **Training**: Team training on vcluster and Cluster API
- **Custom Development**: Chart customizations and integrations
- **24/7 Support**: Critical issue response for production environments

Contact: info@itlusions.com for more information.
