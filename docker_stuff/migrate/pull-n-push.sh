#! /usr/local/Cellar/bash/*/bin/bash

# Common
ACR="YOUR_ACR_NAME"

# From
FROM_REPO="FROM_REPO_NAME"
FROM_VER_TAG="FULL-HYPHENATED-TAG-NAME"

# To
TO_REPO="TO_REPO_NAME"
TO_ENV="ENVIRONMENT-CAPS-MATTER"
TO_VER_TAG="$FROM_VER_TAG" #Change if needed

# Tags
FROM_TAG=${ACR,,}/${FROM_REPO,,}:${FROM_VER_TAG}
TO_TAG=${ACR,,}/${TO_REPO,,}-${TO_ENV,,}:${TO_VER_TAG}

echo "From Tag: $FROM_TAG"
echo "To Tag: $TO_TAG"
echo "Migrate? [y/n]"
read -r RESP

if [[ "$RESP" = y ]]; then
  docker pull "$FROM_TAG"
  docker image tag "$FROM_TAG" "$TO_TAG"
  docker push "$TO_TAG"
else
  exit 0
fi
