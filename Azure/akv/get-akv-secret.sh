#! /usr/local/Cellar/bash/5.1.16/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# Get secret syntax

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VAULT_NAME='YOUR-VAULT-NAME'

while read -r line; do
    GET_SECRET=$(az keyvault secret show \
    --name "$line" \
    --vault-name "$VAULT_NAME" \
    --query "value" \
    --output tsv)
    echo "Retrieving secret for $line | $GET_SECRET"

done < "$SCRIPT_DIR/get-akv-secrets-list.txt"
