#!/bin/bash

set -e

function finish {
	local exitCode=$?

	echo -n "cleanup: "
        docker image rm test-simple

	echo "---------"	
	if [ "$exitCode" == "0" ]; then
		echo "Test: SUCCESS"
	else
		echo "Test: failed"
		exit $exitCode
	fi
}
trap finish EXIT

# build image
docker build -t test-simple ..

set -x

# tests
docker run test-simple >/dev/null || exit 1

set +x


