---
title: "Packaged DSSIM Implementation of pornel"
date: 2015-03-21T10:23:07Z
lastmod: 2015-03-21T13:36:07Z
draft: false
tags: ["ubuntu", "debian", "dssim", "ssim"]
---

I just packaged [dssim](https://github.com/pornel/dssim) for ubuntu. So for now it can easily installed and removed as plain deb file.

To install just type: 

```bash
$ sudo apt-add-repository ppa:lkwg82/dssim
$ sudo apt-get update
$ sudo apt-get install dssim
```

Currently it is only available for ubuntu [trusty](https://launchpad.net/~lkwg82/+archive/ubuntu/dssim/+packages) (14.04 LTS). On request I'll make it for other versions as well.

