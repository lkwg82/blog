---
title: "Hot swap classes in spring-boot with springloaded"
date: 2015-02-17T10:23:07Z
lastmod: 2015-02-17T13:36:07Z
draft: false
tags: ["intellij", "spring-boot", "springloaded", "java"]
---

Spring-Boot is fast, but changing some controller for prototyping still requires some slow restart cycle of some 5s. With [spring-loaded](https://github.com/spring-projects/spring-loaded) you can shortcut this to 1s, depending of your project. Just hit CTRL-F9 to compile.

[![screenshot from intellij](/img/2015-02-07-spring-loaded-in-intellij.jpeg)](/img/posts/2015-02-07-spring-loaded-in-intellij.jpeg)
 
See also:

- [Hot swapping in the spring boot manual](http://docs.spring.io/spring-boot/docs/current/reference/html/howto-hotswapping.html)
- [spring-loaded on GitHub](https://github.com/spring-projects/spring-loaded)

