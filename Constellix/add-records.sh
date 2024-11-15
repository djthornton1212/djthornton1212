#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# PS4='$LINENO:'
# set -x

################################################################################
# Requirements jq, curl, openssl
command -v jq >/dev/null || {
  echo "jq is required to run this script. Please install jq."
  exit 1
}
command -v curl >/dev/null || {
  echo "curl is required to run this script. Please install curl."
  exit 1
}
command -v openssl >/dev/null || {
  echo "openssl is required to run this script. Please install openssl."
  exit 1
}
################################################################################
# DON'T FORGET TO ADD YOUR API KEY TO YOUR ENV: "CONSTELLIX_SECRET_KEY" OR
# SET IT DIRECTLY IN THE auth_token() FUNCTION BELOW
################################################################################
function add_record() {
  local auth="$1" domain_id="$2" record_payload="$3"

  local endpoint="domains/$domain_id/records"
  constellix_api "$endpoint" "$auth" "$record_payload"
}

function auth_token() {
  TIME="$(date +%s%3N)"
  HMAC=$(echo -n "$TIME" |
    openssl dgst -sha1 -hmac "$CONSTELLIX_SECRET_KEY" -binary |
      base64
  )
  echo "$CONSTELLIX_API_KEY:$HMAC:$TIME"
}

function constellix_api(){
  local endpoint="$1" auth_token="$2" data="$3"

  local base='https://api.dns.constellix.com/v4'

  args=(
    -w '\n'
    --location "$base/$endpoint"
    --header 'Content-Type: application/json'
    --header "x-cns-security-token: $auth_token"
    --silent
  )

  if [[ -n "$data" ]]; then
    args+=(--request POST)
    args+=(--data "$data")
  fi

  curl "${args[@]}"
}

function get_domains(){
  local auth_token="$1"

  local endpoint='domains'
  constellix_api "$endpoint/" "$auth"
}

function filter_for_id(){
  local search_name="$1" search_type="$2" records="$3"

  jq \
    --arg name "$search_name" \
    --arg type "$search_type" \
    'if $type == "new" then
      .data.id
    else
      .data[] |
        if $type == "domain" then
          select(.name == $name).id
        elif $type != null then
          select(.type == $type and .name == $name).id
        else
          empty
        end
    end' <<< "$records"
}

function main() {
  local record_data="$1"
  local domain name record_payload auth domain_id record record_id

  domain=$(jq --raw-output '.domain' <<< "$record_data")
  name=$(jq --compact-output --raw-output '.name' <<< "$record_data")
  record_payload=$(jq --compact-output 'del(.domain)' <<< "$record_data")

  echo '###############################################'
  echo 'Processing...'
  echo "Record Name: $name in Domain: $domain"
  if "$DEBUG"; then echo "Payload: " && jq '.'<<< "$record_payload"; fi
  echo '###############################################'
  ##############################################################################
  # Setup authorization token for Constellix API calls
  ##############################################################################
  auth=$(auth_token)

  ##############################################################################
  # Get Domain ID from list of all domains
  ##############################################################################
  domain_id=$(filter_for_id "$domain" "domain" "$(get_domains "$auth")")
  if [[ -z "$domain_id" ]]; then
    echo "Domain not found. Continuing..." && return 1
  fi
  echo "Domain ID: $domain_id"

  ##############################################################################
  # Add Record
  ##############################################################################
  record=$(add_record "$auth" "$domain_id" "$record_payload")
  if [[ "$record" =~ 'already exists' ]]; then
    echo "Record: $name already exists. Continuing..." && return 0
  elif [[ "$record" =~ 'error' ]]; then
    echo 'Record creation failed!'$'\n'"Error response: $record" && return 1
  fi
  record_id=$(filter_for_id 'null' 'new' "$record")
  echo "Record ID #$record_id created for $name in $domain."
}

DEBUG=true
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
records_list="$SCRIPT_DIR/add-records.yaml"
while read -r record_entry; do
  if ! main "$record_entry"; then failure=true && continue; fi
done < <(yq --output-format json --indent 0 '.records[]' "$records_list")

if [[ "$failure" == true ]]; then
  echo "One or more records failed to create. Please check the logs." && exit 1
fi