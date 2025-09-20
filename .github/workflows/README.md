# GitHub Actions Workflows

This directory contains GitHub Actions workflows for testing, validating, and releasing the ITL.K8s.Capi Helm chart.

## 🔄 Workflows Overview

### 1. Test Chart (`test-chart.yml`)

**Triggers**: Push to main/develop branches, Pull requests to main, Manual dispatch

**Purpose**: Comprehensive testing of the Helm chart including lint validation, Kubernetes manifest validation, KIND cluster testing, and security scanning.

**Jobs**:
- **lint-and-validate**: Helm lint, template rendering, Kubernetes validation, YAML syntax check
- **test-with-kind**: KIND cluster setup, CAPI installation, chart deployment testing, upgrade testing
- **security-scan**: Checkov security analysis with SARIF upload
- **documentation-check**: Validates documentation completeness and checks for broken links
- **release-notes**: Generates release notes for main branch pushes

**Duration**: ~15-20 minutes

### 2. Package and Release Chart (`release-chart.yml`)

**Triggers**: Git tags (v*), Manual dispatch with version input

**Purpose**: Packages and releases the Helm chart to GitHub Releases and OCI registry.

**Jobs**:
- **package-and-release**: Updates chart version, packages chart, creates GitHub release, pushes to OCI registry
- **update-documentation**: Updates installation instructions with new version

**Artifacts**:
- Helm chart package (`.tgz`)
- Chart repository index (`index.yaml`)
- OCI registry package at `ghcr.io/ITlusions/helm-charts`

### 3. Dependency Updates (`dependency-updates.yml`)

**Triggers**: Weekly schedule (Mondays 9 AM UTC), Manual dispatch

**Purpose**: Monitors dependencies for updates and creates issues when updates are available.

**Checks**:
- vcluster Helm chart updates
- Cluster API core provider updates  
- vcluster infrastructure provider updates
- Security advisories

**Output**: Creates/updates GitHub issues with dependency update information

### 4. PR Chart Validation (`pr-validation.yml`)

**Triggers**: Pull requests affecting chart files

**Purpose**: Validates chart changes in pull requests before merging.

**Validations**:
- Chart version bump check
- Helm lint validation
- Template comparison with base branch
- Multi-environment testing (default, dev, prod values)
- Kubernetes resource validation
- Documentation consistency check

## 🛠️ Workflow Requirements

### Secrets

The workflows require the following secrets to be configured in the repository:

| Secret | Required For | Description |
|--------|--------------|-------------|
| `GITHUB_TOKEN` | All workflows | Automatically provided by GitHub |
| `SNYK_TOKEN` | dependency-updates.yml | Snyk security scanning (optional) |

### Permissions

The workflows require the following permissions:

```yaml
permissions:
  contents: write    # For creating releases and updating files
  packages: write    # For pushing to GitHub Container Registry
  security-events: write  # For uploading security scan results
  issues: write      # For creating dependency update issues
```

## 🎯 Usage Examples

### Manual Release

Create a new release by pushing a git tag:

```bash
git tag v1.2.3
git push origin v1.2.3
```

Or trigger manually via GitHub Actions UI with a specific version.

### Testing Changes

Push changes to a branch and create a PR to trigger validation:

```bash
git checkout -b feature/update-values
# Make changes to chart
git add .
git commit -m "feat: update chart configuration"
git push origin feature/update-values
# Create PR via GitHub UI
```

### Force Dependency Check

Trigger dependency check manually via GitHub Actions UI or wait for the weekly schedule.

## 📊 Workflow Status

### Badge Examples

Add these to your README.md to show workflow status:

```markdown
[![Test Chart](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/test-chart.yml/badge.svg)](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/test-chart.yml)

[![Release Chart](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/release-chart.yml/badge.svg)](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/release-chart.yml)

[![Dependency Updates](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/dependency-updates.yml/badge.svg)](https://github.com/ITlusions/ITL.K8s.CAPI/actions/workflows/dependency-updates.yml)
```

## 🔧 Customization

### Modifying Test Environments

Update the KIND cluster configuration in `test-chart.yml`:

```yaml
config: |
  kind: Cluster
  apiVersion: kind.x-k8s.io/v1alpha4
  nodes:
  - role: control-plane
    # Add custom configuration here
```

### Adding New Validation Steps

Add new steps to the `lint-and-validate` job in `test-chart.yml`:

```yaml
- name: Custom validation
  run: |
    echo "Running custom validation..."
    # Your validation commands here
```

### Customizing Release Notes

Modify the release body template in `release-chart.yml` to match your organization's standards.

## 🐛 Troubleshooting

### Common Issues

1. **Chart lint failures**: Check Helm template syntax and values schema
2. **KIND cluster failures**: Verify Kubernetes version compatibility
3. **OCI push failures**: Ensure GitHub token has package write permissions
4. **Security scan failures**: Review Checkov configuration and ignore false positives

### Debugging

Enable debug mode by adding to workflow:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

### Local Testing

Test workflows locally using [act](https://github.com/nektos/act):

```bash
# Install act
# Test the lint job
act -j lint-and-validate

# Test with specific event
act pull_request
```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Helm Chart Testing](https://helm.sh/docs/topics/chart_tests/)
- [KIND Documentation](https://kind.sigs.k8s.io/)
- [Cluster API Documentation](https://cluster-api.sigs.k8s.io/)
