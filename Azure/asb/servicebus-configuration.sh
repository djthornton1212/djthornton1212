#! /usr/local/Cellar/bash/*/bin/bash --noprofile --norc -eo pipefail
# shellcheck source=/Users/dthornton/.zshrc

# PS4='$LINENO:'
# set -x

function create_namespace() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local location="$4"
  local sku="$5"

  az servicebus namespace create \
    --subscription "$az_subscription" \
    --resource-group "$az_resource_group" \
    --name "$namesapce" \
    --location "$location" \
    --sku "$sku"
}

function namespace_exists() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"

  if [[ "$namesapce" == null ]]; then
    echo "Error: Namespace is required." && exit 1
  fi

  az servicebus namespace show \
    --subscription "$az_subscription" \
    --resource-group "$az_resource_group" \
    --name "$namesapce"
}

function create_topic() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local topic="$4"

  az servicebus topic create \
    --subscription "$az_subscription" \
    --resource-group "$az_resource_group" \
    --namespace-name "$namesapce" \
    --name "$topic"
}

function topic_exists() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local topic="$4"

  az servicebus topic show \
    --subscription "$az_subscription" \
    --resource-group "$az_resource_group" \
    --namespace-name "$namesapce" \
    --name "$topic"
}

function create_subscription() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local topic="$4"
  local subscription="$5"

  az servicebus topic subscription create \
    --subscription "$az_subscription" \
    --resource-group "$az_resource_group" \
    --namespace-name "$namesapce" \
    --topic-name "$topic" \
    --subscription-name "$subscription" \
    --status 'Active'
}

function subscription_exists() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local topic="$4"
  local subscription="$5"

  if [[ "$subscription" == 'null' ]]; then
    echo "No subscription provided."
    return
  fi

  az servicebus topic subscription show \
    --subscription "$az_subscription" \
    --resource-group "$az_resource_group" \
    --namespace-name "$namesapce" \
    --topic-name "$topic" \
    --subscription-name "$subscription" \
    --output json
}

function create_shared_access_policy() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local topic="$4"
  local shared_access_policy_name="$5"
  local rights="$6"

  az servicebus topic authorization-rule create \
    --subscription "$az_subscription" \
    --resource-group "$az_resource_group" \
    --namespace-name "$namesapce" \
    --topic-name "$topic" \
    --name "$shared_access_policy_name" \
    --rights "$rights"
}

function shared_access_policy_exists() {
  local az_subscription="$1"
  local az_resource_group="$2"
  local namesapce="$3"
  local topic="$4"
  local shared_access_policy_name="$5"

  if [[ "$shared_access_policy_name" == 'null' ]]; then
    echo "No shared access policy provided."
    return
  fi

  az servicebus topic authorization-rule show \
    --subscription "$az_subscription" \
    --resource-group "$az_resource_group" \
    --namespace-name "$namesapce" \
    --topic-name "$topic" \
    --name "$shared_access_policy_name"
}

function main() {
  local input_file="$1"
  local debug="${2:-false}"

  if [[ "$debug" == true ]]; then yq '.' "$input_file"; fi
  filter_schema="$(yq '.filterSchema' "$input_file")"

  while IFS=$'\t' read -r az_sub az_rg ns loc sku topic sap rights sub; do
    echo '-----------------------------------'
    echo 'Processing...'
    echo "Azure Subscription: $az_sub"
    echo "Resource Group: $az_rg"
    echo "Namespace: $ns"
    echo "Location: $loc"
    echo "Topic: $topic"
    echo "Sku: $sku"
    echo "Subscription: $sub"
    echo "Shared Access Policy: $sap"
    echo "Rights: $rights"

    echo "Validating Namespace: $ns"
    if ! namespace_exists "$az_sub" "$az_rg" "$ns"; then
      echo "Failed validation for namespace: $ns"
      echo "Creating Namespace: $ns"
      create_namespace "$az_sub" "$az_rg" "$ns" "$loc" "$sku"
    fi

    if [[ "$topic" == 'null' ]]; then echo "No topic provided." && continue; fi
    echo "Validating Topic: $topic"
    if ! topic_exists "$az_sub" "$az_rg" "$ns" "$topic"; then
      echo "Failed validation for topic: $topic"
      echo "Creating Topic: $topic"
      create_topic "$az_sub" "$az_rg" "$ns" "$topic"
    fi

    echo "Validating shared access policy: $sub"
    if ! shared_access_policy_exists "$az_sub" "$az_rg" "$ns" "$topic" "$sap";
    then
      echo "Creating shared access policy: $sap"
      set_authorization_policy "$az_sub" "$az_rg" "$ns" "$topic" "$sap" "$rights"
    fi

    echo "Validating Subscription: $sub"
    if ! subscription_exists "$az_sub" "$az_rg" "$ns" "$topic" "$sub"; then
      echo "Failed validation for subscription: $sub"
      echo "Creating Subscription: $sub"
      create_subscription "$az_sub" "$az_rg" "$ns" "$topic" "$sub"
    fi
  done < <(yq  --output-format tsv ".servicebus[] | $filter_schema" "$input_file")
}

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
input_file="$script_dir/servicebus-configuration.yml"
# debug=true
if [[ ! -f "$input_file" ]]; then
  echo "Input file not found: $input_file"
  exit 1
fi

main "$input_file" "$debug"
