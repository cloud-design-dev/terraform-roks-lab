variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key to use for authentication."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The IBM Cloud region to deploy resources in."
  type        = string
  default     = "us-south"
}

variable "existing_resource_group" {
  description = "The name of an existing IBM Cloud resource group to deploy resources in."
  type        = string
}


variable "vpc_address_prefix" {
  description = "The address prefix management option for the VPC."
  type        = string
  default     = "auto"
}

variable "owner_tag" {
  description = "The owner tag to apply to resources. This should be in the format 'owner:<name>'."
  type        = string
}

# Cloud Object Storage Configuration
variable "create_cos_instance" {
  description = "Whether to create a new IBM Cloud Object Storage instance. If false, an existing instance ID must be provided."
  type        = bool
}

variable "existing_cos_instance_id" {
  description = "The ID of an existing Cloud Object Storage instance to use. Required if create_cos_instance is false."
  type        = string
  default     = null
  validation {
    condition     = var.create_cos_instance == true || (var.create_cos_instance == false && var.existing_cos_instance_id != null)
    error_message = "When create_cos_instance is false, existing_cos_instance_id must be provided."
  }
}

variable "cos_instance_name" {
  description = "The name for the IBM Cloud Object Storage instance. Only used if create_cos_instance is true."
  type        = string
  default     = null
}
