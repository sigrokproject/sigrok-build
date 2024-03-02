#!/bin/sh

# Note: Use "export CR_PAT=ghp_...." to make the github token available to this script
# Use "export GH_USER=..." to set your github user
# See https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

cd docker
docker build --progress=plain -f sigrok-mxe.Dockerfile -t sigrok-mxe . && \
	echo $CR_PAT | docker login ghcr.io -u $GH_USER --password-stdin && \
	docker push ghcr.io/$GH_USER/sigrok-mxe:latest
cd ..
