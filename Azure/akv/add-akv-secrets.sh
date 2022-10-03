#! /usr/local/Cellar/bash/5.1.16/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VAULT_NAME='YOUR-VAULT-NAME'

while IFS='|' read -r key value; do
    echo "Adding Key: $key :: Value: $value"
    az keyvault secret set \
    --name "${key//_/-}" \
    --vault-name "$VAULT_NAME" \
    --value "$value" \
    --encoding utf-8
done < "$SCRIPT_DIR/akv-secrets-list.txt"
