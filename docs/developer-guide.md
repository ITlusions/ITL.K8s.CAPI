# Developer Guide

This guide provides information for developers who want to contribute to or modify the ITL K8s CAPI Helm chart.

## Table of Contents

- [Development Environment Setup](#development-environment-setup)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Contributing](#contributing)
- [Release Process](#release-process)

## Development Environment Setup

### Prerequisites

- **Kubernetes Cluster**: Minikube, kind, or full cluster
- **Tools**: kubectl, helm, git
- **Languages**: YAML, Go (for template functions)
- **IDE**: VS Code with Kubernetes and Helm extensions (recommended)

### Local Development Setup

1. **Clone the repository**:
```bash
git clone <repository-url>
cd ITL.K8s.Capi
```

2. **Install dependencies**:
```bash
# Install Helm dependencies (if any)
helm dependency update

# Install development tools
# Install helm-docs for documentation generation
GO111MODULE=on go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest

# Install yamllint for YAML validation
pip install yamllint
```

3. **Set up your development cluster**:
```bash
# Using minikube
minikube start --driver=docker --cpus=4 --memory=8192

# Using kind
kind create cluster --config=dev/kind-config.yaml
```

4. **Install Cluster API**:
```bash
# For development, use the quick setup
helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm repo update

helm install cluster-api-operator capi-operator/cluster-api-operator \
  --create-namespace \
  --namespace capi-operator-system \
  --wait
```

## Project Structure

```
ITL.K8s.Capi/
├── Chart.yaml                 # Helm chart metadata
├── values.yaml               # Default values
├── values-development.yaml   # Development environment values
├── values-production.yaml    # Production environment values
├── README.md                 # Main documentation
├── .helmignore              # Files to ignore during packaging
├── templates/               # Helm templates
│   ├── _helpers.tpl        # Template helper functions
│   ├── vcluster.yaml       # Main vcluster resource
│   ├── service.yaml        # Service resources
│   ├── ingress.yaml        # Ingress resources
│   ├── servicemonitor.yaml # Monitoring resources
│   └── capi-providers.yaml # CAPI provider resources
├── docs/                   # Documentation
│   ├── README.md          # Documentation index
│   ├── user-guide.md      # User documentation
│   ├── developer-guide.md # This file
│   └── ...                # Additional docs
└── tests/                 # Test files
    ├── unit/             # Unit tests
    └── integration/      # Integration tests
```

### Template Structure

#### `templates/_helpers.tpl`

Contains reusable template functions:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "itl-k8s-capi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "itl-k8s-capi.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}
```

#### `templates/vcluster.yaml`

Main template for vcluster resources:

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: {{ include "itl-k8s-capi.vclusterName" . }}
  namespace: {{ include "itl-k8s-capi.vclusterNamespace" . }}
  labels:
    {{- include "itl-k8s-capi.labels" . | nindent 4 }}
spec:
  # Cluster specification
```

## Development Workflow

### 1. Making Changes

1. **Create a feature branch**:
```bash
git checkout -b feature/your-feature-name
```

2. **Make your changes**:
   - Modify templates in `templates/`
   - Update values in `values*.yaml`
   - Add/update documentation
   - Add tests

3. **Test your changes**:
```bash
# Lint the chart
helm lint .

# Test template rendering
helm template test-release . --values values-development.yaml

# Dry run installation
helm install test-release . --dry-run --values values-development.yaml
```

### 2. Template Development

#### Best Practices

1. **Use helper functions**: Create reusable template functions in `_helpers.tpl`
2. **Validate inputs**: Use `required` function for mandatory values
3. **Provide defaults**: Always provide sensible defaults
4. **Use proper indentation**: Use `nindent` for consistent indentation
5. **Comment complex logic**: Add comments for complex template logic

#### Template Functions Examples

```yaml
{{/*
Generate vcluster name
*/}}
{{- define "itl-k8s-capi.vclusterName" -}}
{{- .Values.vcluster.name | default (printf "%s-cluster" .Release.Name) }}
{{- end }}

{{/*
Generate common labels
*/}}
{{- define "itl-k8s-capi.labels" -}}
helm.sh/chart: {{ include "itl-k8s-capi.chart" . }}
{{ include "itl-k8s-capi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}
```

#### Conditional Logic

```yaml
{{- if .Values.externalAccess.enabled }}
{{- if eq .Values.externalAccess.type "Ingress" }}
# Ingress configuration
{{- else if eq .Values.externalAccess.type "LoadBalancer" }}
# LoadBalancer configuration
{{- end }}
{{- end }}
```

### 3. Values File Development

#### Structure Guidelines

```yaml
# Global settings
global:
  environment: production
  labels: {}
  annotations: {}

# Main component configuration
vcluster:
  name: workload-cluster
  namespace: vcluster-system
  
# Feature toggles
externalAccess:
  enabled: false
  type: LoadBalancer

# Complex nested structures
highAvailability:
  enabled: false
  replicas: 3
  affinity:
    podAntiAffinity: {}
```

#### Validation

Add validation to templates:

```yaml
{{- if and .Values.externalAccess.enabled (eq .Values.externalAccess.type "Ingress") }}
{{- if not .Values.externalAccess.ingress.host }}
{{- fail "externalAccess.ingress.host is required when using Ingress" }}
{{- end }}
{{- end }}
```

## Testing

### 1. Unit Testing

#### Template Testing

Create tests in `tests/unit/`:

```bash
# Test basic template rendering
helm unittest .

# Test with specific values
helm unittest . -f tests/unit/values-test.yaml
```

#### Example Unit Test

```yaml
# tests/unit/vcluster_test.yaml
suite: test vcluster template
templates:
  - vcluster.yaml
tests:
  - it: should create cluster with default values
    asserts:
      - isKind:
          of: Cluster
      - equal:
          path: metadata.name
          value: workload-cluster
      - equal:
          path: spec.infrastructureRef.kind
          value: VCluster

  - it: should set custom cluster name
    set:
      vcluster.name: custom-cluster
    asserts:
      - equal:
          path: metadata.name
          value: custom-cluster
```

### 2. Integration Testing

#### Local Testing

```bash
# Create test namespace
kubectl create namespace test-vcluster

# Install chart
helm install test-release . \
  --namespace test-vcluster \
  --values values-development.yaml \
  --wait

# Verify installation
kubectl get clusters,vclusters -n test-vcluster

# Test functionality
# ... (add specific functionality tests)

# Cleanup
helm uninstall test-release -n test-vcluster
kubectl delete namespace test-vcluster
```

#### Automated Testing

Create integration test scripts:

```bash
#!/bin/bash
# tests/integration/basic-install.sh

set -e

NAMESPACE="test-$(date +%s)"
RELEASE_NAME="test-release"

echo "Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE"

echo "Installing chart..."
helm install "$RELEASE_NAME" . \
  --namespace "$NAMESPACE" \
  --values values-development.yaml \
  --wait --timeout=600s

echo "Verifying installation..."
kubectl get clusters,vclusters -n "$NAMESPACE"

# Wait for cluster to be ready
kubectl wait --for=condition=Ready cluster/workload-cluster \
  -n "$NAMESPACE" --timeout=600s

echo "Testing vcluster access..."
kubectl get secret workload-cluster-kubeconfig -n "$NAMESPACE" \
  -o jsonpath='{.data.kubeconfig}' | base64 -d > test-kubeconfig

export KUBECONFIG=test-kubeconfig
kubectl get nodes

echo "Cleaning up..."
unset KUBECONFIG
rm -f test-kubeconfig
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
kubectl delete namespace "$NAMESPACE"

echo "Test completed successfully!"
```

### 3. Linting and Validation

```bash
# Helm lint
helm lint .

# YAML lint
yamllint -c .yamllint.yaml .

# Template validation
helm template test . --validate

# Kubernetes validation (requires cluster)
helm template test . | kubectl apply --dry-run=client -f -
```

## Contributing

### 1. Code Standards

#### YAML Style

- Use 2 spaces for indentation
- Use double quotes for strings
- Keep lines under 120 characters
- Use meaningful comments

#### Template Standards

- Use meaningful template function names
- Add comments for complex logic
- Validate required inputs
- Provide sensible defaults
- Use consistent naming conventions

### 2. Documentation

#### Required Documentation

- Update `README.md` for user-facing changes
- Update configuration reference for new options
- Add examples for new features
- Update changelog

#### Documentation Generation

```bash
# Generate documentation from comments
helm-docs

# Validate documentation
markdownlint docs/
```

### 3. Commit Guidelines

Follow conventional commit format:

```
feat: add external access via ingress
fix: correct template indentation in vcluster.yaml
docs: update configuration reference
test: add unit tests for helper functions
```

### 4. Pull Request Process

1. **Create feature branch** from main
2. **Make changes** following standards
3. **Add tests** for new functionality
4. **Update documentation**
5. **Test thoroughly** in local environment
6. **Submit pull request** with:
   - Clear description of changes
   - Testing performed
   - Documentation updates
   - Breaking changes (if any)

## Release Process

### 1. Version Management

Follow semantic versioning:

- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, backward compatible
- **Patch** (0.0.X): Bug fixes, backward compatible

### 2. Release Checklist

1. **Update version** in `Chart.yaml`
2. **Update changelog** with release notes
3. **Test release candidate** in staging environment
4. **Create release tag**
5. **Publish chart** to repository
6. **Update documentation**

### 3. Release Script

```bash
#!/bin/bash
# scripts/release.sh

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

echo "Preparing release $VERSION"

# Update Chart.yaml
sed -i "s/version: .*/version: $VERSION/" Chart.yaml

# Run tests
helm lint .
helm unittest .

# Package chart
helm package .

echo "Release $VERSION ready for publication"
```

## Advanced Topics

### 1. Custom Resources

Adding support for new Kubernetes resources:

```yaml
# templates/custom-resource.yaml
{{- if .Values.customResource.enabled }}
apiVersion: example.com/v1
kind: CustomResource
metadata:
  name: {{ include "itl-k8s-capi.fullname" . }}-custom
  namespace: {{ .Release.Namespace }}
spec:
  # Custom resource specification
{{- end }}
```

### 2. Hooks

Using Helm hooks for lifecycle management:

```yaml
# templates/pre-install-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "itl-k8s-capi.fullname" . }}-pre-install"
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  # Job specification
```

### 3. Subchart Integration

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: 11.6.12
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

## Debugging

### Common Issues

1. **Template rendering errors**: Use `helm template` to debug
2. **Validation failures**: Check YAML syntax and Kubernetes API versions
3. **Resource conflicts**: Ensure unique resource names
4. **Permission issues**: Verify RBAC configuration

### Debugging Commands

```bash
# Debug template rendering
helm template debug-release . --debug

# Show computed values
helm get values release-name

# Check release status
helm status release-name

# View release history
helm history release-name
```

## Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Cluster API Documentation](https://cluster-api.sigs.k8s.io/)
- [vcluster Documentation](https://www.vcluster.com/docs/)
- [Go Template Documentation](https://pkg.go.dev/text/template)
