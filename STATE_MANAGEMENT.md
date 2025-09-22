# Terraform State Management for IBM Cloud Shell

This guide helps you manage Terraform state files across IBM Cloud Shell sessions to ensure you can always destroy your infrastructure, even after session timeouts.

## Overview

IBM Cloud Shell sessions have limitations:
- **4-hour inactivity timeout**: Sessions automatically terminate after 4 hours of inactivity
- **24-hour maximum**: Absolute maximum session duration is 24 hours
- **Temporary file system**: All files are lost when the session ends

This document provides step-by-step instructions for backing up and restoring Terraform state files.

## Before Deploying: Set Up State Backup

### 1. Deploy Infrastructure with State Backup

After running `terraform apply`, immediately backup your state:

```bash
# Verify deployment completed successfully
terraform show

# Create a timestamped state backup
DATE=$(date +"%Y%m%d_%H%M%S")
cp terraform.tfstate "terraform-${DATE}.tfstate"

# Download state file to your local machine
# Method 1: Using file.io (temporary, 14-day retention)
curl -F "file=@terraform.tfstate" https://file.io | tee state-download-info.txt

# Method 2: Using IBM Cloud Object Storage (recommended for longer retention)
# First, ensure you have a COS bucket for backups
ibmcloud cos bucket-create --bucket terraform-state-backup --region us-south

# Upload state file to COS
ibmcloud cos object-put --bucket terraform-state-backup --key "roks-lab/terraform-$(date +%Y%m%d_%H%M%S).tfstate" --body terraform.tfstate

# Save the object key for later retrieval
echo "terraform-state-backup/roks-lab/terraform-$(date +%Y%m%d_%H%M%S).tfstate" > cos-state-key.txt
```

### 2. Export Critical Configuration

Save your Terraform variables and configuration:

```bash
# Backup your terraform.tfvars
cp terraform.tfvars "terraform-vars-${DATE}.tfvars"

# Export current workspace (if using workspaces)
echo "$(terraform workspace show)" > current-workspace.txt

# Create a recovery information file
cat > recovery-info.txt << EOF
# Terraform State Recovery Information
# Generated: $(date)
#
# Project: ROKS Lab Infrastructure
# Region: $(grep region terraform.tfvars | cut -d'"' -f2)
# Prefix: $(terraform output -raw vpc_name | cut -d'-' -f1)
#
# State File Locations:
# - COS Bucket: terraform-state-backup
# - COS Object Key: $(cat cos-state-key.txt)
#
# Next Steps:
# 1. Download this repository: git clone https://github.com/cloud-design-dev/terraform-roks-lab.git
# 2. Restore terraform.tfvars with your original values
# 3. Follow STATE_MANAGEMENT.md import instructions
EOF

# Upload recovery info to COS
ibmcloud cos object-put --bucket terraform-state-backup --key "roks-lab/recovery-info-$(date +%Y%m%d_%H%M%S).txt" --body recovery-info.txt
```

## State File Recovery and Import

### 1. Start New Cloud Shell Session

```bash
# Access IBM Cloud Shell
# Navigate to: https://cloud.ibm.com
# Click the terminal icon in the top navigation

# Verify authentication
ibmcloud target

# Clone the repository
git clone https://github.com/cloud-design-dev/terraform-roks-lab.git
cd terraform-roks-lab
```

### 2. Restore State File

Choose one of the following methods based on how you backed up your state:

#### Method A: From file.io

```bash
# Use the download link from your original session
# Replace with your actual download URL
wget -O terraform.tfstate "https://file.io/[your-download-id]"
```

#### Method B: From IBM Cloud Object Storage

```bash
# List available state backups
ibmcloud cos objects --bucket terraform-state-backup --prefix "roks-lab/"

# Download the most recent state file
# Replace the date/time with your actual backup
ibmcloud cos object-get --bucket terraform-state-backup --key "roks-lab/terraform-20241201_143022.tfstate" terraform.tfstate

# Download recovery information
ibmcloud cos object-get --bucket terraform-state-backup --key "roks-lab/recovery-info-20241201_143022.txt" recovery-info.txt

# Review recovery information
cat recovery-info.txt
```

### 3. Restore Configuration

```bash
# Recreate terraform.tfvars with your original values
# Use the same values from your original deployment
cat > terraform.tfvars << EOF
ibmcloud_api_key = "your-original-api-key"
existing_resource_group = "your-original-resource-group"
region = "us-south"
prefix = "your-original-prefix"
enable_bastion = false  # or true, depending on original config
EOF
```

### 4. Initialize and Verify State

```bash
# Initialize Terraform
terraform init

# Verify state file integrity
terraform plan

# Expected output: "No changes. Your infrastructure matches the configuration."
```

## Destroying Infrastructure After State Recovery

