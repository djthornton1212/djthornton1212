#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# This script requires Azure CLI version 2.25.0 or later. Check version with `az --version`.

# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
AKV_NAME='<AKV_NAME>'
SERVICE_PRINCIPAL_NAME='<SP_NAME>'
SUBSCRIPTION='<SUBSCRIPTION_ID>'
ROLE='<ROLE>'

# Obtain the full registry ID for subsequent command args
AKV_REGISTRY_ID=$(az keyvault show --name "$AKV_NAME" --query "id" --output tsv)

# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'

az account set --subscription "$SUBSCRIPTION"
PASSWORD=$(az ad sp create-for-rbac --name "$SERVICE_PRINCIPAL_NAME" --scopes "$AKV_REGISTRY_ID" --role "$ROLE" --query "password" --output tsv)
USER_NAME=$(az ad sp list --display-name "$SERVICE_PRINCIPAL_NAME" --query "[].appId" --output tsv)

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $USER_NAME"
echo "Service principal password: $PASSWORD"
