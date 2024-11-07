#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# PS4='$LINENO:'
# set -x

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Global Vars
input_file="$script_dir/servicebus-configuration.yml"
auth_keys_file="$script_dir/auth_keys.yaml"
debug=false
register_provider=false
dump_keys=true

function provider_registration() {
  local provider="$1"
  local az_subscription="$2"
  local registered_providers="$3"

  # Return registered list via echo if added
  if [[ "$registered_providers" == *"$provider"* ]]; then
    echo "Provider already registered: $provider" >&2
    echo "$registered_providers" && return 0
  fi

  args=(
    --subscription "$az_subscription"
    --namespace "$provider"
  )

  echo "Checking provider registration status for: $provider" >&2
  service_bus_provider=$(az provider show "${args[@]}")

  provider_status=$(jq \
    --raw-output \
    '.registrationState' <<< "$service_bus_provider"
  )

  if [[ "$provider_status" == 'Registered' ]]; then
    echo "Provider already registered: $provider" >&2
    registered_providers+="$provider|"
    echo "$registered_providers" && return 0
  fi

  echo "Registering provider: $provider" >&2
  if az provider register "${args[@]}"; then
    echo "Registered: $provider provider." >&2
    registered_providers+="$provider|"
    echo "$registered_providers" && return 0
  else
    echo "Error: Failed to register provider: $provider!" && exit 1
  fi
}

function create_namespace() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local location="$4"
  local sku="$5"

  if [[ "$namesapce" == null ]]; then
    echo "Warning: Namespace is required." && return 1
  fi

  local args=(
    --subscription "$az_subscription"
    --resource-group "$az_resource_group"
    --name "$namesapce"
  )

  if az servicebus namespace show "${args[@]}"; then
    echo "Namespace already exists: $namesapce" && return 0
  fi

  args+=(
    --location "$location"
    --sku "$sku"
  )
  if az servicebus namespace create "${args[@]}"; then
    echo "Namespace created: $namesapce" && return 0
  else
    echo "Failed to create namespace: $namesapce" && return 1
  fi
}

function create_topic() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local topic="$4"

  if [[ "$topic" == 'null' ]]; then echo "No topic provided."; return 1; fi

  local args=(
    --subscription "$az_subscription"
    --resource-group "$az_resource_group"
    --namespace-name "$namesapce"
    --name "$topic"
  )

  if az servicebus topic show "${args[@]}"; then
    echo "Topic already exists: $topic" && return 0
  fi

  echo "Creating Topic: $topic"
  if az servicebus topic create "${args[@]}"; then
    echo "Topic created: $topic" && return 0
  else
    echo "Failed to create topic: $topic" && return 1
  fi

}

function create_shared_access_policy() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local entity="$4"
  local policy_name="$5"
  local rights="$6"
  local type="$7"

  if [[ "$policy_name" == 'null' ]]; then
    echo "No policy name provided for $type: $entity." && return 1
  fi

  args=(
    --subscription "$az_subscription"
    --resource-group "$az_resource_group"
    --namespace-name "$namesapce"
    "--$type-name" "$entity"
    --name "$policy_name"
  )

  if az servicebus "$type" authorization-rule show "${args[@]}"; then
    echo "Policy already exists: $policy_name for $type: $entity" && return 0
  fi

  # az expects a validate json array for rights ["right1", "right2", ...]
  list_of_rights=$(jq --arg rights "$rights" --compact-output --null-input \
    '$rights | split(", ")'
  )

  args+=(
    --rights "$list_of_rights"
  )

  echo "Creating $type: $entity's shared access policy: $policy_name"
  if az servicebus "$type" authorization-rule create "${args[@]}"; then
    echo "Created policy: $policy_name for $type: $entity" && return 0
  else
    echo "Failed to create policy: $policy_name for $type: $entity" && return 1
  fi
}

function get_authorization_keys() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local entity="$4"
  local policy="$5"
  local type="$6"
  local dump_keys="$7"

  if [[ "$policy" == 'null' ]]; then
    echo "No policy name provided for $type: $entity." >&2 && return 1
  fi

  args=(
    --subscription "$az_subscription"
    --resource-group "$az_resource_group"
    --namespace-name "$namesapce"
    "--$type-name" "$entity"
    --name "$policy"
  )

  echo "Getting $type: $entity's shared access policy: $policy key" >&2
  keys=$(az servicebus "$type" authorization-rule keys list "${args[@]}")
  key_retrieval="$?"
  if [[ "$key_retrieval" -eq 0 ]]; then
    echo "Retrieved authorization Key for: $policy" >&2
    if [[ "$dump_keys" == true ]]; then
      dump_auth_keys \
        "$keys" "$namesapce" "$entity" "$type" "$policy"
    else
      echo "$keys"
      return 0
    fi
  else
    echo "Failed to retrieve key: $policy for $type: $entity" >&2
    return 1
  fi
}

