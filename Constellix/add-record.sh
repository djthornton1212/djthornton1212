#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# PS4='$LINENO:'
# set -x

################################################################################
# DON'T FORGET TO ADD YOUR API KEY TO YOUR ENV: "CONSTELLIX_SECRET_KEY" OR
# SET IT FOR THE FUNCTION BELOW
################################################################################
auth_token() {
  TIME="$(date +%s%3N)"
  HMAC=$(echo -n "$TIME" |
    openssl dgst -sha1 -hmac "$CONSTELLIX_SECRET_KEY" -binary |
      base64
  )
  echo "$CONSTELLIX_API_KEY:$HMAC:$TIME"
}

constellix_api(){
  local url="$1" auth_token="$2" data="$3"

  args=(
    -w '\n'
    --location "$url"
    --header 'Content-Type: application/json'
    --header "x-cns-security-token: $auth_token"
  )

  if [[ -n "$data" ]]; then
    args+=(--request POST)
    args+=(--data "$data")
  fi

  curl "${args[@]}"
}

get_record_id(){
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

################################################################################
# Script Variables
################################################################################
auth=$(auth_token)
base='https://api.dns.constellix.com/v4'

# Configurable Variables
record_name='RECORD_NAME'
domain='<DOMAIN_NAME>'
host_value='<HOST_VALUE>'
record_type='<RECORD_TYPE>'

enabled='true'
notes='New development app.'
mode='standard'
region='default'
ttl='1800'

################################################################################
# Get Domain ID
################################################################################
endpoint='domains'
domains="$(constellix_api "$base/$endpoint/" "$auth")"
domain_id=$(get_record_id "$domain" "domain" "$domains")

if [[ -z "$domain_id" ]]; then
  echo "Domain ID not found for $domain. Exiting program"
  exit 1
fi
echo "Domain ID: $domain_id"
################################################################################
# Add Record
################################################################################
endpoint="domains/$domain_id/records"
record_data=$(jq \
  --argjson enabled "$enabled" \
  --arg host "$host_value" \
  --arg name "$record_name" \
  --arg notes "$notes" \
  --arg mode "$mode" \
  --arg region "$region" \
  --arg ttl "$ttl" \
  --arg type "$record_type" \
  --compact-output \
  --null-input \
  '{
    enabled: $enabled,
    name: $name,
    notes: $notes,
    mode: $mode,
    region: $region,
    ttl: $ttl,
    type: $type,
    value: [
      {
        "enabled": $enabled,
        "value": $host
      }
    ]
  }'
)

echo "Record Data to add:"
jq '.' <<< "$record_data"

record=$(constellix_api "$base/$endpoint" "$auth" "$record_data")

echo "Record add response: $record"
if [[ "$record" =~ 'error' ]]; then
  echo "Failed to create $record_type record $record_name. Exiting program"
  exit 1
fi

record_id=$(get_record_id '' 'new' "$record")
echo "Added Record ID: $record_id"
################################################################################
# Get Record
################################################################################
endpoint="domains/$domain_id/records/$record_id"
record=$(constellix_api "$base/$endpoint" "$auth")

if [[ "$record" =~ 'Not Found' ]]; then
  echo "Record not found for $record_name. Exiting program"
  exit 1
fi

echo "Record Data retrieved:"
jq '.' <<< "$record"
