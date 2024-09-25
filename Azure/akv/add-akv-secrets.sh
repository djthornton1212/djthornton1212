#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VAULT_NAME='YOUR-VAULT-NAME'

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

while IFS='|' read -r key value; do
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
