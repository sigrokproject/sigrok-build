#!/bin/sh
cd docker
docker build --progress=plain -f sigrok-mxe.Dockerfile .
cd ..
