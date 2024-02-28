#! /usr/local/Cellar/bash/*/bin/bash

# Common
ACR="YOUR_ACR_NAME_FULL_NAME" # <name>.azurecr.io
SHORT_ACR=${ACR/.azurecr.io/}

# From Repository
FROM_REPO="FROM_REPO_NAME"
FROM_ENV="ENVIRONMENT-CAPS-MATTER"

# To Repository
TO_ENV="ENVIRONMENT-CAPS-MATTER"
TO_REPO="${FROM_REPO/$FROM_ENV/$TO_ENV}"
# TO_REPO='SPECIFIC_REPO_NAME' # Change if needed


# Get All tags
FROM_TAGS=$(az \
  acr repository show-tags \
  --name "$ACR" \
  --repository "$FROM_REPO" \
  --output json
)

while read -r FROM_TAG; do
  SOURCE="$ACR/$FROM_REPO:$FROM_TAG"
  TO_IMAGE="$TO_REPO:$FROM_TAG"

  printf "Transferring image:"$'\n'"Source: %s"$'\n'"To: %s"$'\n' \
    "$SOURCE" "$TO_IMAGE"

  MOVED_TAG=$( az acr import \
    --image "$TO_IMAGE" \
    --name "$SHORT_ACR" \
    --output json \
    --source "$SOURCE" 2>&1
  )
  RESP="$?"

  if [[ "$MOVED_TAG" == 'ERROR: (Conflict)'* ]]; then
    echo "Tag already exists in target repository. Continuing..."
    continue
  elif [[ "$MOVED_TAG" == 'ERROR: '*  || "$RESP" != 0 ]]; then
    echo "There was an error: $MOVED_TAG"
  fi
  # Note that `az acr import` does not return anything if successful
done < <(jq --raw-output '.[]' <<< "$FROM_TAGS")
