#!/usr/bin/env bash

set -e

image="blog-jekyll"
docker build -t ${image} .

# https://www.redhat.com/en/blog/rootless-podman-user-namespace-modes
# podman needs userns

docker run -v "$PWD":/jekyll --userns=keep-id -p "127.0.0.1:4000:4000" \
  -p "127.0.0.1:35729:35729" \
  -ti ${image} $@