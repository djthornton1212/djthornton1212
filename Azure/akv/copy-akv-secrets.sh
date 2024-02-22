#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# Copy secret

VAULT_NAME='YOUR-VAULT-NAME'
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
COPY_LIST="$SCRIPT_DIR/copy-akv-secrets-list.txt"

function AZ_KEYVAULT_ADD_KEY {
  local KEY="$1"; local VALUE="$2"; local VAULT_NAME="$3"

  az keyvault secret set \
    --name "$KEY" \
    --vault-name "$VAULT_NAME" \
    --value "$VALUE" \
    --encoding utf-8 \
    --query '{name: name, value: value}'
}

function AZ_KEYVAULT_QUERY_KEY {
  local KEY_ENTRY="$1"; local VAULT_NAME="$2"

  az keyvault secret show \
  --name "$KEY_ENTRY" \
  --vault-name "$VAULT_NAME" \
  --query value \
  --output tsv
}

while IFS='|' read -r SOURCE_KEY DEST_KEY; do
  if [ -z "$SOURCE_KEY" ] || [ -z "$DEST_KEY" ]; then
    echo "Skipping for empty 'source' or 'destination'."
    continue
  elif [ "$SOURCE_KEY" == 'source' ] || [ "$DEST_KEY" == 'destination' ]; then
    echo "Skipping header row."
    continue
  fi

  # Gather source secret
  echo $'\n'"----------------------------------------"
  echo "Gathering value for source: $SOURCE_KEY"
  SOURCE_SECRET=$(AZ_KEYVAULT_QUERY_KEY "$SOURCE_KEY" "$VAULT_NAME")
  if [ -z "$SOURCE_SECRET" ]; then
    echo $'\n'"! No secret found for source: $SOURCE_KEY in $VAULT_NAME. Skipping..."
    continue
  fi

  # Add secret to destination
  echo $'\n'"Adding Key: $DEST_KEY :: Value: ${SOURCE_SECRET:0:5}********"
  DEST_VALUES=$(AZ_KEYVAULT_ADD_KEY "$DEST_KEY" "$SOURCE_SECRET" "$VAULT_NAME")

  echo $'\n'"Successfully added:"
  echo "  Key: $(jq --raw-output '.name' <<< "$DEST_VALUES")"
  DEST_SECRET=$(jq --raw-output '.value' <<< "$DEST_VALUES")
  echo "  Value: ${DEST_SECRET:0:5}********"

done < "$COPY_LIST"
