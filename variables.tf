variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "visibility" {
  description = "Visibility of the Azure DevOps project (public or private)"
  type        = string
  default     = "private"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment for the deployment (e.g., dev, prod)"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for ACR"
  type        = string
}

variable "acr_sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "acr_admin_enabled" {
  description = "Enable admin user for ACR"
  type        = bool
  default     = false
}

variable "devops_resource_group_name" {
  description = "Name of the resource group for DevOps resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
