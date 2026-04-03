---
title: "Vncserver nur von lokal erreichbar starten"
date: 2013-04-01T14:54:55Z
lastmod: 2013-04-01T14:54:55Z
draft: false
tags: ["vnc", "linux", "security"]
---

```bash
$ vncserver :1 -depth 8 -geometry 1600x900 -localhost -nolisten tcp
```

prüfen mit

```bash
$ netstat -tulpen | grep vnc
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
tcp        0      0 127.0.0.1:5901          0.0.0.0:*               LISTEN      1000       19697       11916/Xtightvnc
```

