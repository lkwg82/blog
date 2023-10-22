---
layout: post
title: automatic secure backup on usb with Luks/Udev 
subtitle: Tutorial how to automatically backup on an encrypted usb device
date: 2023-10-08 15:27:34 CET 
comments: true
categories: udev luks linux backup
---

The goal is to automatically mount a specific encrypted usb device on plugin, run a backup and umount it.

## Minor goals

1. simple and use standard linux tooling
2. do not break security
3. interactive, give user feedback
4. robust to interuptions

## Prerequisites

have a spare usb device

## Steps

### 1. Prepare the usb device

Encrypt the device with [luks](https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup).

Assume our device is `/dev/sde`.

```bash
DEVICE=/dev/sde
```

Encrypt the device with a keyfile for automatic usage and a passphrase as backup.
You will be asked for a passphrase.
```bash
cryptsetup luksFormat $DEVICE --batch-mode
```

Create keyfile to use for automation.
```bash
dd if=/dev/urandom bs=1M count=1 of=/root/usb-disk.key
```

Add the keyfile as another key.
```bash
cryptsetup luksAddKey $DEVICE /root/usb-disk.key
```

Verify we have both keys added.
```bash
cryptsetup luksDump $DEVICE
```

output
```bash
LUKS header information
Version:       	2
Epoch:         	4
Metadata area: 	16384 [bytes]
Keyslots area: 	16744448 [bytes]
UUID:          	6255866d-a3c0-466f-9d39-4f2d8084f4be
Label:         	(no label)
Subsystem:     	(no subsystem)
Flags:       	(no flags)

Data segments:
  0: crypt
	offset: 16777216 [bytes]
	length: (whole device)
	cipher: aes-xts-plain64
	sector: 512 [bytes]

Keyslots:
  0: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  6
	Memory:     1048576
	Threads:    4
	Salt:       af 65 1c fd 11 17 fd 7f d6 cd 29 8f 33 fb 5e 70
	            ce 5d 80 83 6c 0a e7 30 a5 ee e1 2f ef 59 4d 62
	AF stripes: 4000
	AF hash:    sha256
	Area offset:32768 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
  1: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  6
	Memory:     1048576
	Threads:    4
	Salt:       9f 38 55 d1 68 4f b1 bb 01 22 53 3c 8f 5b 58 15
	            31 86 f5 4a 1c 28 99 9f 10 0f ce 76 44 e4 d8 99
	AF stripes: 4000
	AF hash:    sha256
	Area offset:290816 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
Tokens:
Digests:
  0: pbkdf2
	Hash:       sha256
	Iterations: 125788
	Salt:       58 d4 83 62 fd f1 26 4f a5 59 c2 29 6e a8 c9 c2
	            51 5a 0b 9c 36 59 36 24 19 f1 a4 37 a0 33 47 56
	Digest:     a2 c4 fb 1b 76 49 2d e2 aa 52 ea 45 c8 db 26 6b
	            90 7f 61 df 75 91 9c 4f fc 90 03 c8 7d 4a 4c c6
```

Note the device is encrypted but lacks a filesystem.

Test it with open the device and format with `btrfs`.

open
```bash
cryptsetup luksOpen /dev/sde usb-crypted
```

format
```bash
# mkfs.btrfs /dev/mapper/usb-crypted
btrfs-progs v6.2
See http://btrfs.wiki.kernel.org for more information.

NOTE: several default settings have changed in version 5.15, please make sure
      this does not affect your deployments:
      - DUP for metadata (-m dup)
      - enabled no-holes (-O no-holes)
      - enabled free-space-tree (-R free-space-tree)

Label:              (null)
UUID:               7eb962dd-7327-4df8-b768-4f6da64d6d2a
Node size:          16384
Sector size:        4096
Filesystem size:    3.72GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP             256.00MiB
  System:           DUP               8.00MiB
SSD detected:       no
Zoned device:       no
Incompat features:  extref, skinny-metadata, no-holes
Runtime features:   free-space-tree
Checksum:           crc32c
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1     3.72GiB  /dev/mapper/usb-crypted
```

Close it
```bash
cryptsetup close /dev/mapper/usb-crypted
```


---

### 2. Automatic open the device on plugin

