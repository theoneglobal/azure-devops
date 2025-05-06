# Fetching Azure AD domain information
data "azuread_domains" "auth" {
  only_initial = true
}

# Fetching current Azure client configuration
data "azurerm_client_config" "current" {}
