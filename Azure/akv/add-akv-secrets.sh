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

function set_secret() {
    local key="$1" value="$2" type="${3:-string}"

    args=(--name "${key//_/-}"
        --vault-name "$VAULT_NAME"
        --encoding utf-8)
    if [[ "$type" == "string" ]]; then
        args+=(--value "$value")
    else
        args+=(--file "$value")
    fi

    az keyvault secret set "${args[@]}"
}

if "$USE_SERVICE_PRINCIPAL"; then
    echo "Logging in w/ service principal..."
    login_w_sp "$APP_ID" "$APP_SECRET" "$TENANT"
fi

while IFS='|' read -r key value || [ -n "$key" ]; do
    type="string"
    file=''
    if [[ -f "$SCRIPT_DIR/$value" ]]; then
        file="$SCRIPT_DIR/$value"
        value=$(cat "$file");
        type="file"
    fi
    echo "Secret $type detected"
    masked_value="${value:0:5}*****"
    echo "Adding Key: $key :: Masked Value: $masked_value"

    SECRET_SET=$(set_secret "$key" "${file:-$value}" $type)

    jq ' .value |= "\(.[0:5])*****"' <<<"$SECRET_SET"
done < "$SCRIPT_DIR/add-akv-secrets-list.txt"