Use udev subsystem ([manpage](https://www.linux.org/docs/man7/udev.html), [intro](https://opensource.com/article/18/11/udev))
to detect and react on events when the usb device is plugged in.

Now we need an identifier to recognize as our usb device. Lets use `dmesg -w` to watch the kernel log, while we plug it in.

```bash
[ 3006.861777] dm-10: detected capacity change from 7811072 to 0
[ 4237.103497] BTRFS: device fsid 7eb962dd-7327-4df8-b768-4f6da64d6d2a devid 1 transid 6 /dev/mapper/usb-crypted scanned by mkfs.btrfs (43170)
[ 4387.501296] dm-10: detected capacity change from 7811072 to 0
[ 4775.969525] usb 5-2: USB disconnect, device number 3
[ 4778.488544] usb 5-2: new high-speed USB device number 4 using xhci_hcd
[ 4778.738946] usb 5-2: New USB device found, idVendor=058f, idProduct=6387, bcdDevice= 1.00
[ 4778.738960] usb 5-2: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[ 4778.738967] usb 5-2: Product: Mass Storage Device
[ 4778.738972] usb 5-2: Manufacturer: JetFlash
[ 4778.738977] usb 5-2: SerialNumber: xxxx
[ 4778.744252] usb-storage 5-2:1.0: USB Mass Storage device detected
[ 4778.744440] scsi host8: usb-storage 5-2:1.0
[ 4779.761711] scsi 8:0:0:0: Direct-Access     JetFlash Transcend 4GB    8.07 PQ: 0 ANSI: 2
[ 4779.762345] sd 8:0:0:0: Attached scsi generic sg4 type 0
[ 4779.763019] sd 8:0:0:0: [sde] 7843840 512-byte logical blocks: (4.02 GB/3.74 GiB)
[ 4779.763185] sd 8:0:0:0: [sde] Write Protect is off
[ 4779.763190] sd 8:0:0:0: [sde] Mode Sense: 03 00 00 00
[ 4779.763351] sd 8:0:0:0: [sde] No Caching mode page found
[ 4779.763355] sd 8:0:0:0: [sde] Assuming drive cache: write through
[ 4779.791386] sd 8:0:0:0: [sde] Attached SCSI removable disk
```

Here we see this line
```bash

[ 4778.738946] usb 5-2: New USB device found, idVendor=058f, idProduct=6387, bcdDevice= 1.00

```

We need both identifiers `idVendor` and `idProduct` to create a specific rule.


udev rule which runs a script on 'adding' the device to the system
```bash
{% include /20231008-automaticbackup/etc/udev/rules.d/99-my-usb-rule.rules %}
```

reload udev (to activate changes to the rule)
```bash
udevadm control --reload
```
Create script to automatically "open" (make it available for access) the device (needs higher priveleges).

udev rule which runs a script on 'adding' the device to and 'removing' the device from the system
```bash
{% include 20231008-automaticbackup/root/open-close-backup-usb.sh %}
```

Make it executable
```bash
chmod +x /root/open-close-backup-usb.sh
```

Lets watch it in action (unplug it and shortly plug it in).

follow the log file
```bash
tail -F /tmp/*.sh.log
```

output after plugged in
```bash
````````````--- Sat Oct  7 14:42:04 CEST 2023 ````````````--
test
usb-crypted
already opened ... closing
opening
opened
/dev/mapper/usb-crypted is active.
  type:    LUKS2
  cipher:  aes-xts-plain64
  keysize: 512 bits
  key location: keyring
  device:  /dev/sdf
  sector size:  512
  offset:  32768 sectors
  size:    7811072 sectors
  mode:    read/write
````````````--- Sat Oct  7 14:42:08 CEST 2023 ````````````--
```

### 3. mount it and run backup

Udev cant be used to mount devices (because of security - details left out here).
So we need something to detect a new device like [incron](https://wiki.ubuntuusers.de/Incron).

check it is running
```bash
# systemctl status incron
● incron.service - file system events scheduler
     Loaded: loaded (/lib/systemd/system/incron.service; enabled; preset: enabled)
     Active: active (running) since Sat 2023-10-07 13:04:26 CEST; 1h 47min ago
       Docs: man:incrond(8)
   Main PID: 2248 (incrond)
      Tasks: 1 (limit: 18883)
     Memory: 864.0K
        CPU: 28ms
     CGroup: /system.slice/incron.service
             └─2248 /usr/sbin/incrond
```

Allow our user to add listeners. It is restricted as it can overload the system.

add permission
```bash
echo lars >> /etc/incron.allow
```


Add `sudo` permissions to use `mount` command.
```bash
# cat /etc/sudoers.d/usermount_backup
Cmnd_Alias C_MOUNT = \
  /bin/mount /dev/mapper/usb-crypted-* /home/lars/backup-crypted, \
  /bin/umount /home/lars/backup-crypted

lars ALL = (root) NOPASSWD: C_MOUNT
```

check sudoers syntax
```bash
# visudo -c
/etc/sudoers: parsed OK

/etc/sudoers.d/usermount_backup: parsed OK

```

Install [incron](https://wiki.archlinux.org/title/Incron). Add this line to `incrontab -e` to listen to file events (based on [inotify](https://www.man7.org/linux/man-pages/man7/inotify.7.html))

Listen in `/dev/mapper` on `IN_MOVED_TO` events and call a script with the filename
```bash
/dev/mapper     IN_MOVED_TO,recursive=false     /home/lars/incron_make_backup.sh  $#
```

The userspace script to `sudo mount ...`, backup and `sudo umount ...`

/home/lars/incron_make_backup.sh
```bash
{% include /20231008-automaticbackup/home/lars/incron_make_backup.sh %}
```
/home/lars/backup-crypted.sh
```bash
{% include /20231008-automaticbackup/home/lars/backup-crypted.sh %}
```
This script will pop up as terminal, window and disappear after a second.

Thats it!

## Debugging

check luks device status
```bash
# cryptsetup status /dev/mapper/usb-crypted
/dev/mapper/usb-crypted is active and is in use.
  type:    n/a
  cipher:  aes-xts-plain64
  keysize: 512 bits
  key location: keyring
  device:  (null)
  sector size:  512
  offset:  32768 sectors
  size:    7811072 sectors
  mode:    read/write
```

udev logging
```bash
udevadm control --log-priority=debug
journalctl  -f -u systemd-udevd # follows the log
udevadm control --log-priority=info # this is default
```

incron logging
```bash
journalctl  -f -u incron
```

Follow the logs while plugin/plugout
```bash
tail -F /tmp/*.sh.log /home/lars/*.sh.log
```



various
```bash
dmsetup remove --force usb-crypted
```

Links:

- [https://wiki.archlinux.org/title/Udev](https://wiki.archlinux.org/title/Udev)
