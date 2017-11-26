#!/usr/bin/env bash

set -e

cidfile=$(tempfile)
testDir="_test_dir"

image="blog-jekyll-test"
docker build --iidfile ${cidfile} --tag ${image} .

rm -rf ${testDir}
rsync -a --exclude "${testDir}" --exclude "_site" --exclude "Gemfile.lock" $(pwd)/* ${testDir}

run="docker run -v $(pwd)/${testDir}:/jekyll --rm -ti ${image}"
${run} bundler install --path .bundler --jobs=100
${run} bundler exec jekyll build

rm -rf ${testDir}