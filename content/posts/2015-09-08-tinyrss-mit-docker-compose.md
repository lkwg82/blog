---
title: "Tiny Tiny RSS setup with docker-compose in 2 minutes"
subtitle: "a single command setup for tiny tiny rss"
date: 2015-09-05T21:23:07Z
lastmod: 2015-09-05T13:36:07Z
draft: false
tags: ["docker-compose"]
---

How can I setup and run my own [tt-rss](https://tt-rss.org/) instance with [docker-compose](https://docs.docker.com/compose/) within 2 minutes?

## TL;DR

```bash
# preparation
$ sudo apt-get install python-pip git curl
# see https://docs.docker.com/installation/ubuntulinux/
$ curl -sSL https://get.docker.com/ | sh
$ sudo pip install docker-compose

# installation
$ git clone https://github.com/lkwg82/blog.git blog
$ cd blog/examples/20150908_tinytinyrss_docker-compose
$ ./run.sh

# usage
$ firefox http://localhost:9108/
```

---

Here comes the little longer story ... not much longer ... only more prose.

## Intro

This example is about installing [tt-rss](https://tt-rss.org/) from scratch with its requires database server (I took postgres) with docker and docker-compose.

## Why?

I like to have some easy reproducible installation procedures for wanna-be-complex setups. I took [docker](http://docker.com) as my favourite virtualization technique.

## What is ...?

- **[tt-rss](https://tt-rss.org/)**: it is an open source web based rss feed reader similiar to former google reader.
- **[docker](http://docker.com)**: *Docker containers wrap up a piece of software in a complete filesystem that contains everything it needs to run: code, runtime, system tools, system libraries – anything you can install on a server. This guarantees that it will always run the same, regardless of the environment it is running in.* (cite from [here](https://www.docker.com/whatisdocker))
- **[docker-compose](https://docs.docker.com/compose/)**: *Compose is a tool for defining and running multi-container applications with Docker. With Compose, you define a multi-container application in a single file, then spin your application up in a single command which does everything that needs to be done to get it running.* (cite from [here](https://docs.docker.com/compose/)).

## how?

(I explain here only the `./run.sh` context from **TL:DR**)

create a file called `docker-compose.yml`

```yaml
# https://hub.docker.com/_/postgres/
pgdb:
   container_name: pgdb
   image: postgres
   environment:
       - POSTGRES_PASSWORD=mysecretpassword
       - PGDATA=/pgdata
   volumes:
       - ./volumes/pgdb_pgdata:/pgdata

ttrss:
   container_name: ttrss
   build: setup_data
   links:
      - pgdb:db
   volumes:
      - ./tt-rss_:/var/www/html:rw
   ports:
      - 9108:80
```

- **line 2 and 11**: two services called `pgdb` (postgres database) and `ttrss` (feed reader), can be later called from `docker-compose` separatly
- **line 3**: docker container name is pgdb
- **line 4**: service bases on docker image pgdb(:latest)
- **line 8**: saves the database outside in the local directory `./volumes/pgdb_pgdata` and mounts into container under `/pgdata`
- **line 13**: looks for a `Dockerfile` in the directory named `setup_data`
- **line 14**: links container `pgdb` with alias `db`, so inside of this container the database is addressable via `db`, (imagine a call of `ping db`)
- **line 19:** exposes container port 80 to local 9108 (http://localhost:9108 should get the reader)

Build the setup with `docker-compose build` from the directory where the `docker-compose.yml` is. First it will build the `pgdb` container and then the `ttrss`. After they are built call `docker-compose up`. (For this setup watch the `run.sh`! There are some additional setup calls.)

**Disclaimer 1:** For simplicity reasons I deployed the db ... no I let it to you, to find this little nasty thing ;).  
**Disclaimer 2:** Maybe the downloads take longer than while my tests.

