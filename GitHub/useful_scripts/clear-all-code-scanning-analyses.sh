#! /usr/local/Cellar/bash/5.1.16/bin/bash
# PS4='$LINENO:'
# set -x

ORG=''
REPO=''

SARIFS=$(curl \
-H "Authorization: Bearer $GITHUB_TOKEN" \
-H 'Accept: application/vnd.github.v3+json' \
"https://api.github.com/repos/$ORG/$REPO/code-scanning/analyses" | jq -r '.[].id')

while IFS=$'\n' read -r SID; do
  echo "Sarif ID: $SID"
  curl \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H 'Accept: application/vnd.github.v3+json' \
  -X DELETE \
  "https://api.github.com/repos$ORG/$REPO/code-scanning/analyses/$SID?confirm_delete"
done <<< "$SARIFS"
