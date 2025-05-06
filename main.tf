# Defining local variables for naming and time formatting
locals {
  prefix      = "${var.project_name}-${var.environment}"
  safe_prefix = lower(replace(local.prefix, "-", ""))
  start_time  = "${formatdate("YYYY-MM-DD", timestamp())}T00:00:00Z"
  expiry_time = "${formatdate("YYYY-MM-DD", timestamp())}T23:59:59Z"
}

# Configuring the random string for unique naming
resource "random_string" "unique_suffix" {
  length  = 4
  upper   = false
  special = false
}

# Creating the Azure DevOps project
resource "azuredevops_project" "main" {
  name               = "${local.safe_prefix}-project"
  description        = "Project for ${var.prefix}"
  visibility         = var.visibility
  version_control    = "Git"
  work_item_template = "Agile"
}

# Setting up the Azure DevOps Git repository
resource "azuredevops_git_repository" "devops_repo" {
  project_id = azuredevops_project.main.id
  name       = "${local.prefix}-${var.prefix}-${random_string.unique_suffix.result}"
  initialization {
    init_type = "Clean"
  }
}

# Defining the Azure DevOps build pipeline
resource "azuredevops_build_definition" "devops_pipeline" {
  project_id = azuredevops_project.main.id
  name       = "${local.prefix}-devops-ci"

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.devops_repo.id
    branch_name = "main"
    yml_path    = "azure-pipelines.yml"
  }

  ci_trigger {
    use_yaml = true
  }
}

# Creating a variable group for CI variables
resource "azuredevops_variable_group" "ci_vars" {
  project_id   = azuredevops_project.main.id
  name         = "${local.prefix}-ci-vars"
  allow_access = true

  variable {
    name  = "AZURE_DEVOPS_ORG"
    value = azuredevops_project.main.name
  }

  variable {
    name  = "LOCATION"
    value = var.location
  }
}

# Setting up a user-assigned managed identity for the application
resource "azurerm_user_assigned_identity" "app_identity" {
  location            = var.location
  name                = "webapp-identity"
  resource_group_name = azurerm_resource_group.devops_rg.name
}

# Creating an Azure DevOps service connection for Azure Container Registry
resource "azuredevops_serviceendpoint_azurerm" "acr" {
  project_id                             = azuredevops_project.main.id
  service_endpoint_name                  = "Azure DevOps ACR Service Connection"
  description                            = "Managed by Terraform"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"

  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.app_identity.client_id
  }

  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name = "Auto-Detected Subscription"
}

# Configuring federated identity credentials for ACR
resource "azurerm_federated_identity_credential" "acr" {
  name                = "acr-federated-identity"
  resource_group_name = azurerm_resource_group.devops_rg.name
  parent_id           = azurerm_user_assigned_identity.app_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azuredevops_serviceendpoint_azurerm.acr.workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurerm.acr.workload_identity_federation_subject
}

# Assigning AcrPush role to the managed identity
resource "azurerm_role_assignment" "acr_pull_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}

# Assigning AcrPull role to the managed identity
resource "azurerm_role_assignment" "acr_pull_subscription" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}

# Creating the Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
}

# Creating the resource group for DevOps resources
resource "azurerm_resource_group" "devops_rg" {
  name     = var.devops_resource_group_name
  location = var.location
  tags     = var.tags
}
