# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the ITL K8s CAPI Helm chart.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Cluster API Issues](#cluster-api-issues)
- [vcluster Issues](#vcluster-issues)
- [Networking Issues](#networking-issues)
- [Performance Issues](#performance-issues)
- [Monitoring Issues](#monitoring-issues)
- [Security Issues](#security-issues)
- [Diagnostic Commands](#diagnostic-commands)

## Installation Issues

### Chart Installation Fails

**Symptoms:**
- Helm install command fails
- Error messages about missing resources or invalid values

**Common Causes and Solutions:**

#### 1. Missing Cluster API Installation

**Error:** `no matches for kind "Cluster" in version "cluster.x-k8s.io/v1beta1"`

**Solution:**
```bash
# Verify CAPI installation
kubectl get crd | grep cluster.x-k8s.io

# If missing, install CAPI
helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm install cluster-api-operator capi-operator/cluster-api-operator \
  --create-namespace \
  --namespace capi-operator-system
```

#### 2. Invalid Configuration Values

**Error:** `values don't meet the specifications of the schema`

**Solution:**
```bash
# Validate your values file
helm template test-release . --values your-values.yaml --validate

# Check for required fields
grep -n "required" values.yaml
```

#### 3. Insufficient RBAC Permissions

**Error:** `cannot create resource "clusters" in API group "cluster.x-k8s.io"`

**Solution:**
```bash
# Check current permissions
kubectl auth can-i create clusters.cluster.x-k8s.io

# If using service account, verify RBAC
kubectl describe clusterrole cluster-admin
```

### Helm Template Rendering Issues

**Symptoms:**
- Template parsing errors
- Unexpected template output

**Diagnostic Steps:**
```bash
# Debug template rendering
helm template debug-release . --debug --values values-development.yaml

# Test specific template
helm template debug-release . --show-only templates/vcluster.yaml

# Validate YAML output
helm template test-release . | kubectl apply --dry-run=client -f -
```

## Cluster API Issues

### Provider Installation Failures

**Symptoms:**
- InfrastructureProvider not becoming ready
- Error messages about version not found

**Common Issues:**

#### 1. Incorrect Provider Version

**Error:** `release not found for version v0.20.0`

**Solution:**
```bash
# Check available versions
kubectl describe infrastructureprovider vcluster -n capi-operator-system

# Try a different version (current supported version)
kubectl patch infrastructureprovider vcluster -n capi-operator-system \
  --type merge -p '{"spec":{"version":"v0.2.2"}}'
```

#### 2. Network Connectivity Issues

**Error:** `failed to download provider manifests`

**Solution:**
```bash
# Check operator logs
kubectl logs -n capi-operator-system deployment/cluster-api-operator

# Test connectivity from cluster
kubectl run test-connectivity --image=busybox --rm -it -- \
  wget -qO- https://github.com/loft-sh/cluster-api-provider-vcluster/releases
```

#### 3. Resource Constraints

**Error:** `insufficient memory` or `insufficient cpu`

**Solution:**
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Scale cluster or add resources
```

### Core Provider Issues

**Symptoms:**
- CoreProvider not installing
- CAPI controllers not starting

**Diagnostic Steps:**
```bash
# Check core provider status
kubectl get coreprovider cluster-api -n capi-operator-system -o yaml

# Check controller pods
kubectl get pods -n capi-system

# View controller logs
kubectl logs -n capi-system -l control-plane=controller-manager
```

## vcluster Issues

### Cluster Not Starting

**Symptoms:**
- Cluster stuck in "Provisioning" state
- VCluster resource shows errors

**Common Causes:**

#### 1. Resource Limits

**Error:** `pod has unbound immediate PersistentVolumeClaims`

**Solution:**
```bash
# Check storage class
kubectl get storageclass

# Update values to use available storage class
helm upgrade release-name . --set vcluster.helmRelease.values.storage.storageClass=standard
```

#### 2. Image Pull Issues

**Error:** `ErrImagePull` or `ImagePullBackOff`

**Solution:**
```bash
# Check pod events
kubectl describe pod <vcluster-pod> -n <namespace>

# Verify image accessibility
kubectl run test-image --image=rancher/k3s:v1.31.2-k3s1 --rm -it -- /bin/sh
```

#### 3. Network Policy Blocking

**Error:** Pods can't reach each other or external services

**Solution:**
```bash
# Temporarily disable network policies
kubectl annotate namespace <namespace> networking.kubernetes.io/network-policy-

# Check existing policies
kubectl get networkpolicy -n <namespace>
```

### Cluster API Server Issues

**Symptoms:**
- Can't connect to vcluster API server
- Authentication failures

**Diagnostic Steps:**
```bash
# Check vcluster service
kubectl get svc -n <namespace>

# Test internal connectivity
kubectl run test-conn --image=busybox --rm -it -- \
  nc -zv <vcluster-service>.<namespace>.svc.cluster.local 443

# Check certificates
kubectl get secret <cluster-name>-kubeconfig -n <namespace> -o yaml
```

## Networking Issues

### External Access Problems

**Symptoms:**
- Can't access vcluster from outside the cluster
- Ingress/LoadBalancer not working

#### LoadBalancer Issues

**Solution:**
```bash
# Check service status
kubectl get svc -n <namespace>

# Check cloud provider integration
kubectl describe svc <service-name> -n <namespace>

# Test with NodePort temporarily
helm upgrade release-name . --set externalAccess.type=NodePort
```

#### Ingress Issues

**Solution:**
```bash
# Check ingress status
kubectl get ingress -n <namespace>

# Verify ingress controller
kubectl get pods -n ingress-system

# Check DNS resolution
nslookup <ingress-host>

# Test with port-forward
kubectl port-forward svc/<vcluster-service> 8443:443 -n <namespace>
```

### DNS Resolution Issues

**Symptoms:**
- Services can't resolve DNS names
- Inter-pod communication failures

**Solution:**
```bash
# Test DNS from within vcluster
export KUBECONFIG=vcluster-kubeconfig.yaml
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes.default

# Check CoreDNS in main cluster
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check vcluster DNS configuration
kubectl get configmap coredns -n kube-system -o yaml
```

## Performance Issues

### Slow Cluster Creation

**Symptoms:**
- vcluster takes too long to become ready
- Resource allocation delays

**Solutions:**
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n <namespace>

# Increase resource limits
helm upgrade release-name . \
  --set vcluster.helmRelease.values.resources.limits.cpu=2000m \
  --set vcluster.helmRelease.values.resources.limits.memory=4Gi

# Use faster storage class
helm upgrade release-name . \
  --set vcluster.helmRelease.values.storage.storageClass=premium-ssd
```

### High Memory Usage

**Symptoms:**
- Pods being OOMKilled
- Node resource exhaustion

**Solutions:**
```bash
# Monitor memory usage
kubectl top pods -n <namespace> --containers

# Increase memory limits
helm upgrade release-name . \
  --set vcluster.helmRelease.values.resources.limits.memory=8Gi

# Enable swap (if appropriate)
# Configure resource quotas
```

## Monitoring Issues

### ServiceMonitor Not Created

**Symptoms:**
- Prometheus not scraping metrics
- Missing metrics in Grafana

**Solution:**
```bash
# Verify monitoring is enabled
helm get values release-name | grep -A 10 monitoring

# Check ServiceMonitor resource
kubectl get servicemonitor -n monitoring

# Verify Prometheus operator
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-operator
```

### Missing Metrics

**Symptoms:**
- Empty dashboards
- No data in Prometheus

**Solution:**
```bash
# Check metrics endpoint
kubectl port-forward svc/<vcluster-service> 8443:443 -n <namespace>
curl -k https://localhost:8443/metrics

# Verify service labels match ServiceMonitor selector
kubectl get svc <vcluster-service> -n <namespace> --show-labels
```

## Security Issues

### RBAC Permission Denied

**Symptoms:**
- Operations fail with permission errors
- Service account can't access resources

**Solution:**
```bash
# Check service account permissions
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<sa-name>

# Review RBAC resources
kubectl get clusterrole,clusterrolebinding | grep vcluster

# Update RBAC if necessary
```

### Certificate Issues

**Symptoms:**
- TLS handshake failures
- Certificate verification errors

**Solution:**
```bash
# Check certificate expiration
kubectl get secret <tls-secret> -n <namespace> -o yaml | \
  yq '.data."tls.crt"' | base64 -d | openssl x509 -text -noout

# Regenerate certificates
kubectl delete secret <tls-secret> -n <namespace>
# Restart vcluster pods to regenerate
```

## Diagnostic Commands

### Cluster Status

```bash
# Overall cluster health
kubectl get clusters,vclusters -A

# Detailed cluster info
kubectl describe cluster <cluster-name> -n <namespace>

# Check all resources in namespace
kubectl get all -n <namespace>
```

### Event Monitoring

```bash
# Recent events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -n <namespace> --watch

# Events for specific resource
kubectl describe <resource-type> <resource-name> -n <namespace>
```

### Log Analysis

```bash
# vcluster controller logs
kubectl logs -n capi-vcluster-system -l control-plane=controller-manager

# Specific vcluster logs
kubectl logs -n <namespace> -l app=vcluster

# Follow logs in real-time
kubectl logs -f -n <namespace> <pod-name>

# Previous pod logs (for crashed pods)
kubectl logs -p -n <namespace> <pod-name>
```

### Resource Usage

```bash
# Node resources
kubectl top nodes

# Pod resources by namespace
kubectl top pods -n <namespace>

# Resource quotas
kubectl get resourcequota -n <namespace>

# Persistent volume usage
kubectl get pv,pvc
```

### Network Diagnostics

```bash
# Test connectivity between pods
kubectl exec -it <pod1> -n <namespace> -- ping <pod2-ip>

# Test external connectivity
kubectl exec -it <pod> -n <namespace> -- curl -I https://kubernetes.io

# Check DNS resolution
kubectl exec -it <pod> -n <namespace> -- nslookup kubernetes.default

# Port forwarding for testing
kubectl port-forward svc/<service> 8080:80 -n <namespace>
```

### Configuration Verification

```bash
# Current Helm values
helm get values <release-name> -n <namespace>

# Rendered templates
helm get manifest <release-name> -n <namespace>

# Chart status
helm status <release-name> -n <namespace>

# Template validation
helm template <release-name> . --validate
```

## Getting Help

### Self-Service Resources

1. **Check logs** first using the diagnostic commands above
2. **Review configuration** against the [Configuration Reference](configuration.md)
3. **Search issues** in the project repository
4. **Consult documentation**:
   - [User Guide](user-guide.md)
   - [FAQ](faq.md)
   - [Cluster API Documentation](https://cluster-api.sigs.k8s.io/)
   - [vcluster Documentation](https://www.vcluster.com/docs/)

### Reporting Issues

When reporting issues, include:

1. **Environment information**:
   ```bash
   kubectl version
   helm version
   kubectl get nodes -o wide
   ```

2. **Chart information**:
   ```bash
   helm list -A
   helm get values <release-name>
   ```

3. **Error logs**:
   ```bash
   kubectl logs -n <namespace> <pod-name>
   kubectl get events -n <namespace> --sort-by='.lastTimestamp'
   ```

4. **Resource status**:
   ```bash
   kubectl get clusters,vclusters -A
   kubectl describe cluster <cluster-name> -n <namespace>
   ```

### Contact Information

- **Repository Issues**: Open an issue in the project repository
- **Email Support**: info@itlusions.com
- **Emergency Support**: (Contact information for critical issues)
