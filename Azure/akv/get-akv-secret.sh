#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# Input Variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VAULT_NAME='YOUR-VAULT-NAME'
USE_SERVICE_PRINCIPAL=false

# Service Principal Variables if `USE_SERVICE_PRINCIPAL` is true
APP_ID=''
APP_SECRET=''
TENANT=''

function login_w_sp() {
    local app_id="$1" app_secret="$2" tenant="$3"
    az login \
        --service-principal \
        --username "$app_id" \
        --password "$app_secret" \
        --tenant "$tenant"
}

if "$USE_SERVICE_PRINCIPAL"; then
    echo "Logging in w/ service principal..."
    login_w_sp "$APP_ID" "$APP_SECRET" "$TENANT"
fi

while read -r line || [ -n "$line" ]; do
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