function dump_auth_keys() {
  local keys_json="$1"
  local namespace="$2"
  local entity="$3"
  local type="$4"
  local policy="$5"

  entity="$entity" \
  type="$type" \
  namespace="$namespace" \
  policy="$policy" \
  keys_json="$keys_json" \
    yq \
     --inplace \
      '. + [{
        "namespace": strenv(namespace),
        "type": strenv(type),
        "entity": strenv(entity),
        "policy": strenv(policy),
        "keys": env(keys_json)
      }]' "$auth_keys_file"
}

function create_topic_subscription() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local topic="$4"
  local topic_subscription="$5"

  if [[ "$topic_subscription" == 'null' ]]; then
    echo "No subscription provided." && return 1
  fi

  args=(
    --subscription "$az_subscription"
    --resource-group "$az_resource_group"
    --namespace-name "$namesapce"
    --topic-name "$topic"
    --subscription-name "$topic_subscription"
  )

  if az servicebus topic subscription show "${args[@]}"; then
    echo "Subscription already exists: $topic_subscription" && return 0
  fi

  args+=(
    --status 'Active'
  )

  echo "Creating Topic: $topic's subscription: $tsub"
  if az servicebus topic subscription create "${args[@]}"; then
    echo "Subscription created: $topic_subscription" && return 0
  else
    echo "Failed to create subscription: $topic_subscription" && return 1
  fi
}

function create_queue() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local queue="$4"

  if [[ "$queue" == 'null' ]]; then
    echo "No queue name provided." && return 1
  fi

  args=(
    --subscription "$az_subscription"
    --resource-group "$az_resource_group"
    --namespace-name "$namesapce"
    --name "$queue"
  )

  if az servicebus queue show "${args[@]}"; then
    echo "Queue already exists: $queue" && return 0
  fi

  echo "Creating Queue: $queue"
  if az servicebus queue create "${args[@]}"; then
    echo "Queue created: $queue" && return 0
  else
    echo "Failed to create queue: $queue" && return 1
  fi
}

#-------------------------------------------------------------------------------
# Main function to create service bus resources. Note that we'll alwasy validate
# if the resource already exists before creating it. This is because az will
# attempt to `update` the resource if it already exists, which can cause
# unexpected behavior.
#-------------------------------------------------------------------------------
function main() {
  filter_schema="$(yq '.filterSchema' "$input_file")"

  registered_providers=''
  while IFS=$'\t' read -r az_sub az_rg ns loc sku topic tsap trights \
  tsub queue qsap qrights; do
    echo "-----------------------------------
      Processing...
      Azure Subscription: $az_sub
      Resource Group: $az_rg
      Namespace: $ns
      Location: $loc
      Topic: $topic
      Sku: $sku
      Topic Subscription: $tsub
      Topic Shared Access Policy: $tsap
      Topic Rights: $trights
      Queue: $queue
      Queue Shared Access Policy: $qsap
      Queue Rights: $qrights"
    echo "-----------------------------------"

    if [[ "$register_provider" == true ]]; then
      registered_providers=$(provider_registration \
        'Microsoft.ServiceBus' "$az_sub" "$registered_providers")
    fi

    echo "Creating Namespace: $ns"
    if ! create_namespace "$az_sub" "$az_rg" "$ns" "$loc" "$sku"; then
      continue
    fi

    if create_topic "$az_sub" "$az_rg" "$ns" "$topic"; then
      create_shared_access_policy \
        "$az_sub" "$az_rg" "$ns" "$topic" "$tsap" "$trights" 'topic'
      get_authorization_keys \
        "$az_sub" "$az_rg" "$ns" "$topic" "$tsap" 'topic' "$dump_keys"
    fi

    create_topic_subscription "$az_sub" "$az_rg" "$ns" "$topic" "$tsub"

    if create_queue "$az_sub" "$az_rg" "$ns" "$queue"; then
      create_shared_access_policy \
        "$az_sub" "$az_rg" "$ns" "$queue" "$qsap" "$qrights" 'queue'
      get_authorization_keys \
        "$az_sub" "$az_rg" "$ns" "$queue" "$qsap" 'queue' "$dump_keys"
    fi

  done < <(yq --output-format tsv ".servicebus[] | $filter_schema" "$input_file")
}

#-------------------------------------------------------------------------------
# Pre-flight checks
if [[ ! -f "$input_file" ]]; then
  echo "Input file not found: $input_file" && exit 1
fi

if [[ "$dump_keys" == true ]]; then
  echo "Dumping keys to: $auth_keys_file"
  echo '[]' > "$auth_keys_file"
fi

if [[ "$debug" == true ]]; then yq '.' "$input_file"; fi
#-------------------------------------------------------------------------------

main
