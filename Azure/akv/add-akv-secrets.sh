#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VAULT_NAME='YOUR-VAULT-NAME'

while IFS='|' read -r key value; do
    masked_value="${value:0:5}*****"
    echo "Adding Key: $key :: Value: $masked_value"

    SECRET_SET=$(az keyvault secret set \
    --name "${key//_/-}" \
    --vault-name "$VAULT_NAME" \
    --value "$value" \
    --encoding utf-8)
    jq '.' <<< "${SECRET_SET/$value/$masked_value}"
done < "$SCRIPT_DIR/add-akv-secrets-list.txt"
