#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc
# PS4='$LINENO:'
# set -x


function AZ_KEYVAULT_QUERY {
  local KEY_ENTRY="$1"; local VAULT_NAME="$2"

  az keyvault secret show \
  --name "$KEY_ENTRY" \
  --vault-name "$VAULT_NAME" \
  --query value \
  --output tsv
}


SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
VAULT_NAME='YOUR-VAULT-NAME'

echo "Beginning Azure KeyVault key comparison script from Vault: $VAULT_NAME"
while IFS='|' read -r KEY1 KEY2; do
  echo $'\n'"Gathering 1st Key: $KEY1"
  SECRET1=$(AZ_KEYVAULT_QUERY "$KEY1" "$VAULT_NAME")
  echo "Gathering 2nd Key $KEY2"
  SECRET2=$(AZ_KEYVAULT_QUERY "$KEY2" "$VAULT_NAME")
  echo "Comparing secrets between gathered keys:"
  if [ "$SECRET1" == "$SECRET2" ]; then
    MATCH=true
  else
    MATCH=false
  fi
  echo "Keys match: $MATCH"
done < "$SCRIPT_DIR/compare-keys.txt"
