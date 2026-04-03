---
title: "Undeleting opened files on ext4"
date: 2013-02-09T21:23:07Z
lastmod: 2013-02-09T21:23:07Z
draft: false
tags: ["linux", "ext4", "recovery"]
---
 
Mich lässt das Thema nicht los: Hier nun die kurze Anleitung, wie man gelöschte Dateien wiederherstellt, wenn sie noch von Prozessen geöffnet sind:

1. pid finden
2. filehandle finden: `/proc/<pid>/fd`
3. mit cp dieses filehandle kopieren

Ausführliche Anleitung hier: [http://glandium.org/blog/?p=87](http://glandium.org/blog/?p=87)

