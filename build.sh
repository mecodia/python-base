#!/bin/sh
# Build and push one tag for amd64 and arm64 architecture

TAG=v5.0-rc2
IMAGE=mecodia/python-base

echo "Building $IMAGE:$TAG"

docker buildx build --platform "linux/arm64" --tag $IMAGE:$TAG-arm64 .
docker buildx build --platform "linux/amd64" --tag $IMAGE:$TAG-amd64 .

docker push $IMAGE:$TAG-arm64
docker push $IMAGE:$TAG-amd64

docker manifest create $IMAGE:$TAG \
    --amend $IMAGE:$TAG-arm64 \
    --amend $IMAGE:$TAG-amd64

docker manifest push $IMAGE:$TAG
