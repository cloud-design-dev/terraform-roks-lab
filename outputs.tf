# VPC Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = ibm_is_vpc.lab.id
}

output "vpc_name" {
  description = "Name of the created VPC"
  value       = ibm_is_vpc.lab.name
}

output "subnet_ids" {
  description = "List of subnet IDs for ROKS cluster deployment"
  value       = ibm_is_subnet.cluster[*].id
}

# Cloud Object Storage Outputs
output "cos_instance_crn" {
  description = "CRN of the Cloud Object Storage instance"
  value       = module.cos_module.cos_instance_crn
}

output "cos_instance_id" {
  description = "ID of the Cloud Object Storage instance"
  value       = module.cos_module.cos_instance_id
}

output "cos_instance_name" {
  description = "Name of the Cloud Object Storage instance"
  value       = module.cos_module.cos_instance_name
}

# ROKS Cluster Outputs
output "cluster_id" {
  description = "ID of the ROKS cluster"
  value       = ibm_container_vpc_cluster.cluster.id
}

output "cluster_name" {
  description = "Name of the ROKS cluster"
  value       = ibm_container_vpc_cluster.cluster.name
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = local_file.kubeconfig.filename
}

output "cluster_status" {
  description = "Status of the ROKS cluster"
  value       = ibm_container_vpc_cluster.cluster.state
}
