---
title: "EncFS --reverse"
date: 2013-02-17T22:42:00Z
lastmod: 2013-02-17T22:42:00Z
draft: false
tags: ["backup", "rsync", "server", "encfs", "encryption"]
---

Gerade habe ich in der Manpage von EncFS eine sehr schöne Lösung für ein sicheres Backup in der Cloud gefunden.

Encfs ist ein Dateisystem im Userspace und bietet eine Sicht auf Verzeichnisse an. Ursprünglich ging es darum verschlüsselte Verzeichnisse entschlüsselt anzuzeigen. Der *Reverse* Modus bietet genau den umgekehrten Weg an. Somit können beliebige (unverschlüsselte) Verzeichnisse mittels `EncFs` als verschlüsselte Verzeichnisse angezeigt werden.

"Wow. Wtf?" Werden sich gerade einige fragen. Aber mit dieser umgekehrten Sicht, kann man einfach mit einem Synchronisationswerkzeug das Ganze an syncronisieren. "Wow!"

Ich verweise einfach nur auf den Artikel: [Daten sicher in der Synchro-Wolke dank encfs](http://dbudwm.wordpress.com/tag/encfs/).

Habe leider keine Ahnung, ob dieser Modus auch für Mac bzw. auch für Windows via dokan verfügbar ist. :|

P.S. Python WrapperSkript [encfs –reverse + rsync = encrb](http://blog.fealdia.org/2012/12/06/encfs-reverse-rsync-encrb/)

