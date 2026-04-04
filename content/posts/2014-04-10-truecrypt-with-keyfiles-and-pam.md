---
title: "Truecrypt mit Keyfiles und pam_exec automatisch mounten"
date: 2014-04-10T21:23:07Z
lastmod: 2014-04-10T21:23:07Z
draft: false
tags: ["privacy" , "security"]
---

Nachdem ich in im letzten [Artikel](/posts/2014-04-06-hibernate-and-resume-with-dm-crypt/) kurz beschrieben habe, warum ich mich für [truecrypt] `http://ww.truecrypt.org` entschieden habe, möchte ich nun kurz zeigen, wie man mit Hilfe von [pam_exec](https://web.archive.org/web/20140226152417/http://www.linux-pam.org/Linux-PAM-html/sag-pam_exec.html) verschlüsselte Datenträger mit [Schlüsseldateien] `http://www.truecrypt.org/docs/keyfiles` einbindet.

Mein System is effektiv hat nur einen menschlichen Nutzer, daher wird im Folgenden nicht nach unterschiedlichen Nutzern unterschieden.

## Ziel

Eine Zeile pro Datenträger der mit einer Schlüsseldatei mit Hilfe von `pam_exec` gemountet wird.

```bash
session    optional        pam_exec.so ...
```

Die Integration mit `pam_mount` habe ich nicht in Betracht gezogen, weil mir keine Möglichkeit zum sicheren Identifizieren der Festplatten (siehe unten) ersichtlich war.

## Vorgehensweise

1. [Verschlüsseln der Datenträger](#enc)
2. [Identifizieren der Datenträger](#id)
3. [Einbindung mit pam_exec](#pam)
4. [Tipps zum Debugging](#debug)

---

## 1. Verschlüsseln des Datenträgers {#enc}

Hier verweise ich auf Truecrypt im [ArchLinux Wiki](https://wiki.archlinux.de/title/TrueCrypt) oder man nimmt einfach die GUI.

## 2. Identifizieren der Datenträger {#id}

Mittels `blkid` erscheinen die verschlüsselten Datenträger leider nicht auf. Also muss man sie anders ermitteln. Da ich eine 2TB und eine 3TB Festplatte habe, musste ich [`gdisk`](http://wiki.ubuntuusers.de/gdisk) (f**disk** für **G**PT) verwenden.

Weil ich gemischte Partitionstabellen habe (nach alter und neuer Bauart), sind die Identifizierungsnummern der Festplatten mit alter Partitionstablle mit `gdisk` bei aufeinanderfolgenden Aufrufen nicht identisch:

```bash
# erster Aufruf
gdisk -l /dev/sdc | grep "^Disk identifier" | cut -d\   -f4
1DA8415E-997C-4264-8037-C159FEF26AAD

# zweiter Aufruf
gdisk -l /dev/sdc | grep "^Disk identifier" | cut -d\   -f4
A7A3912B-DE0F-4B0A-A6E3-A06DF8E4EDE7

# dritter Aufruf
gdisk -l /dev/sdc | grep "^Disk identifier" | cut -d\   -f4
D16AB7A6-B045-4398-84C2-1236EF6111E1

...
```

Da ich nicht schon wieder die ganzen Daten kopieren wollte, musste ein Workaround her. Ich habe mich dann an die Seriennummern von Festplatten erinnert und mit `hdparm` ermitteln können:

```bash
hdparm -i /dev/sdc | grep SerialNo | cut -d= -f4
6XW139KA
```

## 3. Einbindung mit pam_exec {#pam}

Nun noch die Integration mit `PAM`.

Hierzu bitte ins Verzeichnis `/etc/pam.d` wechseln und die Datei `login` öffnen. Dort sehen wir, dass auf `common-session` verwiesen wird:

```bash
...
# Standard Un*x account and session
@include common-account
@include common-session
@include common-password
...
```

Dort stand bei mir bisher:

```bash
...
session required        pam_unix.so
session optional        pam_winbind.so
session optional        pam_mount.so    debug
session optional        pam_systemd.so
session optional        pam_ecryptfs.so unwrap
session optional        pam_ck_connector.so nox11
```

> **Warnung:** Bitte `pam_exec` nur als **optional** konfigurieren. Denn sollte etwas beim Anmelden schief gehen, würde man sich eventuell aussperren.

Das sieht dann so aus:

```bash
...

session optional        pam_ecryptfs.so unwrap
session optional        pam_ck_connector.so nox11

session optional        pam_exec.so     <parameter>
```

Aus Gründen der Darstellung liste ich `<parameter>` hier separat auf:

- `debug` - allg. Flag für das Logging
- `log=/var/log/pam_exec.log` - Skriptausgaben in diese Datei
- `mountTruecryptByGUID.sh` - Skript zum Mounten (siehe unten)
- `backup_disk.key` - Schlüsseldatei
- `Z1F1LF69` - Seriennummer der Festplatte
- `1` - Partitionsnummer z.B `/dev/sda**1**`
- `/backup` - Mountpoint

Alle Pfade sollten natürlich absolut sein ;).

Das Skript dazu sieht dann wie folgt aus:

```bash
#!/bin/bash

set -e
#set -x

if [ $# -ne 4 ]
then
  echo "Usage: `basename $0` <keyfile> <serialNo> <partition-nr> <mountpoint>"
  echo
  echo "serialNo can be retrieved from 'hdparm -i /dev/sda' "
  exit 1
fi

keyfile=$1
serialNo=$2
partition=$3
mountpoint=$4

if [ -z "$PAM_TYPE" ]; then
        echo "INFO running outside of pam"
else
        if [ "$PAM_TYPE" == "close_session" ]; then
                echo "INFO skipping mounting (closing session)"
                exit 0
        fi
fi

function _mount(){
        local keyfile=$1
        local device=$2
        local mountpoint=$3

        /usr/bin/truecrypt --text --protect-hidden=no --non-interactive --keyfiles=$keyfile $device $mountpoint
}

for device in $(fdisk -l 2>/dev/null| grep ^Disk | sed -e 's#Disk\ \(.*\?\):.*#\1#g'| xargs );
do
        serial=$(hdparm -i $device 2>/dev/null| grep SerialNo | cut -d= -f4)

        if [ "$serial" == "$serialNo" ];
        then
                echo "$device $serial"

                # skip if already mounted
                truecrypt --text -l | cut -d\  -f2 | grep $device$partition > /dev/null || \
                        _mount $keyfile $device$partition $mountpoint
        fi
done
```

Geschafft!

## 4. Tipps zum Debugging {#debug}

- das `debug` Flag in der Konfiguration
- mit dem Schalter `set -x` im Skript kann man beim Anmelden in jeder Konsole mit `sudo su <Nutzername>` das Skript testen

