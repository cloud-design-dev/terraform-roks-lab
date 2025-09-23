# Troubleshooting Guide

This guide covers common issues and solutions for the IBM Cloud ROKS Lab Infrastructure deployment, both for Schematics and local development.

## Schematics Deployment Issues

### Workspace Creation Problems

**Error: "Repository not found" or "Invalid repository URL"**
- Verify the repository URL is correct: `https://github.com/cloud-design-dev/terraform-roks-lab`
- Ensure the repository is public and accessible
- Check that you have proper permissions in your IBM Cloud account

**Error: "Invalid Terraform version"**
- Ensure you're using the correct Terraform version in the Schematics workspace
- The recommended version is `terraform_v1.10` or later

### Plan Generation Issues

**Error: "Resource group not found"**
```bash
# List available resource groups
ibmcloud resource groups

# Verify the resource group name matches exactly
```

**Error: "Invalid API key"**
- Regenerate your API key from IBM Cloud Console
- Ensure the API key has sufficient permissions
- Verify the API key is correctly set in the Schematics workspace variables

**Error: "Region does not support ROKS clusters"**
- Check [IBM Cloud regions](https://cloud.ibm.com/docs/openshift?topic=openshift-regions-and-zones) for ROKS availability
- Common supported regions: `us-south`, `us-east`, `eu-gb`, `eu-de`, `jp-tok`

**Error: "Invalid COS instance ID"**
```bash
# Get correct COS instance CRN
ibmcloud resource service-instances --service-name cloud-object-storage
ibmcloud resource service-instance <instance-name> --output json | jq -r '.[].crn'
```

### Apply/Deployment Failures

**Error: "Insufficient quota" or "Resource limit exceeded"**
- Check your account quotas in IBM Cloud Console
- Contact IBM Cloud support to increase quotas if needed
- Verify you have available IP addresses in your VPC

**Error: "COS instance creation failed"**
- Check if you've reached the limit for COS instances in your account
- Verify billing is set up correctly
- Try using an existing COS instance instead

**Error: "ROKS cluster creation timeout"**
- ROKS cluster creation can take 30-45 minutes
- Check the Schematics workspace logs for detailed progress
- If it fails after 60+ minutes, destroy and retry

**Error: "VPC creation failed"**
- Ensure you have VPC creation permissions
- Check if the region has available zones
- Verify no conflicting VPC configurations exist

### Schematics Workspace Issues

**Error: "Cannot access workspace"**
- Verify you have proper IAM permissions for Schematics
- Check that the workspace is in the correct resource group
- Ensure you're logged into the correct IBM Cloud account

**Workspace stuck in "Planning" state**
- Refresh the page and wait a few minutes
- Check the workspace logs for error messages
- If stuck for >10 minutes, cancel and retry

**Variables not saving**
- Ensure all required variables are provided
- Check for validation errors in variable values
- Use the correct format for complex variables (JSON for objects/arrays)

## Local Development Issues

### Terraform Setup Problems

**Error: "terraform: command not found"**
```bash
# Install terraform using mise
mise install terraform

# Or check if mise is properly configured
mise which terraform
```

**Error: "Provider initialization failed"**
```bash
# Reinitialize Terraform
terraform init -upgrade

# Clear cache if needed
rm -rf .terraform/
terraform init
```

### Authentication Issues

**Error: "Authentication failed" or "Invalid credentials"**
```bash
# Check IBM Cloud authentication
ibmcloud target

# Re-authenticate if needed
ibmcloud login --sso

# Verify API key if using one
ibmcloud iam api-key-get <key-name>
```

**Error: "Permission denied" during deployment**
```bash
# Check your IBM Cloud permissions
ibmcloud iam user-policies <your-email>

# Ensure you have proper roles:
# - Viewer on Resource Group
# - Editor on VPC Infrastructure Services
# - Editor on Kubernetes Service
# - Editor on Cloud Object Storage
```

### Resource Creation Failures

**Error: "Resource group does not exist"**
```bash
# List available resource groups
ibmcloud resource groups

# Verify the resource group name in terraform.tfvars
```

**Error: "Zone does not exist in region"**
```bash
# Check available zones
ibmcloud is zones <region>

# Common regions and their zones:
# us-south: us-south-1, us-south-2, us-south-3
# us-east: us-east-1, us-east-2, us-east-3
```

**Error: "COS instance name already exists"**
- Change the `cos_instance_name` variable to a unique name
- Or set it to `null` to auto-generate a unique name

### Cluster Access Issues

**Error: "kubectl: command not found"**
```bash
# Install kubectl using mise
mise install kubectl

# Or install manually
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Error: "The connection to the server was refused"**
```bash
# Check cluster status
ibmcloud oc cluster get --cluster <cluster-name>

# Reconfigure kubectl
ibmcloud oc cluster config --cluster <cluster-name> --admin

# Or use the mise task to switch contexts
mise run k8s:switch
```

**Error: "Please enter Username:" prompt**
- This indicates you're using a context without proper authentication
- Use the IAM-authenticated context:
```bash
mise run k8s:config  # This will find and use the correct context
```

### State File Issues

**Error: "State file is locked"**
```bash
# Check for terraform processes
ps aux | grep terraform

# If no processes, force unlock (use with caution)
terraform force-unlock <lock-id>
```

**Error: "State file corrupted"**
```bash
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Try to refresh state
terraform refresh

# If that fails, you may need to import resources manually
```

## Network and Connectivity Issues

### VPC Networking Problems

**Error: "No available IP addresses"**
- The default configuration uses /26 subnets (64 IPs each)
- If you need more IPs, modify the `total_ipv4_address_count` in `main.tf`
- Or use fewer zones to concentrate IP usage

**Error: "Public gateway creation failed"**
- Check if you've reached the public gateway limit (10 per zone)
- Verify the zone supports public gateways
- Try a different zone if needed

### ROKS Cluster Networking

**Error: "Cluster nodes not ready"**
```bash
# Check cluster status
ibmcloud oc cluster get --cluster <cluster-name>

# Check worker nodes
ibmcloud oc workers --cluster <cluster-name>

# Check for events
kubectl get events --all-namespaces
```

**Error: "Cannot pull images"**
- Verify the COS instance is properly configured
- Check if image registry is accessible
- Ensure worker nodes have internet access through public gateways

## Cost and Billing Issues

### Unexpected Charges

**High COS charges**
- Monitor COS storage usage in IBM Cloud Console
- Set up storage lifecycle policies to archive old data
- Delete unused buckets and objects

**High compute charges**
- Check if you have additional worker nodes beyond the configuration
- Verify cluster autoscaling settings
- Stop or delete clusters when not in use

**High networking charges**
- Public gateway charges are ~$45/month per gateway
- VPC egress charges may apply for large data transfers
- Monitor bandwidth usage in IBM Cloud Console

## Getting Help

### IBM Cloud Resources
- [IBM Cloud Status](https://status.cloud.ibm.com) - Check for service outages
- [IBM Cloud Support](https://cloud.ibm.com/support) - Open support cases
- [IBM Cloud ROKS Documentation](https://cloud.ibm.com/docs/openshift)

### Terraform Resources
- [IBM Cloud Terraform Provider Documentation](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [Terraform IBM Cloud Examples](https://github.com/IBM-Cloud/terraform-provider-ibm/tree/master/examples)

### Diagnostic Commands

**Comprehensive system check:**
```bash
# Check IBM Cloud CLI version and login status
ibmcloud version
ibmcloud target

# Check terraform version and validate config
terraform version
terraform validate

# Check available resources
ibmcloud resource service-instances
ibmcloud is vpcs
ibmcloud oc clusters

# Check quotas
ibmcloud sl vs get-upgrade-itemprices
```

**Cluster diagnostic commands:**
```bash
# Cluster information
kubectl cluster-info
kubectl get nodes -o wide
kubectl get namespaces

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check for issues
kubectl get events --sort-by='.lastTimestamp' --all-namespaces
kubectl describe nodes
```

### Log Collection

**Schematics logs:**
1. Go to IBM Cloud Console → Schematics → Workspaces
2. Select your workspace
3. Click on the job ID to view detailed logs
4. Copy relevant error messages for support cases

**Local terraform logs:**
```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run terraform command
terraform apply

# Review the log file
tail -f terraform.log
```

**Cluster logs:**
```bash
# Get cluster logs
ibmcloud oc cluster get --cluster <cluster-name> --output json

# Worker node logs
ibmcloud oc workers --cluster <cluster-name> --output json

# Kubernetes events
kubectl get events --sort-by='.lastTimestamp' --all-namespaces > cluster-events.log
```

## Common Resolution Steps

1. **Always start with the basics:**
   - Verify authentication and permissions
   - Check resource quotas and limits
   - Ensure proper variable configuration

2. **For Schematics issues:**
   - Check workspace logs thoroughly
   - Verify all variables are set correctly
   - Try destroying and recreating if configuration is correct

3. **For local development:**
   - Update tools to latest versions
   - Clear terraform cache and reinitialize
   - Check for conflicting local configurations

4. **For cluster access:**
   - Use IBM Cloud Console as a fallback
   - Reconfigure kubectl/oc from scratch
   - Verify cluster is in "normal" state before troubleshooting access

Remember: Most issues are related to authentication, permissions, or configuration errors. Double-check these first before escalating to IBM Cloud support.