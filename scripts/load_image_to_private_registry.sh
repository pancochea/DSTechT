#!/bin/bash

LOCAL_REPO_URL="localhost:5000"

if [ -z "$1" ] && [ -z "$2" ]; then
    echo "Parameter 1: the image to copy"
    echo "Parameter 2: The origin repository (Optional)"
    exit 1
fi

docker pull $2$1
docker tag $2$1 $LOCAL_REPO_URL/$1
docker push $LOCAL_REPO_URL/$1