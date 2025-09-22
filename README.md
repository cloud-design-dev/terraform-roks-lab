# IBM Cloud ROKS Lab Infrastructure

This repository provides Terraform configuration to deploy a complete IBM Cloud infrastructure stack for Red Hat OpenShift on IBM Cloud (ROKS) testing and demonstration. The infrastructure includes VPC networking, Cloud Object Storage, and a 2-node ROKS cluster optimized for cost-effective learning environments.

## Architecture Overview

The deployment creates:

- **VPC Infrastructure**: 2-zone VPC with custom CIDR blocks and public gateways
- **Networking**: Dedicated subnets per zone for ROKS cluster nodes
- **Bastion Host**: Optional single instance for accessing ROKS services via private IPs (configurable)
- **Cloud Object Storage**: COS instance for ROKS cluster backup and storage needs
- **ROKS Cluster**: 2-node OpenShift cluster (1 worker per zone) for demonstration and testing

## Prerequisites

- IBM Cloud account with sufficient permissions
- Access to IBM Cloud Shell (no local installation required)

## Getting Started with IBM Cloud Shell

### 1. Access IBM Cloud Shell

1. Log into the [IBM Cloud Console](https://cloud.ibm.com)
2. Click the terminal icon (Cloud Shell) in the top navigation bar
3. Wait for the Cloud Shell environment to initialize

### 2. Clone Repository

```bash
git clone https://github.com/cloud-design-dev/terraform-roks-lab.git
cd terraform-roks-lab
```

### 3. Set Up Authentication

IBM Cloud Shell is pre-authenticated, but the Terraform IBM Cloud provider requires setting an API key for infrastructure deployment.

```bash
ibmcloud iam api-key-create <initials>-terraform-roks-lab -d "API key for deploying ROKS lab resources" --file apikey.json 
```

Retrieve the API key from the output using the `jq` tool:

```bash
jq -r '.apikey' < apikey.json
```

### 4. Configure Terraform Variables

Create your configuration file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit the variables file:
```bash
nano terraform.tfvars
```

**Required variables:**
```hcl
# Your IBM Cloud API key
ibmcloud_api_key = "your-api-key-here"

# Existing resource group name
existing_resource_group = "your-resource-group"

# IBM Cloud region
region = "us-south"

# Optional: Custom prefix for resources. 
# Uncomment and set if desired, otherwise a random prefix will be used.
# prefix = "roks-lab"

# Optional: Enable bastion host (default: false)
enable_bastion = false
```

**To list resource groups:**

```bash
ibmcloud resource groups
```

## Configuration Options

### Bastion Host Configuration

The bastion host is **optional** and controlled by the `enable_bastion` variable:

- **Enable bastion** (`enable_bastion = true`): Creates bastion subnet, security group, SSH key management, and enables SSH access
- **Disable bastion** (`enable_bastion = false`): Skips bastion resources and SSH key creation, reduces costs, ROKS cluster access via IBM Cloud console only

**When to disable bastion:**
- Cost optimization (saves ~$25-40/month)
- Console-only access sufficient
- Using private service endpoints exclusively

**When to enable bastion:**
- Need SSH access to worker nodes
- Private network troubleshooting required
- Custom network testing scenarios

## State File Management for Cloud Shell

⚠️ **IMPORTANT**: IBM Cloud Shell sessions are temporary and have time limits. Always backup your Terraform state after provisioning completes!

### Quick State Backup

After successful deployment, immediately backup your state:

In the IBM Cloud Shell menu bar, click the Download icon ![Download Icon](./images/download.svg) and enter the path to the file in your home directory, such as `myFolder/myFile.txt`. Click Continue.

Alternatively, use the IBM Cloud CLI to back up state to the newly created Cloud Object Storage instance:

```bash
# Get COS instance CRN
export COS_CRN=$(ibmcloud resource service-instance <cos-instance-name> --output json | jq -r '.[].crn')

# Configure IBM Cloud COS plugin to use the instance
ibmcloud cos config crn --crn $COS_CRN --force

# Create new bucket for state backups (if not already created)
ibmcloud cos bucket-create --bucket <bucket-name> --region <your-region> --class smart

# Create timestamped backup
DATE=$(date +"%Y%m%d_%H%M%S")
ibmcloud cos object-put --bucket <bucket-name>  --key "roks-lab/terraform-${DATE}.tfstate" --body terraform.tfstate
```

### Complete State Management Guide

📖 **For detailed state management instructions, including recovery and import procedures, see [STATE_MANAGEMENT.md](./STATE_MANAGEMENT.md)**

This comprehensive guide covers:
- Step-by-step state backup procedures
- State file recovery after session timeout
- Infrastructure destruction with imported state
- Troubleshooting common state issues
- Emergency recovery procedures

## Deployment Instructions

### Phase 1: VPC Infrastructure Deployment

Initialize and deploy the base VPC infrastructure:

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy VPC infrastructure
terraform apply
```

**Expected deployment time**: 3-5 minutes

**Resources created:**
- VPC with 2 availability zones
- Public gateways for internet access
- Subnets for ROKS cluster nodes
- ROKS cluster with 2 worker nodes
- Cloud Object Storage instance

**Additional resources (if bastion enabled):**
- Bastion subnet with dedicated IP range
- Bastion security group with SSH access rules
- SSH key pair (generated if not provided)

### Phase 2: Cloud Object Storage Setup

Create a COS instance for ROKS cluster storage:

```bash
# Create COS instance
ibmcloud resource service-instance-create roks-lab-cos cloud-object-storage standard global

# Create service credentials
ibmcloud resource service-key-create roks-lab-cos-key Manager --instance-name roks-lab-cos

# Verify COS instance
ibmcloud resource service-instances --service-name cloud-object-storage
```

### Phase 3: ROKS Cluster Deployment

Deploy the 2-node OpenShift cluster:

```bash
# Get VPC ID from Terraform output
VPC_ID=$(terraform output -raw vpc_id)
SUBNET_IDS=$(terraform output -json subnet_ids | jq -r '.[]' | paste -sd "," -)

# Create ROKS cluster (this takes 30-45 minutes)
ibmcloud oc cluster create vpc-gen2 \
  --name roks-lab-cluster \
  --version 4.14_openshift \
  --zone us-south-1 \
  --zone us-south-2 \
  --flavor bx2.4x16 \
  --workers 1 \
  --vpc-id $VPC_ID \
  --subnet-id $SUBNET_IDS \
  --cos-instance roks-lab-cos \
  --disable-public-service-endpoint

# Monitor cluster creation
ibmcloud oc cluster get --cluster roks-lab-cluster
```

**Important Notes:**
- Cluster creation takes 30-45 minutes
- The cluster uses private service endpoint only for security
- Each zone gets 1 worker node (bx2.4x16 flavor)

### Phase 4: Access Configuration

Once the cluster is ready, configure access:

```bash
# Download cluster configuration
ibmcloud oc cluster config --cluster roks-lab-cluster --admin

# Verify cluster access
oc get nodes
oc get namespaces

# Access via bastion host (if bastion is enabled)
if [ "$(terraform output -raw bastion_subnet_id)" != "null" ]; then
  echo "Bastion host available for SSH access to private resources"
  SSH_KEY_PATH=$(terraform output -raw ssh_private_key_path)
  echo "SSH key path: $SSH_KEY_PATH"
else
  echo "No bastion host deployed - using console access only"
fi
```

## Using Your ROKS Cluster

### OpenShift Console Access

```bash
# Get console URL
ibmcloud oc cluster get --cluster roks-lab-cluster | grep "Master URL"

# Get admin password
ibmcloud oc cluster config --cluster roks-lab-cluster --admin --output json
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

### Resource Monitoring

```bash
# Check cluster resources
oc get nodes -o wide
oc describe nodes

# Monitor cluster capacity
oc top nodes
oc top pods --all-namespaces
```

## Cost Management

**Estimated monthly costs (us-south region):**
- VPC infrastructure: ~$20-30/month
- 2x bx2.4x16 worker nodes: ~$200-250/month
- Cloud Object Storage: ~$5-10/month
- Public gateways: ~$15/month
- Bastion host (if enabled): ~$25-40/month

**Cost optimization tips:**
1. Use `terraform destroy` when not actively using the lab
2. Set `enable_bastion = false` if SSH access not needed (saves ~$25-40/month)
3. Scale down worker nodes during off-hours
4. Monitor COS storage usage
5. Delete unused OpenShift projects regularly

## Troubleshooting

### Common Issues

**Terraform deployment fails:**
```bash
# Check IBM Cloud authentication
ibmcloud target

# Verify resource group exists
ibmcloud resource groups

# Check available zones
ibmcloud is zones us-south
```

**ROKS cluster creation fails:**
```bash
# Check cluster status
ibmcloud oc cluster get --cluster roks-lab-cluster

# View cluster events
ibmcloud oc cluster events --cluster roks-lab-cluster

# Check worker node status
ibmcloud oc workers --cluster roks-lab-cluster
```

**Cannot access OpenShift console:**
```bash
# Verify cluster is ready
oc get nodes

# Check if console route exists
oc get routes -n openshift-console

# Reset cluster config
ibmcloud oc cluster config --cluster roks-lab-cluster --admin
```

### Useful Diagnostic Commands

```bash
# Check all IBM Cloud resources
ibmcloud resource service-instances

# View VPC resources
ibmcloud is vpcs
ibmcloud is subnets

# Monitor cluster logs
ibmcloud logging config get --cluster roks-lab-cluster

# Check cluster add-ons
ibmcloud oc cluster addon ls --cluster roks-lab-cluster
```

## Cleanup

### Destroy ROKS Cluster
```bash
ibmcloud oc cluster rm --cluster roks-lab-cluster --force-delete-storage
```

### Destroy VPC Infrastructure
```bash
terraform destroy
```

### Remove COS Instance
```bash
ibmcloud resource service-instance-delete roks-lab-cos --force
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