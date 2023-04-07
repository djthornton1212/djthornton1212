#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# Transfer secret

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# From environment:
FROM_ENV='FROM_ENVIRONMENT'
FROM_VAULT_NAME='YOUR_FROM_VAULT_NAME'

# To environment:
TO_ENV='TO_ENVIRONMENT'
TO_VAULT_NAME='YOUR_TO_VAULT_NAME'
TRANSFER_LIST="$SCRIPT_DIR/transfer-akv-secrets-list.txt"

while read -r ORIGINAL_KEY; do
  SECRET_VALUE=$(az keyvault secret show \
  --name "$ORIGINAL_KEY" \
  --vault-name "$FROM_VAULT_NAME" \
  --query "value" \
  --output tsv)

  echo "Transfering secret $ORIGINAL_KEY to ..."

  NEW_KEY="${ORIGINAL_KEY/$FROM_ENV/$TO_ENV}"
  echo "  Vault Name: $TO_VAULT_NAME
  Key: $NEW_KEY :: Value: $SECRET_VALUE
  "

  az keyvault secret set \
  --name "$NEW_KEY" \
  --vault-name "$TO_VAULT_NAME" \
  --value "$SECRET_VALUE" \
  --encoding utf-8 \
  --query "id"

done < "$TRANSFER_LIST"
