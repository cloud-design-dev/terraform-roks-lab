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