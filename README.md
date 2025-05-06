# Azure DevOps Terraform Repository

[![Terraform Lint](https://github.com/theoneglobal/azure-devops/actions/workflows/terraform.yml/badge.svg)](https://github.com/theoneglobal/azure-devops/actions/workflows/terraform.yml)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-brightgreen?logo=dependabot)](https://github.com/theoneglobal/azure-devops/security/dependabot)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/theoneglobal/azure-devops/blob/main/LICENSE)
[![Issues](https://img.shields.io/github/issues/theoneglobal/azure-devops)](https://github.com/theoneglobal/azure-devops/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/theoneglobal/azure-devops)](https://github.com/theoneglobal/azure-devops/pulls)
[![Stars](https://img.shields.io/github/stars/theoneglobal/azure-devops)](https://github.com/theoneglobal/azure-devops)
[![Forks](https://img.shields.io/github/forks/theoneglobal/azure-devops)](https://github.com/theoneglobal/azure-devops)
[![Last Commit](https://img.shields.io/github/last-commit/theoneglobal/azure-devops)](https://github.com/theoneglobal/azure-devops/commits/main)

This repository ([theoneglobal/azure-devops](https://github.com/theoneglobal/azure-devops)) contains Terraform configurations to set up an Azure DevOps project, including a Git repository, CI pipeline, variable group, and integration with Azure Container Registry (ACR) using a managed identity for secure authentication. It is designed to work with the [theoneglobal/azure-devops-django](https://github.com/theoneglobal/azure-devops-django) repository, which provides the Docker-based Django application code to be built and pushed to the ACR. The repository also includes an optional Azure backend for state storage, a GitHub Actions workflow for linting Terraform code, and Dependabot for managing Terraform dependencies.

## Features

- Creates an Azure DevOps project with Git version control and Agile work item template.
- Sets up a Git repository initialized as a clean repository.
- Configures a CI pipeline using an `azure-pipelines.yml` file to validate Terraform and build/push Docker images.
- Defines a variable group for CI variables.
- Provisions an Azure Container Registry (ACR) and a resource group.
- Establishes a user-assigned managed identity with federated credentials for secure ACR access.
- Assigns `AcrPush` and `AcrPull` roles to the managed identity.
- Optional Azure backend for persistent Terraform state storage.
- GitHub Actions workflow for linting Terraform code.
- Dependabot for managing Terraform dependencies.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed (version >= 1.5.0).
- An Azure subscription with permissions to create resource groups, ACR, storage accounts, and managed identities.
- An Azure DevOps organization with permissions to create projects, repositories, pipelines, and service connections.
- Azure CLI or Azure PowerShell for authentication and backend setup.
- Azure AD tenant for federated identity credentials.
- A GitHub repository with Actions and Dependabot enabled (for linting and dependency management).
- Docker installed locally (for testing the Docker build).
- Access to the [theoneglobal/azure-devops-django](https://github.com/theoneglobal/azure-devops-django) repository for the application code.

## Setup

1. **Clone the Repositories**

   Clone both this repository and the Django application repository:

   ```bash
   git clone https://github.com/theoneglobal/azure-devops.git
   git clone https://github.com/theoneglobal/azure-devops-django.git
   cd azure-devops
   ```

2. **(Optional) Set Up Terraform Backend**

   To store Terraform state in Azure for collaborative or persistent state management, provision a storage account and container:

   ```bash
   chmod +x scripts/setup-backend.sh
   ./scripts/setup-backend.sh
   ```

   The script creates a resource group, storage account, and container, outputting the values needed for the backend configuration. Choose one of the following approaches:

   - **Using `backend.tf`**:
     Copy `backend.tf.example` to `backend.tf`, update it with the output values (e.g., `resource_group_name`, `storage_account_name`, `container_name`), and uncomment the backend block:
     ```bash
     cp backend.tf.example backend.tf
     ```

   - **Using `backend.hcl`**:
     Copy `backend.hcl.example` to `backend.hcl` and update it with the output values:
     ```bash
     cp backend.hcl.example backend.hcl
     ```

   Set the `ARM_ACCESS_KEY` environment variable with the storage account key provided by the script:

   ```bash
   export ARM_ACCESS_KEY=<storage-account-key>
   ```

3. **Configure Terraform Variables**

   Copy `terraform.tfvars.example` to `terraform.tfvars` and update the values to match your environment:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Example `terraform.tfvars`:

   ```hcl
   prefix                      = "myproject"
   visibility                  = "public"
   location                    = "eastus"
   project_name                = "myapp"
   environment                 = "dev"
   acr_name                    = "myacr123"
   resource_group_name         = "my-rg"
   acr_sku                     = "Basic"
   acr_admin_enabled           = false
   devops_resource_group_name  = "devops-rg"
   tags = {
     Environment = "Development"
     Project     = "MyApp"
   }
   ```

   Refer to `variables.tf` for all available variables, their descriptions, and default values.

4. **Create an Azure Service Principal**

   To authenticate the Azure DevOps pipeline with Azure, create a service principal using the Azure CLI:

   ```bash
   az ad sp create-for-rbac --name "myproject-sp" --role contributor --scopes /subscriptions/<subscription-id>
   ```

   Note the output values (`appId`, `password`, `tenant`). These will be used as pipeline variables:

   - `ARM_CLIENT_ID`: The `appId` of the service principal.
   - `ARM_CLIENT_SECRET`: The `password` of the service principal (mark as secret).
   - `ARM_TENANT_ID`: The `tenant` ID.
   - `ARM_SUBSCRIPTION_ID`: Your Azure subscription ID.

5. **Authenticate with Azure and Azure DevOps**

   - **Azure**: Authenticate using the Azure CLI to manage Azure resources:
     ```bash
     az login
     ```
   - **Azure DevOps**: Create a Personal Access Token (PAT) in Azure DevOps with permissions for project, repository, pipeline, and service connection management. Set the PAT as an environment variable:
     ```bash
     export AZDO_PERSONAL_ACCESS_TOKEN=<your-pat>
     ```

6. **Initialize Terraform**

   If using the Azure backend, ensure either `backend.tf` or `backend.hcl` is configured and `ARM_ACCESS_KEY` is set. Initialize with:

   - For `backend.tf`:
     ```bash
     terraform init
     ```
   - For `backend.hcl`:
     ```bash
     terraform init -backend-config=backend.hcl
     ```

7. **Plan and Apply**

   Review the planned changes:

   ```bash
   terraform plan
   ```

   Apply the configuration to provision the Azure DevOps and Azure resources:

   ```bash
   terraform apply
   ```

8. **Set Up GitHub Actions and Dependabot**

   To enable the GitHub Actions linting workflow and Dependabot in the [theoneglobal/azure-devops](https://github.com/theoneglobal/azure-devops) repository:

   - **GitHub Actions**:
     - Ensure GitHub Actions is enabled in the repository settings (Actions > General > Allow all actions and reusable workflows).
     - The `.github/workflows/terraform.yml` workflow will automatically run on push or pull requests to the `main` branch, linting the Terraform code.
     - No secrets or authentication are required, as the workflow only performs local linting (formatting and validation).
     - The workflow status is displayed via the `Terraform Lint` badge at the top of this README.

   - **Dependabot**:
     - Enable Dependabot in the repository settings (Security > Code security and analysis > Enable Dependabot version updates).
     - The `.github/dependabot.yml` configuration will check for Terraform provider and module updates daily, creating pull requests for updates.
     - The Dependabot badge at the top of this README indicates that dependency updates are enabled.

## Integration with [theoneglobal/azure-devops-django]

This repository provisions the infrastructure and CI/CD pipeline for a Docker-based Django application hosted in the [theoneglobal/azure-devops-django](https://github.com/theoneglobal/azure-devops-django) repository. The Azure DevOps pipeline (`azure-pipelines.yml`) is configured to:

- Validate Terraform configurations for the Azure DevOps and ACR resources.
- Clone the [theoneglobal/azure-devops-django](https://github.com/theoneglobal/azure-devops-django) repository to access the Django application code and `Dockerfile`.
- Build and push the Docker image to the ACR provisioned by Terraform, using the managed identity for authentication.

To use the Django application with this setup:

1. Ensure both repositories are cloned as described in the Setup section.
2. Configure the Azure DevOps pipeline to access the [theoneglobal/azure-devops-django](https://github.com/theoneglobal/azure-devops-django) repository by setting the `DJANGO_REPO_URL` variable (see CI Pipeline section).
3. Verify that the ACR name and managed identity outputs from Terraform are correctly used in the pipeline variables.

## Testing

To validate the setup locally and in Azure DevOps:

1. **Local Terraform Testing**:
   - Run `terraform fmt -check` to verify code formatting:
     ```bash
     terraform fmt -check
     ```
   - Initialize Terraform without a backend and validate:
     ```bash
     terraform init -backend=false
     terraform validate
     ```
   - Test the Terraform configuration in a non-production environment by running:
     ```bash
     terraform plan
     terraform apply
     ```
     Destroy resources after testing to avoid costs:
     ```bash
     terraform destroy
     ```

2. **Local Docker Testing**:
   - Navigate to the [theoneglobal/azure-devops-django](https://github.com/theoneglobal/azure-devops-django) repository directory.
   - Build the Docker image locally:
     ```bash
     docker build -t myapp:test .
     ```
   - Run the container to verify the application:
     ```bash
     docker run -p 8000:8000 myapp:test
     ```
     Access the application at `http://localhost:8000`.

3. **Pipeline Testing**:
   - After applying Terraform, push the `azure-pipelines.yml` file to the Azure DevOps repository created by Terraform.
   - Trigger the pipeline manually or via a commit to the `main` branch.
   - Check the pipeline logs in Azure DevOps to verify that:
     - Terraform commands (`init`, `validate`, `plan`) complete successfully.
     - The Docker image is built and pushed to the ACR.
   - Use the Terraform outputs (`terraform output`) to confirm the ACR URL and repository details.

## Repository Structure

- `main.tf`: Core Terraform configuration for Azure DevOps and Azure resources.
- `variables.tf`: Variable definitions for customizable inputs.
- `outputs.tf`: Outputs for key resource IDs and attributes.
- `versions.tf`: Specifies Terraform and provider versions for reproducibility.
- `backend.tf.example`: Example configuration for optional Azure backend (Terraform block).
- `backend.hcl.example`: Example configuration for optional Azure backend (HCL format).
- `terraform.tfvars.example`: Example Terraform variables configuration.
- `azure-pipelines.yml`: Azure DevOps CI pipeline configuration.
- `scripts/setup-backend.sh`: Script to provision Azure resources for the backend.
- `.github/workflows/terraform.yml`: GitHub Actions workflow for linting Terraform code.
- `.github/dependabot.yml`: Dependabot configuration for Terraform dependencies.
- `.github/pull_request_template.md`: Template for pull request descriptions.
- `README.md`: This file, providing documentation.
- `CONTRIBUTING.md`: Guidelines for contributing to the repository.
- `CODE_OF_CONDUCT.md`: Community code of conduct.
- `LICENSE`: MIT License for the repository.
- `.gitignore`: Excludes sensitive files and development artifacts.

## Outputs

After applying the Terraform configuration, the following outputs are available:

- `azuredevops_project_id`: ID of the Azure DevOps project.
- `git_repository_id`: ID of the Git repository.
- `build_definition_id`: ID of the CI pipeline.
- `variable_group_id`: ID of the variable group.
- `acr_id`: ID of the Azure Container Registry.
- `managed_identity_id`: ID of the user-assigned managed identity.
- `service_endpoint_id`: ID of the Azure DevOps service endpoint.

Use `terraform output` to view these values:

```bash
terraform output
```

## CI Pipeline (Azure DevOps)

The `azure-pipelines.yml` file defines a CI pipeline that:

- Triggers on changes to the `main` branch.
- Installs Terraform (version 1.5.0).
- Runs `terraform init`, `validate`, and `plan` to validate the Terraform configuration.
- Clones the [theoneglobal/azure-devops-django](https://github.com/theoneglobal/azure-devops-django) repository, builds the Docker image, and pushes it to the ACR using the managed identity.
- Uses the variable group created by Terraform (`$(AZURE_DEVOPS_ORG)-ci-vars`).

To enable the pipeline in Azure DevOps:

1. Ensure the pipeline is linked to the repository created by Terraform (`${local.prefix}-${var.prefix}-${random_string.unique_suffix.result}`).
2. Set the following variables in Azure DevOps (via pipeline variables or a separate variable group):
   - `ARM_CLIENT_ID`: Azure service principal client ID.
   - `ARM_CLIENT_SECRET`: Azure service principal client secret (marked as secret).
   - `ARM_SUBSCRIPTION_ID`: Azure subscription ID.
   - `ARM_TENANT_ID`: Azure AD tenant ID.
   - `AZDO_PERSONAL_ACCESS_TOKEN`: Azure DevOps PAT (marked as secret).
   - `ARM_ACCESS_KEY`: Storage account key (marked as secret, if using the Azure backend).
   - `DJANGO_REPO_URL`: URL of the Django repository (`https://github.com/theoneglobal/azure-devops-django.git`).
   - `ACR_NAME`: Name of the ACR provisioned by Terraform (from `terraform output acr_id`).
3. Verify the service connection (`Azure DevOps ACR Service Connection`) created by Terraform is active and authorized in the Azure DevOps project settings.

## GitHub Actions (Linting)

The `.github/workflows/terraform.yml` file defines a GitHub Actions workflow that:

- Triggers on push or pull requests to the `main` branch.
- Installs Terraform (version 1.5.0).
- Runs `terraform fmt -check` to verify code formatting.
- Runs `terraform init -backend=false` and `terraform validate` to check configuration syntax.
- Requires no authentication, as it only lints the code locally.

The workflow status is displayed via the `Terraform Lint` badge at the top of this README, linking to the workflow runs in the [theoneglobal/azure-devops](https://github.com/theoneglobal/azure-devops) repository.

## Dependabot

The `.github/dependabot.yml` file configures Dependabot to:

- Check for updates to Terraform providers (e.g., `hashicorp/random`, `azure/azapi`) and modules daily.
- Create pull requests for dependency updates, labeled with `dependencies` and `terraform`.
- Limit open pull requests to 10 to avoid overwhelming the repository.

The Dependabot badge at the top of this README indicates that dependency updates are enabled, linking to the repository’s security settings.

## Notes

- The Azure DevOps CI pipeline expects the `azure-pipelines.yml` file to be in the root of the Git repository created by Terraform.
- The repository uses a random 4-character suffix for unique naming to avoid conflicts in Azure DevOps and Azure resource names.
- The managed identity uses workload identity federation for secure authentication with ACR, managed by Terraform.
- The Azure backend is optional. If not used, Terraform will store state locally. To use the backend, configure either `backend.tf` or `backend.hcl` as described in the Setup section.
- Ensure the Azure DevOps organization and Azure subscription are in the same Azure AD tenant for federated credentials to work.
- The GitHub Actions workflow is for linting only and does not interact with Azure or Azure DevOps resources, complementing the Azure DevOps pipeline for CI/CD tasks.
- The [theoneglobal/azure-devops-django](https://github.com/theoneglobal/azure-devops-django) repository must be accessible to the Azure DevOps pipeline, either publicly or via a PAT with read access.
