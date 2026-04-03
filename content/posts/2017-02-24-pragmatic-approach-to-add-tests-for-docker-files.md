---
layout: post
title: testing dockerfiles
subtitle: a simple pragmatic approach 
date: 2017-02-23T23:23:07+01:00
comments: true
categories: docker tdd devops
---

Since a while I'm facing regularly issues with images create from docker files. 
So I'm trying to develop a simple approach to test them. It is inspired basically by 
<a href="https://www.martinfowler.com/bliki/TestDrivenDevelopment.html">TDD</a>.

# concept

Let me show my approach. It is aimed to be easy to implement and easy to comprehend.

I follow these simple steps:
- creating a `Dockerfile`
- create a `test.sh` under `test/`
- run `test.sh` from `test/`


-----

# trivial example

`Dockerfile`
```docker
FROM ubuntu

CMD date
```

`test.sh`
```bash
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
```
 
 and the output

```bash
$ ./test.sh 
Sending build context to Docker daemon 3.584 kB
Step 1/2 : FROM ubuntu
 ---> f49eec89601e
Step 2/2 : CMD date
 ---> Using cache
 ---> 50149deef371
Successfully built 50149deef371
+ docker run test-simple
+ set +x
cleanup: Untagged: test-simple:latest
---------
Test: SUCCESS
```

----
# more complex example with docker-compose

This example is about an application which consists of two images, app and database.
The test is only about the app, which actually uses the database. This example is taken from [lkwg82/docker-trss](https://github.com/lkwg82/docker-ttrss/tree/8581ca27e780af2cb1bf0f4673b329f37d52b23c), 
here you can checkout and test it yourself (commit #8581ca2). 

`test/docker-compose.yml`
```yaml
version: "2"

services:
 ttrss:
  image: test-ttrss
  restart: always
  links:
   - db:db
  environment:
   DB_ENV_USER: root
   DB_ENV_PASS: rootpass
   DB_HOST: db
   DB_PORT: 3306
   DB_TYPE: mysql

 db:
  image: mariadb:10.1
  environment:
   MYSQL_DATABASE: ttrss
   MYSQL_ROOT_PASSWORD: rootpass
   MYSQL_USER: user
   MYSQL_PASSWORD: userpass

```


`test/test.sh`
```bash
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



```
I admit any test with sleeps inside is worth inspecting and mostly due to poor design. 
At this point I make a tradeoff after 2hrs reading about :(. 

output
```bash
$ ./test.sh 
Sending build context to Docker daemon 23.55 kB
Step 1/18 : FROM ubuntu:14.04
 ---> b969ab9f929b
...
Successfully built d37df1479d4a
test_db_1 is up-to-date
test_db_1 is up-to-date
test_ttrss_1 is up-to-date
+ docker-compose exec ttrss curl --fail -v http://localhost:8080/
+ grep '^< HTTP/1.1 200 OK'
< HTTP/1.1 200 OK
+ docker-compose exec ttrss curl --fail -v http://localhost:8080/
+ grep '^< Set-Cookie: ttrss_sid=deleted'
< Set-Cookie: ttrss_sid=deleted; expires=Thu, 01-Jan-1970 00:00:01 GMT; Max-Age=0; path=/
+ set +x
cleanup 
-------
Test: SUCCESS
```

----

I know tooling around would make some aspects more convinient, but at least *start testing dockerfiles*!

Feedback is welcome - of course!
