#!/usr/bin/env bash

image="blog-jekyll"
docker build -t ${image} .
docker run -v `pwd`:/jekyll -p "4000:4000" -ti ${image}