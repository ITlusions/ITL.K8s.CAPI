# Quick Start Guide

Get your vcluster up and running in minutes with this quick start guide.

## Prerequisites

Before you begin, ensure you have:

- A Kubernetes cluster (version 1.19 or later)
- `kubectl` configured to access your cluster
- `helm` (version 3.0 or later)
- Administrative access to install Cluster API

## Step 1: Install Cluster API

Install the Cluster API operator using Helm:

```bash
# Add the CAPI operator Helm repository
helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm repo update

# Install the Cluster API operator
helm install cluster-api-operator capi-operator/cluster-api-operator \
  --create-namespace \
  --namespace capi-operator-system \
  --wait
```

## Step 2: Install Cluster API Providers

Create the provider configuration:

```bash
# Create providers configuration
cat <<EOF | kubectl apply -f -
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
  version: v0.2.2
EOF
```

Wait for the providers to be ready:

```bash
# Check installation status
kubectl get coreprovider,infrastructureprovider -n capi-operator-system

# Wait for READY status to show True
kubectl wait --for=condition=ProviderInstalled=true infrastructureprovider/vcluster -n capi-operator-system --timeout=300s
```

## Step 3: Deploy Your First vcluster

Clone or download this Helm chart, then deploy:

```bash
# Create a namespace for your vcluster
kubectl create namespace k8s-tst

# Deploy using development values
helm install k8s-tst . \
  --namespace k8s-tst \
  --values values-development.yaml \
  --wait
```

## Step 4: Access Your vcluster

Get the kubeconfig for your new vcluster:

```bash
# Wait for the cluster to be ready
kubectl wait --for=condition=Ready cluster/dev-workload -n k8s-tst --timeout=600s

# Extract the kubeconfig
kubectl get secret dev-workload-kubeconfig -n k8s-tst \
  -o jsonpath='{.data.kubeconfig}' | base64 -d > k8s-tst-kubeconfig.yaml

# Use the vcluster
export KUBECONFIG=k8s-tst-kubeconfig.yaml
kubectl get nodes
kubectl get namespaces
```

## Step 5: Deploy Applications

Your vcluster is ready! Deploy applications just like on any Kubernetes cluster:

```bash
# Create a simple deployment
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=ClusterIP

# Check the deployment
kubectl get pods
kubectl get services
```

## Next Steps

- **Customize Configuration**: Review [Configuration Reference](configuration.md) to customize your deployment
- **Production Setup**: See [User Guide](user-guide.md) for production configurations
- **Monitoring**: Learn how to enable monitoring in the [User Guide](user-guide.md#monitoring)
- **External Access**: Configure external access options in [Configuration Reference](configuration.md#external-access)

## Cleanup

To remove your vcluster:

```bash
# Delete the Helm release
helm uninstall k8s-tst -n k8s-tst

# Delete the namespace
kubectl delete namespace k8s-tst

# Reset kubeconfig
unset KUBECONFIG
```

## Troubleshooting

If you encounter issues:

1. Check cluster status: `kubectl get clusters,vclusters -n k8s-tst`
2. View logs: `kubectl logs -n capi-vcluster-system -l control-plane=controller-manager`
3. See [Troubleshooting Guide](troubleshooting.md) for common issues

## Getting Help

- Review the [FAQ](faq.md) for common questions
- Check [Troubleshooting](troubleshooting.md) for known issues  
- Open an issue in the repository for bugs or feature requests