### 1. Verify Current Resources

```bash
# Check what resources exist in your state
terraform show

# List all outputs to verify infrastructure
terraform output

# Verify resources exist in IBM Cloud
ibmcloud resource service-instances
ibmcloud is vpcs
ibmcloud oc clusters
```

### 2. Plan and Execute Destruction

```bash
# Plan the destruction to see what will be removed
terraform plan -destroy

# Review the plan carefully - ensure it matches your deployed resources

# Execute the destruction
terraform destroy

# Type 'yes' when prompted
```

### 3. Verify Complete Cleanup

```bash
# Verify VPC resources are cleaned up
ibmcloud is vpcs

# Verify ROKS cluster is deleted
ibmcloud oc clusters

# Verify COS instances (may need manual cleanup)
ibmcloud resource service-instances --service-name cloud-object-storage

# Clean up any remaining COS instances if needed
ibmcloud resource service-instance-delete roks-lab-cos --force
```

## Troubleshooting Common Issues

### State File Corruption or Mismatch

```bash
# If state file doesn't match actual resources, refresh from real infrastructure
terraform refresh

# If resources exist but aren't in state, you may need to import them
# Example: Import a VPC that exists but isn't in state
terraform import ibm_is_vpc.lab r006-12345678-1234-1234-1234-123456789012
```

### Missing Resource Group or API Permissions

```bash
# Verify your API key has correct permissions
ibmcloud iam user-policies [your-user-email]

# Check resource group access
ibmcloud resource groups

# If using a different API key, update terraform.tfvars
```

### Partial Infrastructure Remaining

```bash
# List all resources in your resource group
ibmcloud resource service-instances --resource-group-name your-resource-group

# Manually clean up any remaining resources
ibmcloud is subnets
ibmcloud is vpcs
ibmcloud oc cluster rm --cluster roks-lab-cluster --force-delete-storage
```

### State File Version Mismatch

```bash
# If you get version mismatch errors, upgrade state file
terraform init -upgrade

# Or downgrade Terraform version to match state file
# Check the state file version:
grep -i "terraform_version" terraform.tfstate
```

## Best Practices for State Management

### 1. Automated State Backup

Add this to your deployment workflow:

```bash
#!/bin/bash
# deploy-with-backup.sh

# Deploy infrastructure
terraform apply

# Automatically backup state on successful deployment
if [ $? -eq 0 ]; then
    DATE=$(date +"%Y%m%d_%H%M%S")

    # Upload to COS with metadata
    ibmcloud cos object-put \
        --bucket terraform-state-backup \
        --key "roks-lab/terraform-${DATE}.tfstate" \
        --body terraform.tfstate \
        --metadata "project=roks-lab,date=${DATE},user=$(ibmcloud target --output json | jq -r '.user.display_name')"

    echo "State backed up to: roks-lab/terraform-${DATE}.tfstate"
else
    echo "Deployment failed - state not backed up"
fi
```

### 2. Remote State Backend (Advanced)

For production use, consider configuring remote state:

```hcl
# Add to providers.tf
terraform {
  backend "s3" {
    bucket                      = "terraform-state-backup"
    key                         = "roks-lab/terraform.tfstate"
    region                      = "us-south"
    endpoint                    = "s3.us-south.cloud-object-storage.appdomain.cloud"
    skip_credentials_validation = true
    skip_region_validation      = true
  }
}
```

### 3. State Locking

Use DynamoDB-compatible locking with IBM Cloud Databases:

```hcl
terraform {
  backend "s3" {
    # ... existing config ...
    dynamodb_table = "terraform-locks"
  }
}
```

## Emergency Recovery

If all state files are lost but resources still exist:

### 1. Resource Discovery

```bash
# List all your IBM Cloud resources
ibmcloud resource service-instances --output json > all-resources.json

# Find VPCs
ibmcloud is vpcs --output json > vpcs.json

# Find clusters
ibmcloud oc clusters --output json > clusters.json
```

### 2. Manual State Recreation

```bash
# Initialize new Terraform configuration
terraform init

# Import resources one by one (example for VPC)
VPC_ID=$(jq -r '.[] | select(.name | contains("roks-lab")) | .id' vpcs.json)
terraform import ibm_is_vpc.lab $VPC_ID

# Repeat for all resources...
```

This process is complex and time-consuming. **Always backup your state files!**

## Support and Resources

- **IBM Cloud Terraform Provider**: [Registry Documentation](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- **Terraform State Management**: [Official Documentation](https://www.terraform.io/docs/language/state/index.html)
- **IBM Cloud Shell**: [Documentation](https://cloud.ibm.com/docs/cloud-shell)

For issues specific to this ROKS lab setup, refer to the main [README.md](./README.md) troubleshooting section.