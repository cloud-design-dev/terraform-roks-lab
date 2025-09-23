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

The deployment creates a complete IBM Cloud infrastructure stack optimized for ROKS cluster deployment:

**Key Components:**
- **VPC Infrastructure**: 2-zone VPC with custom CIDR blocks and public gateways
- **Networking**: Dedicated subnets per zone (64 IPs each) for ROKS cluster nodes
- **Security**: Security group with SSH, ICMP, and Kubernetes API access rules
- **Compute**: ROKS worker nodes (bx2.4x16 flavor) distributed across zones
- **Storage**: Cloud Object Storage instance for container registry and backups
- **Management**: IBM-managed ROKS control plane with high availability

## Prerequisites

- **IBM Cloud account** with sufficient permissions
- **API key** (instructions below)

### API Key Creation

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

## Alternative Deployment Methods

- **🛠️ Local Development**: For advanced users who want to customize the configuration locally, see [LOCAL.md](LOCAL.md)
- **🔍 Troubleshooting**: For common issues and solutions, see [DEBUG.md](DEBUG.md)

## Deployment Instructions

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

**Resources created:**
- VPC with 2 availability zones
- Public gateways for internet access
- Subnets for ROKS cluster nodes
- Cloud Object Storage instance (or reference to existing)
- ROKS cluster with configurable worker nodes

### Configuration Options

#### Cloud Object Storage
- **Create new COS instance** (default): Set `create_cos_instance = true`
- **Use existing COS instance**: Set `create_cos_instance = false` and provide `existing_cos_instance_id`

To find your existing COS instance ID:
```bash
# List COS instances
ibmcloud resource service-instances --service-name cloud-object-storage

# Get the CRN of your COS instance
ibmcloud resource service-instance <cos-instance-name> --output json | jq -r '.[].crn'
```

After deployment completes, you can access your ROKS cluster using multiple methods.

### Access via IBM Cloud Console (All Users)

1. **Navigate to your cluster**:
   - Go to [IBM Cloud Console](https://cloud.ibm.com)
   - Navigate to **OpenShift** → **Clusters**
   - Select your cluster (name starts with your prefix)

2. **Access the OpenShift web console**:
   - Click **OpenShift web console** button
   - Log in using your IBM Cloud credentials

### Access via Command Line

#### Method 1: IBM Cloud CLI (Recommended)

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

### Get Console URL and Credentials

```bash
# Get console URL
ibmcloud oc cluster get --cluster <your-cluster-name> | grep "Master URL"

# Get admin credentials
ibmcloud oc cluster config --cluster <your-cluster-name> --admin --output json
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

## Troubleshooting

For common issues and detailed troubleshooting guidance, see **[DEBUG.md](DEBUG.md)**.

**Quick diagnostics:**
- Check IBM Cloud status at [status.cloud.ibm.com](https://status.cloud.ibm.com)
- Verify Schematics workspace logs for deployment issues
- Ensure all required variables are set correctly
- Confirm your account has sufficient quotas and permissions

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

**Note**: This will destroy the ROKS cluster, VPC infrastructure, and COS instance (if created by Terraform). Existing COS instances referenced via `existing_cos_instance_id` will not be deleted.

## Advanced Configuration

For advanced configuration options including local development, Terraform workspaces, and custom variable files, see **[LOCAL.md](LOCAL.md)**.


## Next Steps

After successful deployment, explore:

1. **OpenShift Development**: Deploy applications using S2I, BuildConfigs, and DeploymentConfigs
2. **Networking**: Configure ingress controllers, network policies, and service mesh
3. **Storage**: Test persistent volumes with IBM Cloud Block Storage
4. **Security**: Implement RBAC, security contexts, and Pod Security Standards
5. **Monitoring**: Set up logging and monitoring with IBM Cloud services

## Support

For issues with this infrastructure:
- Review the **[DEBUG.md](DEBUG.md)** troubleshooting guide
- Check IBM Cloud status at [status.cloud.ibm.com](https://status.cloud.ibm.com)
- Consult [IBM Cloud ROKS documentation](https://cloud.ibm.com/docs/openshift)
- For local development issues, see **[LOCAL.md](LOCAL.md)**