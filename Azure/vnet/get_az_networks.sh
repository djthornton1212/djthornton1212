#! /usr/local/Cellar/bash/*/bin/bash
# shellcheck source=/Users/dthornton/.zshrc

# PS4='$LINENO:'
# set -x

# Requires: az, jq, yq

function get_vnets() {
  az network vnet list
}

function get_vnet_available_ips() {
  local vnet_id="$1"
  az network vnet list-available-ips --only-show-errors --ids "$vnet_id" 2>&1
}

function get_vnet_subnet_available_ips() {
  local subnet_id="$1"
  az network vnet subnet list-available-ips \
    --only-show-errors --ids "$subnet_id" 2>&1
}

function validate_ips() {
  local ips="$1"
  if [[ "$ips" != '['*']' ]]; then
    jq --arg error "$ips" --null-input '[$error]'
  else
    jq '.' <<< "$ips"
  fi
}

function initialize_filter() {
  local location="${1-.*}"
  jq --arg location "$location" \
    '[.[] | select(.location | test("(?i)\($location)")) | {
      name: .name,
      id: .id,
      location: .location,
      resourceGroup: .resourceGroup,
      addressPrefixes: .addressSpace.addressPrefixes,
      availableAddressPrefixes: [],
      subnets: [.subnets[] | {
        addressPrefix: .addressPrefix,
        availableSubnets: [],
        name: .name,
        id: .id,
        resourceGroup: .resourceGroup,
      }],
    }]' < <(get_vnets)
}

function append_available_ips() {
  local id="$1"
  local available_ips="$2"
  local initial_node="$3"
  local key="$4"
  local file="$5"

  yq --inplace --prettyPrint \
    "with($initial_node | select(.id == \"$id\");
      $key = $available_ips
    )" "$file"
}

function main() {
  local file="$1"
  local location="$2"

  # Writing to file as the size can possibly exceed allowed memory buffer of jq.
  if [[ -n $location ]]; then
    file="${file/.yaml/-${location}.yaml}"
  fi
  echo "File Name: $file"
  echo "Note this script is running in the following subscription:"
  az account show | jq '{name: .name, subscriptionId: .id}'

  echo "Please wait while we fetch the data..."

  # initialize the json string with the predefined filter
  initialize_filter "$location" | \
    yq --input-format json --output-format yaml > "$file"

  # loop through vnets and append available IPs spaces
  while IFS=$'\t' read -r id vnet rg; do
    echo "Searching for available IPs in vnet: $vnet with resource group: $rg"

    available_ips=$(validate_ips "$(get_vnet_available_ips "$id")")
    append_available_ips \
      "$id" "$available_ips" '.[]' '.availableAddressPrefixes' "$file"

  done < <(yq --output-format tsv '.[] |
    [.id, .name, .resourceGroup]' "$file")

  # loop through subnets and append available IPs subnets
  while IFS=$'\t' read -r subnet_id vnet subnet_name; do
    echo "Searching for available IPs in subnet: $subnet_name of vnet: $vnet"

    available_ips=$(validate_ips "$(get_vnet_subnet_available_ips "$subnet_id")")
    append_available_ips \
      "$subnet_id" "$available_ips" '.[].subnets[]' '.availableSubnets' "$file"

  done < <(yq --output-format tsv '.[] | {"name": .name, "subnets": .subnets[]}
    | [.subnets.id, .name, .subnets.name]' "$file")
}

location='eastus2' # if commented out, all locations will be returned
output_file='networks.yaml'

main "$output_file" "$location"
