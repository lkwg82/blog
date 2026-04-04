---
title: "Sicheres und einfaches Backup mit Encfs in die Cloud"
date: 2013-04-08T21:53:04Z
lastmod: 2013-04-08T21:53:04Z
draft: false
tags: ["encfs", "backup", "cloud", "security"]
---

Wie in [encfs --reverse](/posts/2013-02-17-encfs---reverse/) schon angekündigt, stellt [encfs](https://web.archive.org/web/20130126125752/http://www.arg0.net/encfs) eine einfache praktikable Lösung bereit, Klartext-Verzeichnisse on-the-fly als verschlüsselte Verzeichnisse zu mounten.

## Übersicht

Dazu bedarf es nur weniger Zeilen (1) und der Information zur Verschlüsselung im Klartextverzeichnis (2)

1. ```bash
   encfs --reverse clear-text-directory directory-to-show-as-encrypted
   ```

2. ```bash
   $ ls -al
   insgesamt 2768
   drwxr-xr-x 10 lars lars    4096 Mär 15 15:18 .
   drwxr-xr-x  3 lars lars    4096 Dez 17 23:46 ..
   ...
   -rw-r--r--  1 lars lars    1090 Feb 13 10:39 .encfs6.xml
   ...
   ```

Die Datei aus (2) bekommt man durch den klassischen Weg (Anlegen eines verschlüsselten Verzeichnisses)

```bash
encfs clear-text-directory directory-to-show-as-encrypted
...
```

Das Ganze mal in ein Skript verpackt, welches aus dem aktuellsten [backintime](http://wiki.ubuntuusers.de/Back_In_Time) Verzeichnis meine Bilder in die Cloud sichert. (Die Cloud ist hier jetzt mein Server ;))

## Praxisbeispiel

Sie sieht die Ausführung aus:

```bash
$ ./bilder_backup.sh
Give pw for encView
EncFS-Passwort:
insgesamt 3,1M
4,0K dr-xr-xr-x 10 lars lars 4,0K Mär 15 15:18 .
328K drwxrwxrwt 21 root root 324K Apr  8 22:20 ..
1,4M -r--r--r-- 14 lars lars 1,3M Sep  9  2012 72EM,II1
4,0K -r--r----- 17 lars lars  407 Jun 26  2006 8HFavTtakwyTC-
4,0K -r--r--r--  8 lars lars 1,1K Feb 13 10:39 cZcEr1j6cPnLRha10,
292K -r--r----- 17 lars lars 292K Jun  7  2005 gbrODCTZU3wCc9JgQsusQz-5
4,0K dr-xr-xr-x  7 lars lars 4,0K Sep  9  2012 Ki4-qaws1mXW
4,0K dr-xr-xr-x 24 lars lars 4,0K Mär 14 17:25 KW,cCDCPQgQA
388K -r--r----- 17 lars lars 386K Jan  2  2005 kykBT6MBxWsN7Rs4usZjBZyOKITWbBC
4,0K dr-xr-x---  3 lars lars 4,0K Nov  9  2009 loVuTdSv6Rcx1vRqzXMMDFaFF-j-32OmZo7
4,0K -r-xr-xr-x 17 lars lars  233 Jun 26  2006 meqPWsFAIhi1
4,0K dr-xr-x---  3 lars lars 4,0K Jan 12  2010 ny8KaOyd0hQ8S0
4,0K dr-xr-x---  2 lars lars 4,0K Okt 23  2009 teUPxPhzK3bXr1
4,0K dr-xr-xr-x 12 lars lars 4,0K Sep 15  2010 twep7Wbbb1uN
4,0K dr-x------  8 lars lars 4,0K Okt 21 15:19 v4ZC-SmXGf3
352K -r--r----- 17 lars lars 351K Apr  3  2005 XL7z8lqo0OqMpZlx91
4,0K dr-xr-xr-x  7 lars lars 4,0K Apr  9  2008 xP-CpRIY9YcqybC,HOLNkWqW
352K -r--r----- 17 lars lars 351K Aug 30  2006 xqI6SUadWF9PR-556ChJF6-VWVM0eCB
building file list ...
20080 files to consider
Ki4-qaws1mXW/wNovM37-LeKdn00/ErfqKTMMk4r0dFPCqxGX-sv9fLNX/
Ki4-qaws1mXW/wNovM37-LeKdn00/ErfqKTMMk4r0dFPCqxGX-sv9fLNX/hz0wj1FP6JLTDeC/
Ki4-qaws1mXW/wNovM37-LeKdn00/ErfqKTMMk4r0dFPCqxGX-sv9fLNX/hz0wj1FP6JLTDeC/2sTxd26gZ1fkEACTyEkga3KuEGGm4m2UElmRF5knNre1YZyutl2nKsf,VwEuYX8
         262 100%    0.00kB/s    0:00:00 (xfer#1, to-check=11491/20080)

Number of files: 20080
Number of files transferred: 1
Total file size: 96218876503 bytes
Total transferred file size: 262 bytes
Literal data: 262 bytes
Matched data: 0 bytes
File list size: 687638
File list generation time: 3.391 seconds
File list transfer time: 0.000 seconds
Total bytes sent: 687964
Total bytes received: 41

sent 687964 bytes  received 41 bytes  65524.29 bytes/sec
total size is 96218876503  speedup is 139852.00
```

und so das Skript dazu:

```bash
#!/bin/bash

set -e
#set -x

pathToImages=home/lars/remote/lars/volume_i/bilder/
lastBackup=$(find /backup/backintime/lars-G33-DS3R/lars/1 -maxdepth 1 -type d |  sort -n | tail -n1)

path=$lastBackup/backup/$pathToImages

pathToEncView=$(tempfile).d
mkdir $pathToEncView

echo Give pw for encView
encfs --reverse $path $pathToEncView

ls -alsh $pathToEncView

continue=1
while( [ $continue == 1 ] );
do
        rsync -v --stats --progress -e ssh  --partial --archive --delete-after --log-file=log  $pathToEncView/* wirt2.lgohlke.de:/backup/uploaded/Bilder/.backend && continue=0 || sleep 1
done


sudo umount $pathToEncView
rmdir $pathToEncView
```

Das Skript mounted die Sicht auf das verschlüsselte Verzeichnis in ein temporäres Verzeichnis (Zeile 11) und löscht dieses wieder (Zeile 27).

Das Hochladen der Bilder erfolgt über rsync+ssh und wird so lange wiederholt, bis das Backup erfolgreich war und nicht zwischendurch abgebrochen ist.

## Fazit

1. Mit ausreichender Verschlüsselung sind die Daten sicher!
2. Damit kann nun auch Dropbox o.ä. genutzt werden. Dorthinein mounten und hochladen lassen.

