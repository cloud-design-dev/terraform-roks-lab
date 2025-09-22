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

output "cos_instance_crn" {
  description = "CRN of the Cloud Object Storage instance"
  value       = module.cos_module.cos_instance_crn
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.resource_group_id
}

output "cluster_id" {
  description = "ID of the ROKS cluster"
  value       = ibm_container_vpc_cluster.cluster.id
}

output "cluster_name" {
  description = "Name of the ROKS cluster"
  value       = ibm_container_vpc_cluster.cluster.name
}

# output "kube_config" {
#   description = "Kube config for the ROKS cluster"
#   value       = ibm_container_vpc_cluster.cluster.kube_config.0.raw
#   sensitive   = true
# }