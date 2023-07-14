#! /usr/local/Cellar/bash/*/bin/bash
# PS4='$LINENO:'
# set -x

# shellcheck source=/Users/dthornton/.zshrc

# Delete specific list object from array based on key match
if [ "${#TOKEN_FAILURES[@]}" -ne 0 ]; then
  echo "::group::Removing token creation failures from list."
    for SCOPE_NAME in "${TOKEN_FAILURES[@]}"; do
      echo "Removing Scope: $SCOPE_NAME"
      SCOPE_MAPS=$(jq \
        --compact-output \
        --arg scopeName "$SCOPE_NAME" \
        'del(.[] | select(.scopeName == $scopeName))' \
        <<< "$SCOPE_MAPS"
      )
    done
  echo "::endgroup::"
fi
