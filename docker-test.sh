#!/usr/bin/env bash

set -e

cidfile=$(mktemp)
testDir="_test_dir"

image="blog-jekyll-test"
docker build --iidfile "${cidfile}" --tag ${image} .

rm -rf ${testDir}
rsync -a --exclude "${testDir}" --exclude "_site" --exclude "Gemfile.lock" $(pwd)/* ${testDir}

run="docker run -v $PWD/${testDir}:/jekyll --rm -ti ${image}"
${run} bundle config set --local path '_cache_'
${run} bundler install --jobs=100
${run} bundler exec jekyll build

rm -rf ${testDir}