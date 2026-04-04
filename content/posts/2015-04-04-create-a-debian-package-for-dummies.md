---
title: "Short debian package guide for dummies"
date: 2015-04-07T21:23:07Z
lastmod: 2015-04-07T13:36:07Z
draft: false
tags: ["ubuntu", "debian", "packaging"]
---


As I always struggle with creating a debian so I decided to write the few steps down. Finally. This is more a kind of cheat sheet than a comprehensive guide.  
In my example I will package [h2o](https://github.com/h2o/h2o) a very fast http/2 static file server capable to run as reverse proxy.

This is my environment:

```bash
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 14.04.2 LTS
Release:	14.04
Codename:	trusty
```

## 1. creating the basic structure

clone repository and change to newly created branch

```bash
$ git clone git@github.com:lkwg82/h2o.git
$ git checkout tags/v1.1.1
$ git branch debian
$ git checkout debian
$ git branch --track origin/master
```
 
create the debian structure as directory `debian/`.

```bash
$ export DEBEMAIL=lkwg82@gmx.de
$ export DEBFULLNAME="Lars K.W. Gohlke"
$ dh_make --single -p h2o-server_1.1.1 --createorig -y
```

> **Note:** `DEBEMAIL` and `DEBFULLNAME` should be the same as in your gpg keys, which you are using to sign the package.

Now fill the generated files under `debian/` (control/changelog) and check with `lintian` until there are no more errors. Commit all changes!

```bash
$ lintian
Too late to run INIT block at /usr/local/lib/perl/5.18.2/Net/DNS.pm line 213.
W: h2o-server source: native-package-with-dash-version
W: h2o-server source: package-needs-versioned-debhelper-build-depends 9
W: h2o-server source: vcs-field-uses-unknown-uri-format vcs-git git@github.com:h2o/h2o.git
W: h2o-server source: syntax-error-in-dep5-copyright line 11: Continuation line outside a paragraph (maybe line 10 should be " .").
W: h2o-server source: out-of-date-standards-version 3.9.4 (current is 3.9.5)
W: h2o-server source: debian-watch-file-in-native-package
```

### about preparation for publishing

I publish my packages on [launchpad](https://launchpad.net/~lkwg82). For this I recommend to make sure every needed [build dependency](https://www.debian.org/doc/debian-policy/ch-relationships.html) is met.

I struggled with [pbuilder] `http://pbuilder.alioth.debian.org/` so I chose [docker](http://www.docker.com) to have a clean build environment. For this I wrote [docker-debian-build-env](https://github.com/lkwg82/docker-debian-build-env).

A single command runs a clean ubuntu instance and build everything:

```bash
$ docker_debian_build_all
```

If you struggle with both ... loop until no errors left.

## 2. Finish

Finish your (initial) changes with these steps:

Build a binary package:

```bash
$ dpkg-buildpackage -tc -B
```

or build a source package for publishing on launchpad:

```bash
$ git-dch --release --git-author --commit --id-length=10 --distribution=trusty --debian-branch=debian
$ git-buildpackage -S -sa --git-tag --git-sign-tags --git-no-create-orig --git-debian-branch=debian
```

In both cases the result is in the parent directory.

## 3. Publish!

Share your package with the community. Make a pull request to the original authors and let everyone know you packaged that software for easy use (hopfully).

```bash
$ dput ppa:lkwg82/webperformance ../h2o-server_1.1.1-2_source.changes
```

My result is here [ppa:lkwg82/webperformance](https://launchpad.net/~lkwg82/+archive/ubuntu/webperformance).

Feedback is welcome!

---

### Links

- [automatically install build dependencies](https://www.v13.gr/blog/?p=364)
- [ubuntu packaging guide](http://packaging.ubuntu.com/html/)
- [launchpad uploading a package](https://help.launchpad.net/Packaging/PPA/Uploading)

