#!/bin/bash

# Script to provision Azure resources for Terraform backend
# Based on https://github.com/theoneglobal/azure-devops-bootstrap

# Exit on error
set -e

# Default values
RESOURCE_GROUP="terraform-backend-rg"
LOCATION="eastus"
STORAGE_ACCOUNT="tfstate$(date +%s)"
CONTAINER="tfstate"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it first: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
    echo "Please log in to Azure using 'az login'"
    exit 1
fi

echo "Creating resource group: $RESOURCE_GROUP"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "Creating storage account: $STORAGE_ACCOUNT"
az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2

echo "Creating storage container: $CONTAINER"
az storage container create \
    --name "$CONTAINER" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login

echo "Retrieving storage account key"
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" \
    --query '[0].value' -o tsv)

echo ""
echo "Backend setup complete! Use the following values in backend.tf:"
echo "resource_group_name  = \"$RESOURCE_GROUP\""
echo "storage_account_name = \"$STORAGE_ACCOUNT\""
echo "container_name       = \"$CONTAINER\""
echo "key                  = \"terraform.tfstate\""
echo ""
echo "Export the storage account key for Terraform initialization:"
echo "export ARM_ACCESS_KEY=\"$STORAGE_KEY\""
