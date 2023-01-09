#! /usr/local/Cellar/bash/5.1.16/bin/bash
# PS4='$LINENO:'
# set -x

ARGOCD_URL='https://argocd...net'
API='api/v1'
API_ENDPOINT='applications'
NAMESPACE='env10'
PASSWORD="$(cat "$ONEDRIVE"/tokens/ArgoCD/githubbot.txt)"
SESSION_ENDPOINT='session'
USERNAME='githubbot'

SESSION_RESP="$(curl -s -w '\n' \
  --url "$ARGOCD_URL/$API/$SESSION_ENDPOINT" \
  --data "{\"username\":\"$USERNAME\",
  \"password\":\"$PASSWORD\"}")"


SESSION_TOKEN=$(jq -r '.token' <<< "$SESSION_RESP")

# echo "$SESSION_TOKEN"

ALL_APPS="$(curl -s -w '\n' \
  --url "$ARGOCD_URL/$API/$API_ENDPOINT" \
  --header "Authorization: Bearer $SESSION_TOKEN" \
  --header 'Content-type: application/json' \
  --data "{\"appNamespace\":\"$NAMESPACE\"}" \
  | jq '.')"

echo "All Applications in $NAMESPACE: $ALL_APPS"
