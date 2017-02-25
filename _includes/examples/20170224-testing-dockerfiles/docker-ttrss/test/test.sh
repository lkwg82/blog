#!/bin/bash

set -e

function finish {
	local exitCode=$?
	set +x

	echo "cleanup "
        docker-compose stop > /dev/null 2>&1 &
	
	echo "-------"
	if [ "$exitCode" == "0" ]; then
		echo "Test: SUCCESS"
	else
		docker-compose logs
		echo
		echo "Test: failed"
		exit $exitCode
	fi
}
trap finish EXIT

# build docker image
docker build -t test-ttrss ..

docker-compose up -d db

# give mariadb some time to startup
sleep 5

docker-compose up -d ttrss

cmd='docker-compose exec ttrss curl --fail -v http://localhost:8080/'

set -x

# tests
$cmd | grep "^< HTTP/1.1 200 OK" || exit 1
$cmd | grep "^< Set-Cookie: ttrss_sid=deleted" || exit 1

set +x


