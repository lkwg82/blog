---
title: "Isolated web tests in docker"
date: 2015-10-25T21:23:07Z
draft: false
tags: ["docker", "google-chrome","webdriver"]
---
  
This is a simple tutorial to show you how easy it can be to run isolated webtests in docker.

Presumed you want to run your webtests in an isolated environment for the following reasons:

- isolation from other test runs (same ports/same directories/...)
- automatic cleanup of ...
  - orphaned processes (to avoid memory leaks of test agent)
  - cleanup of build files (not filling disk up with temporary files)
- repeatability (of course)

> **Note:** Btw. with *build files* I include the temporary container and images as well. (I just had a bunch of stability tests, which means running tests more than 50 times. I had local memory fuckups twice.)

The examples are taken from [https://github.com/lkwg82/de.lgohlke.selenium-webdriver](https://github.com/lkwg82/de.lgohlke.selenium-webdriver/tree/c18b2933d0dd371469f0a573aac2e097c2e2a310).  
Any mentioned files are saved in the current directory otherwise it is specified.

## Requirements

- docker (I took 1.8)
- ubuntu (I took 15.04)
- maven (just for this example, I took 3.3.3)

## Roadmap

My roadmap in this tutorial:

1. create a script to run the tests (in and outside of docker)
2. create a `Dockerfile`
3. create a script to run docker with tests
4. dont run as root, make it secure
5. bundle some convinient code to live happily with

---

## 1. create a script to run the tests

There should be a script wrapping test commands to be used inside and outside of docker. No special docker test commands!

**File: `run_tests.sh`**

```bash
#!/bin/bash

# just for resolving all dependencies
mvn install -DskipTests

# actual running tests
timeout --preserve-status --kill-after 7m 6m \
    mvn clean verify -P sonar-coverage
```

Line 7 does timout the test run after specified time. I do have in mind a range of time to timeout the complete test run. To make the download of artifact independent line 4 is kept separate.

## 2. Creating the Dockerfile

I prefer to have a `Dockerfile` to build a fresh container for each run. For my example I choose [lkwg82/mitmproxy-0.11-maven3-jdk8](https://hub.docker.com/r/lkwg82/mitmproxy-0.11-maven3-jdk8/~/dockerfile/) (contains maven, jdk8, google-chrome and ...).

```dockerfile
FROM lkwg82/mitmproxy-0.11-maven3-jdk8
```

To run my tests I add the current directory while building the container.

```dockerfile
FROM lkwg82/mitmproxy-0.11-maven3-jdk8

ADD     . /home/build
WORKDIR   /home/build
```

## 3. create a script to run docker

### 3.1 get it run

**File: `run_docker.sh`**

```bash
#!/bin/bash

docker build -t test-$$ . | tee docker_build.log
IMAGE_ID=$(tail -n1 docker_build.log| cut -d\  -f3)
docker run $IMAGE_ID ./run_tests.sh
```

- line 3: build the container and log the output while displaying
- line 3: use a tagname which contains the PID to identify when running in parallel
- line 4: retrieve the image id
- line 5: run the tests in a new container with the retrieved image id

Make some custom adjustments:

**File: `run_docker.sh`**

```bash
#!/bin/bash

DOCKER_USER_TMP="/tmp/docker_$USER"
DOCKER_M2="$DOCKER_USER_TMP/m2"
DOCKER_WEBDRIVER="$DOCKER_USER_TMP/webdriver"

args="--name=webdriver-test-$$ -m 1500M --memory-swap=-1 \
    -v /dev/shm:/dev/shm \
    -v $DOCKER_M2:/home/build/.m2/repository \
    -v $DOCKER_WEBDRIVER:/home/build/tmp_webdrivers "

rm -rf target/*
docker build -t test . | tee docker_build.log
IMAGE_ID=$(tail -n1 docker_build.log| cut -d\  -f3)
docker run $args $IMAGE_ID ./run_tests.sh
```

- line 4: reuse the maven repository over many runs
- line 5: reuse special temp directory over many runs
- line 12: clean `target/` before adding to the new image

### 3.2 let it cleanup after run, dont mess with y disk space

**File: `run_docker.sh`**

```bash
#!/bin/bash

DOCKER_USER_TMP="/tmp/docker_$USER"
DOCKER_M2="$DOCKER_USER_TMP/m2"
DOCKER_WEBDRIVER="$DOCKER_USER_TMP/webdriver"

args="--name=webdriver-test-$$ -m 1500M --memory-swap=-1 \
    -v /dev/shm:/dev/shm \
    -v $DOCKER_M2:/home/build/.m2/repository \
    -v $DOCKER_WEBDRIVER:/home/build/tmp_webdrivers "

rm -rf target/*
docker build -t test . | tee docker_build.log
IMAGE_ID=$(tail -n1 docker_build.log| cut -d\  -f3)
CONTAINER_ID=$(docker run -d $args $IMAGE_ID bash -c 'while true; do sleep 10000; done')

echo -n $IMAGE_ID > docker_IMAGE_ID
echo -n $CONTAINER_ID > docker_CID

function cleanup {
  ./run_docker_cleanup.sh
}
trap cleanup EXIT INT

docker exec $CONTAINER_ID ./run_tests.sh
```

- line 15: we need a main loop to keep the container running
- line 15: keep the `$CONTAINER_ID` in memory
- line 17-18: save ids to be used from outside this script
- line 20: create function to call a cleanup script
- line 23: register this cleanup function to be called on EXIT and CTRL-C (see [traps](http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html))
- line 25: execute the tests

**File: `run_docker_cleanup.sh`**

```bash
#!/bin/bash

CONTAINER_ID=$(cat docker_CID)
IMAGE_ID=$(cat docker_IMAGE_ID)

# cleanup instances
docker kill  $CONTAINER_ID
docker rm -f $CONTAINER_ID
docker rmi   $IMAGE_ID
```

- line 7-9: kill and remove the container and remove the specified iamge

## 4. dont run as root, make it secure

**File: `run_docker.sh`**

```bash
#!/bin/bash

DOCKER_USER_TMP="/tmp/docker_$USER"
DOCKER_M2="$DOCKER_USER_TMP/m2"
DOCKER_WEBDRIVER="$DOCKER_USER_TMP/webdriver"

mkdir -p $DOCKER_M2           # create the directory before
mkdir -p $DOCKER_WEBDRIVER    # to have the correct ownership

args="--name=webdriver-test-$$ -m 1500M --memory-swap=-1 \
    -v /dev/shm:/dev/shm \
    -v $DOCKER_M2:/home/build/.m2/repository \
    -v $DOCKER_WEBDRIVER:/home/build/tmp_webdrivers "

rm -rf target/*
docker build -t test-$$ . | tee docker_build.log
IMAGE_ID=$(tail -n1 docker_build.log| cut -d\  -f3)
CONTAINER_ID=$(docker run -d $args $IMAGE_ID bash -c 'while true; do sleep 10000; done')

echo -n $IMAGE_ID > docker_IMAGE_ID
echo -n $CONTAINER_ID > docker_CID

function cleanup {
  ./run_docker_cleanup.sh
}
trap cleanup EXIT INT

UID_OUTSIDE=$(id --user)
GID_OUTSIDE=$(id --group)
USER_INSIDE_DOCKER="build"

docker exec $CONTAINER_ID useradd --uid $UID_OUTSIDE $USER_INSIDE_DOCKER
docker exec $CONTAINER_ID chown -R $USER_INSIDE_DOCKER .
docker exec $CONTAINER_ID su $USER_INSIDE_DOCKER -c './run_tests.sh'
```

- line 7-8: create the shared directories as user which runs the tests
- line 32: create an user with the same uid and gid inside the container as you have outside (this fixes the user id mapping problem)
- line 33: remember you added the project as root (you dont set any user), so change the ownership to the new user
- line 34: run the tests with the new user

## 5. make it convinient, make the user happy

### 5.1 Where is my build containing the logs?

**File: `run_docker_cleanup.sh`**

```bash
#!/bin/bash

CONTAINER_ID=$(cat docker_CID)
IMAGE_ID=$(cat docker_IMAGE_ID)

rm -rf target
docker cp $CONTAINER_ID:/home/build/target .

# cleanup instances
docker kill  $CONTAINER_ID
docker rm -f $CONTAINER_ID
docker rmi   $IMAGE_ID
```

- line 6: clear the local `target/` directory before filling with copies from container
- line 7: copy the build files

### 5.2 Which software environment I ran the tests with?

**File: `Dockerfile`**

```dockerfile
FROM lkwg82/mitmproxy-0.11-maven3-jdk8

ADD     . /home/build
WORKDIR   /home/build
RUN dpkg --list | grep ^ii > installed_software.log
```

- line 5: save the installed package list

the list looks like

```bash
ii  acl            2.2.52-2     amd64        Access control list utilities
ii  adduser        3.113+nmu3   all          add and remove users and groups
ii  apt            1.0.9.8.1    amd64        commandline package manager
ii  base-files     8+deb8u2     amd64        Debian base system miscellaneous files
ii  base-passwd    3.5.37       amd64        Debian base system master password and group files
ii  bash           4.3-11+b1    amd64        GNU Bourne Again SHell
...
```

Dont forget to copy the list from the container.

**File: `run_docker_cleanup.sh`**

```bash
#!/bin/bash

CONTAINER_ID=$(cat docker_CID)
IMAGE_ID=$(cat docker_IMAGE_ID)

rm -rf target
docker cp $CONTAINER_ID:/home/build/target .
docker cp $CONTAINER_ID:/home/build/installed_software.log target

# cleanup instances
docker kill  $CONTAINER_ID
docker rm -f $CONTAINER_ID
docker rmi   $IMAGE_ID
```

- line 8: copy the package list

### 5.3 Do I have any issues in docker with the limits?

If you ever experienced issues with flaky tests, read on!

**File: `run_docker_cleanup.sh`**

```bash
#!/bin/bash

CONTAINER_ID=$(cat docker_CID)
IMAGE_ID=$(cat docker_IMAGE_ID)

rm -rf target
docker cp $CONTAINER_ID:/home/build/target .
docker cp $CONTAINER_ID:/home/build/installed_software.log target

# check for issues (low memory etc.)
if [ $(dmesg -T | grep docker-$CONTAINER_ID | wc -l) -gt 0 ]; then
    echo "";
    echo "[ERROR] there were issues with $CONTAINER_ID:";
    echo "";
    dmesg -T | grep docker-$CONTAINER_ID
    echo "--"
    echo "host config looks like (reduced)"
    docker inspect --format="{{json .HostConfig}}" $CONTAINER_ID | python -m json.tool \
        | grep -v ": \"\"" \
        | grep -v ": null" \
        | grep -vE ": 0|-1" \
        | grep -v ": \[\]" \
        | grep -v ": {}"

    exit 137
fi

# cleanup instances
docker kill  $CONTAINER_ID
docker rm -f $CONTAINER_ID
docker rmi   $IMAGE_ID
```

- line 10-26: add a check and let the build fail

For more details read [this separate post](/memory/docker/2015/10/24/detect-when-docker-instance-reached-memory-limit.html) on this issue.

---

I appreciate any feedback/corrections and comments.

