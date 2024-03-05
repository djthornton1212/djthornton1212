#! /usr/local/Cellar/bash/5.1.16/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# Get secret syntax

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VAULT_NAME='YOUR-VAULT-NAME'

while read -r line; do
    [[ "$DEBUG" ]] && echo "Retrieving secret for $line"
    [[ "$DEBUG" ]] && echo "-----------------------------------"
    GET_SECRET=$(az keyvault secret show \
        --name "$line" \
        --vault-name "$VAULT_NAME" \
        --query "value" \
        --output tsv 2>&1
    )

    echo "-----------------------------------"
    if [[ "$GET_SECRET" == "ERROR"* ]]; then
        CATCH_ERROR=$(grep -o 'ERROR:.*vault.' <<< "$GET_SECRET")
        CATCH_CODE=$(grep 'Code:' <<< "$GET_SECRET")
        echo "$CATCH_ERROR"
        echo "$CATCH_CODE"
        continue
    fi

    echo "Secret Name: $line"
    echo "Secret Value: $GET_SECRET"

done < "$SCRIPT_DIR/get-akv-secrets-list.txt"
