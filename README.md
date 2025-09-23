# IBM Cloud ROKS Lab Infrastructure

This repository provides Terraform configuration to deploy a complete IBM Cloud infrastructure stack for Red Hat OpenShift on IBM Cloud (ROKS) testing and demonstration. The infrastructure includes VPC networking, Cloud Object Storage, and a 2-zone ROKS cluster optimized for cost-effective learning environments.

## 🚀 Quick Deploy

Deploy directly to IBM Cloud using Schematics (recommended):

[![Deploy to IBM Cloud](https://cloud.ibm.com/devops/setup/deploy/button.png)](https://cloud.ibm.com/schematics/workspaces/create?repository=https://github.com/cloud-design-dev/terraform-roks-lab&terraform_version=terraform_v1.10)

**What you get:**
- Complete VPC infrastructure with 2-zone deployment
- ROKS cluster with configurable worker nodes
- Cloud Object Storage instance (or use existing)
- All resources properly tagged and organized

## Architecture Overview

The deployment creates:

- **VPC Infrastructure**: 2-zone VPC with custom CIDR blocks and public gateways
- **Networking**: Dedicated subnets per zone for ROKS cluster nodes
- **Cloud Object Storage**: COS instance for ROKS cluster backup and storage needs (create new or use existing)
- **ROKS Cluster**: 2-zone OpenShift cluster with configurable worker nodes for demonstration and testing

## Deployment Options

Choose your preferred deployment method:

### Option 1: Schematics Deployment (Recommended)

Deploy directly from the IBM Cloud console using the "Deploy to IBM Cloud" button above. This is the easiest way to get started with no local setup required.

#### Prerequisites for Schematics
- IBM Cloud account with sufficient permissions
- API key (see instructions below)

#### API Key Creation

**Method 1: IBM Cloud Portal**
1. Log into the [IBM Cloud Console](https://cloud.ibm.com)
2. Go to **Manage** → **Access (IAM)** → **API keys**
3. Click **Create an IBM Cloud API key**
4. Enter a name (e.g., "terraform-roks-lab")
5. Add a description (e.g., "API key for ROKS lab deployment")
6. Click **Create**
7. **Important**: Copy and save the API key immediately (you won't be able to see it again)

**Method 2: Cloud Shell**
1. Access IBM Cloud Shell by clicking the terminal icon in the IBM Cloud console
2. Run the following command:
   ```bash
   ibmcloud iam api-key-create terraform-roks-lab -d "API key for ROKS lab deployment" --file ~/apikey.json
   ```
3. Retrieve the key:
   ```bash
   jq -r '.apikey' ~/apikey.json
   ```

### Option 2: Local Development

For advanced users who want to customize the configuration locally:

#### Prerequisites
1. **[mise](https://mise.jdx.dev/)** - Development tool version manager
   - Installation: https://mise.jdx.dev/getting-started.html
   - Used to manage Terraform and other tool versions automatically

2. **[IBM Cloud CLI](https://cloud.ibm.com/docs/cli)** - IBM Cloud command line interface
   - Installation: https://cloud.ibm.com/docs/cli?topic=cli-getting-started
   - Required for authentication and resource management

#### Tool Version Management with mise

This project includes a `.mise.toml` configuration file that automatically manages tool versions including Terraform, kubectl, and jq. After installing `mise`, the required tools will be installed automatically when you enter the project directory and run `mise trust` and `mise install`.

## Getting Started

### Schematics Deployment (Recommended)

1. **Click the "Deploy to IBM Cloud" button** at the top of this README
2. **Configure the workspace:**
   - **Workspace name**: Enter a unique name (e.g., "roks-lab-workspace")
   - **Resource group**: Select your target resource group
   - **Location**: Choose your preferred region
3. **Set Terraform variables:**
   - `ibmcloud_api_key`: Your IBM Cloud API key (created above)
   - `existing_resource_group`: Name of your resource group
   - `region`: IBM Cloud region (e.g., "us-south")
   - `owner_tag`: Your ownership tag (format: "owner:your-initials")
   - `create_cos_instance`: true (or false if using existing COS)
   - `existing_cos_instance_id`: CRN of existing COS instance (if applicable)
4. **Apply the plan:**
   - Click **Generate plan** to validate the configuration
   - Review the resources to be created
   - Click **Apply plan** to deploy the infrastructure

**Expected deployment time**: 30-45 minutes for complete infrastructure

### Local Development Setup

For advanced users preferring local development:

#### 1. Clone Repository

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

After deployment completes (via Schematics or local), you can access your ROKS cluster using multiple methods.

### Access via IBM Cloud Console (All Users)

1. **Navigate to your cluster**:
   - Go to [IBM Cloud Console](https://cloud.ibm.com)
   - Navigate to **OpenShift** → **Clusters**
   - Select your cluster (name starts with your prefix)

2. **Access the OpenShift web console**:
   - Click **OpenShift web console** button
   - Log in using your IBM Cloud credentials

### Access via Command Line

#### Method 1: IBM Cloud CLI (Recommended for Schematics users)

```bash
# Install IBM Cloud CLI if not already installed
# https://cloud.ibm.com/docs/cli?topic=cli-getting-started

# Login (use --sso for federated users)
ibmcloud login --sso

# List your clusters to find the cluster name
ibmcloud oc clusters

# Or get cluster name from Schematics workspace
# 1. Go to IBM Cloud Console → Schematics → Workspaces
# 2. Select your workspace
# 3. View the "cluster_name" output value

# Configure kubectl/oc with your cluster
ibmcloud oc cluster config --cluster <your-cluster-name> --admin

# Verify access
oc get nodes
kubectl get namespaces
```

#### Method 2: Local Development with mise (Local deployment users)

For users who deployed locally and want to merge configurations:

```bash
# Configure kubectl/oc access (merges with existing kubeconfig)
mise run k8s:config

# Verify access (no KUBECONFIG environment variable needed)
kubectl get nodes
oc get namespaces

# Switch back to ROKS cluster anytime
mise run k8s:switch

# Alternative: Manual configuration using IBM Cloud CLI
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

### Schematics Deployment Outputs

Access outputs from your Schematics workspace:

1. Go to [IBM Cloud Console](https://cloud.ibm.com) → **Schematics** → **Workspaces**
2. Select your workspace
3. View the **Outputs** section

**Available outputs:**
- `vpc_id` - VPC ID for additional resources
- `subnet_ids` - Subnet IDs for ROKS cluster
- `cos_instance_crn` - COS instance CRN
- `cos_instance_id` - COS instance ID
- `cluster_id` - ROKS cluster ID
- `cluster_name` - ROKS cluster name
- `cluster_status` - ROKS cluster status

### Local Development Outputs

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

## Cost Management

**Estimated monthly costs (us-south region):**
- VPC infrastructure: ~$20-30/month
- ROKS cluster worker nodes: ~$100-250/month (depending on size/count)
- Cloud Object Storage: ~$5-10/month
- Public gateways: ~$15/month

**Cost optimization tips:**
1. Use `terraform destroy` when not actively using the lab
2. Scale down worker nodes during off-hours
3. Monitor COS storage usage
4. Delete unused OpenShift projects regularly
5. Use existing COS instances when possible

## Troubleshooting

### Schematics Deployment Issues

**Workspace creation fails:**
- Ensure you have proper permissions in your IBM Cloud account
- Verify the repository URL is correct
- Check that your API key has sufficient permissions

**Plan generation fails:**
- Verify all required variables are set correctly
- Check that the resource group exists
- Ensure the region supports ROKS clusters

**Apply fails:**
- Check the Schematics workspace logs for detailed error messages
- Verify your account has sufficient quotas for VPC and ROKS resources
- Ensure COS instance ID is correct if using existing COS

### Local Development Issues

**Terraform deployment fails:**
```bash
# Check IBM Cloud authentication
ibmcloud target

# Verify resource group exists
ibmcloud resource groups

# Check available zones
ibmcloud is zones $(terraform output -raw region)

# Validate Terraform configuration
terraform validate
```

**ROKS cluster issues:**
```bash
# Check cluster status
ibmcloud oc cluster get --cluster $(terraform output -raw cluster_name)

# View cluster events
ibmcloud oc cluster events --cluster $(terraform output -raw cluster_name)

# Check worker node status
ibmcloud oc workers --cluster $(terraform output -raw cluster_name)
```

**COS configuration issues:**
```bash
# List COS instances
ibmcloud resource service-instances --service-name cloud-object-storage

# Verify COS instance access
ibmcloud cos config list
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

### Schematics Cleanup

To destroy resources deployed via Schematics:

1. **Go to your Schematics workspace**:
   - [IBM Cloud Console](https://cloud.ibm.com) → **Schematics** → **Workspaces**
   - Select your workspace

2. **Destroy the resources**:
   - Click **Actions** → **Destroy resources**
   - Type "destroy" to confirm
   - Click **Destroy**

3. **Delete the workspace (optional)**:
   - After resources are destroyed, click **Actions** → **Delete workspace**
   - Confirm deletion

### Local Development Cleanup

For local Terraform deployments:

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

For issues with this infrastructure:
- Review the troubleshooting section above
- Check IBM Cloud status at [status.cloud.ibm.com](https://status.cloud.ibm.com)
- Consult [IBM Cloud ROKS documentation](https://cloud.ibm.com/docs/openshift)

For Terraform-specific issues:
- Run `terraform validate` to check configuration syntax
- Use `terraform plan` to preview changes before applying
- Check the [IBM Cloud Terraform provider documentation](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)