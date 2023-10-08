#!/usr/bin/env bash

set -e

image="blog-jekyll"
docker build -t ${image} .
docker run -v "$PWD":/jekyll -p "127.0.0.1:4000:4000" \
  -p "127.0.0.1:35729:35729" \
  -ti ${image} $@