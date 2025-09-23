# Local Development Guide

This guide covers local development setup for the IBM Cloud ROKS Lab Infrastructure. For the simpler Schematics deployment, see the main [README.md](README.md).

## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

### Required Tools

1. **[mise](https://mise.jdx.dev/)** - Development tool version manager
   - Installation: https://mise.jdx.dev/getting-started.html
   - Used to manage Terraform and other tool versions automatically

2. **[IBM Cloud CLI](https://cloud.ibm.com/docs/cli)** - IBM Cloud command line interface
   - Installation: https://cloud.ibm.com/docs/cli?topic=cli-getting-started
   - Required for authentication and resource management

### Tool Version Management with mise

This project includes a `.mise.toml` configuration file that automatically manages tool versions including Terraform, kubectl, and jq. After installing `mise`, the required tools will be installed automatically when you enter the project directory and run `mise trust` and `mise install`.

## Getting Started

### 1. Clone Repository

```bash
git clone https://github.com/cloud-design-dev/terraform-roks-lab.git
cd terraform-roks-lab
```

### 2. Install Tools with mise

```bash
# mise will automatically install Terraform based on .mise.toml
mise install
```

### 3. Authenticate with IBM Cloud

#### Using SSO (Recommended for users that don't have an API key saved locally)

```bash
# Login using Single Sign-On
ibmcloud login --sso

# Follow the prompts to complete authentication via browser
```

#### Using API Key (Alternative method)

If you have an existing API key:

```bash
# Login with API key
ibmcloud login --apikey <your-api-key>

# Or create a new API key
ibmcloud iam api-key-create terraform-roks-lab -d "API key for ROKS lab deployment"
```

### 4. Set Target Resource Group and Region

```bash
# List available resource groups
ibmcloud resource groups

# Target your resource group and region
ibmcloud target -g <your-resource-group> -r <your-region>
```

### 5. Configure Terraform Variables

Create your configuration file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit the variables file with your preferred editor:

```bash
# Edit with your preferred editor
nano terraform.tfvars
```

## Configuration Options

### Required Variables

```hcl
# Your IBM Cloud API key (get from: ibmcloud iam api-key-create <name>)
ibmcloud_api_key = "your-api-key-here"

# Existing resource group name
existing_resource_group = "your-resource-group"

# IBM Cloud region
region = "us-south"

# Tag to identify ownership
owner_tag = "owner:your-initials"
```

### Cloud Object Storage Configuration

You can either create a new COS instance or use an existing one:

#### Option 1: Create New COS Instance (Default)

```hcl
# Create a new COS instance (default behavior)
create_cos_instance = true

# Optional: Custom COS instance name (auto-generated if not specified)
cos_instance_name = "my-roks-cos"
```

#### Option 2: Use Existing COS Instance

```hcl
# Use an existing COS instance
create_cos_instance = false
existing_cos_instance_id = "crn:v1:bluemix:public:cloud-object-storage:global:a:account-id:instance-id::"
```

**Note**: ROKS automatically creates its own bucket for container registry storage, so no additional bucket creation is needed.

To find your existing COS instance ID:

```bash
# List COS instances
ibmcloud resource service-instances --service-name cloud-object-storage

# Get the CRN of your COS instance
ibmcloud resource service-instance <cos-instance-name> --output json | jq -r '.[].crn'
```

### Optional Configuration

```hcl
# VPC address prefix management
vpc_address_prefix = "auto"  # or "manual"
```

## Deployment Instructions

### Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

**Expected deployment time**:
- VPC Infrastructure: 3-5 minutes
- ROKS Cluster: 30-45 minutes (handled by Terraform)

**Resources created:**
- VPC with 2 availability zones
- Public gateways for internet access
- Subnets for ROKS cluster nodes
- Cloud Object Storage instance (or reference to existing)
- ROKS cluster with configurable worker nodes

## Using Your ROKS Cluster

### Access via Command Line with mise (Local Development)

For users who deployed locally and want to merge configurations:

```bash
# Configure kubectl/oc access (merges with existing kubeconfig)
mise run k8s:config

# Verify access (no KUBECONFIG environment variable needed)
kubectl get nodes
oc get namespaces

# Switch back to ROKS cluster anytime
mise run k8s:switch

# Alternative: Configure using IBM Cloud CLI
ibmcloud oc cluster config --cluster $(terraform output -raw cluster_name) --admin
```

**What the mise task does:**
- Creates `~/.kube` directory if it doesn't exist
- Backs up existing kubeconfig to `~/.kube/config.backup`
- Merges ROKS cluster config with any existing kubeconfig
- Automatically switches to the IAM-authenticated ROKS context
- Works with or without existing kubectl configurations

### Get Console URL and Credentials

```bash
# Get console URL
ibmcloud oc cluster get --cluster $(terraform output -raw cluster_name) | grep "Master URL"

# Get admin credentials
ibmcloud oc cluster config --cluster $(terraform output -raw cluster_name) --admin --output json
```

### Deploy Sample Application

```bash
# Create a new project
oc new-project sample-app

# Deploy a sample application
oc new-app --docker-image=nginx:latest --name=nginx-app

# Expose the service
oc expose service nginx-app

# Get route URL
oc get routes
```

## Infrastructure Outputs

For local Terraform deployments:

```bash
# View all outputs
terraform output

# Key outputs available:
terraform output vpc_id                    # VPC ID for additional resources
terraform output subnet_ids                # Subnet IDs for ROKS cluster
terraform output cos_instance_crn          # COS instance CRN
terraform output cos_instance_id           # COS instance ID
terraform output cluster_id                # ROKS cluster ID
terraform output cluster_name              # ROKS cluster name
terraform output kubeconfig_path           # Path to kubeconfig file
terraform output cluster_status            # ROKS cluster status
```

## Development Workflow

### Using mise for Tool Management

```bash
# Check tool versions
mise list

# Update tools to latest versions
mise upgrade

# Install additional tools as needed
mise install jq  # example
```

### Available mise Tasks

This project includes helpful mise tasks for common operations:

```bash
# Terraform operations
mise run tf:init              # Initialize Terraform
mise run tf:fmt               # Format Terraform files
mise run tf:val               # Validate Terraform files
mise run tf:check             # Format and validate (runs both)
mise run tf:plan              # Create execution plan
mise run tf:apply             # Apply plan
mise run tf:destroy           # Destroy infrastructure
mise run tf:reset             # Reset Terraform state

# Cluster operations
mise run k8s:config           # Configure kubectl for ROKS cluster (merges with existing kubeconfig)
mise run k8s:switch           # Switch to ROKS cluster context

# List all available tasks
mise tasks
```

### Terraform Best Practices

```bash
# Always format before committing
terraform fmt

# Validate configuration
terraform validate

# Plan before applying
terraform plan -out=tfplan

# Apply with plan file
terraform apply tfplan
```

## Cleanup

### Destroy Resources

```bash
# Destroy all Terraform-managed resources
terraform destroy

# Confirm when prompted
```

**Note**: This will destroy the ROKS cluster, VPC infrastructure, and COS instance (if created by Terraform). Existing COS instances referenced via `existing_cos_instance_id` will not be deleted.

## Advanced Configuration

### Using Terraform Workspaces

```bash
# Create separate environments
terraform workspace new development
terraform workspace new staging

# Switch between environments
terraform workspace select development

# List workspaces
terraform workspace list
```

### Custom Variable Files

```bash
# Use environment-specific variable files
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="prod.tfvars"
```

## Next Steps

After successful deployment, explore:

1. **OpenShift Development**: Deploy applications using S2I, BuildConfigs, and DeploymentConfigs
2. **Networking**: Configure ingress controllers, network policies, and service mesh
3. **Storage**: Test persistent volumes with IBM Cloud Block Storage
4. **Security**: Implement RBAC, security contexts, and Pod Security Standards
5. **Monitoring**: Set up logging and monitoring with IBM Cloud services

## Support

For issues with local development:
- Review the [DEBUG.md](DEBUG.md) troubleshooting guide
- Check IBM Cloud status at [status.cloud.ibm.com](https://status.cloud.ibm.com)
- Consult [IBM Cloud ROKS documentation](https://cloud.ibm.com/docs/openshift)

For Terraform-specific issues:
- Run `terraform validate` to check configuration syntax
- Use `terraform plan` to preview changes before applying
- Check the [IBM Cloud Terraform provider documentation](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)