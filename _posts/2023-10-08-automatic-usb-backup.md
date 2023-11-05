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

- have a spare usb device
- have root access

## Steps

1. Prepare the encrypted usb device
2. Setup automounting
3. Setup automatic backup as root with visual feedback for an ordinary user 

### 1. Prepare the encrypted usb device

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
cryptsetup luksOpen $DEVICE usb-crypted
```

format
```bash
root@host:~# mkfs.btrfs /dev/mapper/usb-crypted
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

### 2. Setup automounting

overall plan for automounting:
1. Use udev subsystem ([manpage](https://www.linux.org/docs/man7/udev.html), [intro](https://opensource.com/article/18/11/udev))
   to detect and react on events when the usb device is plugged in.
2. Use [systemd](https://systemd.io) to automount crypted usb device.

#### 2.1 udev tagging


Now we need an identifier to recognize as our usb device. Lets use `dmesg --follow` to watch the kernel log, while we plug it in.

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
...
[ 4778.738946] usb 5-2: New USB device found, idVendor=058f, idProduct=6387, bcdDevice= 1.00
...
```

We need both identifiers `idVendor` and `idProduct` to create a specific rule.

udev rule in `/etc/udev/rules.d/99-my-usb-rule.rules` which tags the device for [systemd.device](https://www.freedesktop.org/software/systemd/man/latest/systemd.device.html)
```bash
KERNEL=="sd*", SUBSYSTEMS=="usb", ATTRS{idVendor}=="058f", ATTRS{idProduct}=="6387", TAG+="systemd"
```

reload udev (to activate changes to the rule, without reboot)
```bash
udevadm control --reload
```

#### 2.2 setup systemd to automount encrypted usb

find device uuid with
```bash
root@host:~# lsblk -fs $DEVICE
NAME FSTYPE      FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
sde  crypto_LUKS 2           f3e7f11c-9b84-4391-80b2-2ef82b2aa5c8
```
add following line to `/etc/crypttab` to configure decrypting this usb device (`noauto` prevents failing boot, when device is unplugged)
```bash
backup-crypted     UUID=f3e7f11c-9b84-4391-80b2-2ef82b2aa5c8 /root/usb-disk.key luks,noauto
```

test with 
```bash
root@host:~# cryptdisks_start backup-crypted
 * Starting crypto disk...                                                                                                                                                                                                                                                                                           
 * backup-crypted (running)...
```

check device
```bash
root@host:~# cryptsetup status backup-crypted
/dev/mapper/backup-crypted is active.
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

configure mounting in `/etc/fstab` (triggered from [systemd.mount](https://www.freedesktop.org/software/systemd/man/latest/systemd.mount.html)) 
```
/dev/mapper/backup-crypted /root/backup-crypted btrfs compress=zstd,noauto,nofail,x-systemd.automount,x-systemd.device-timeout=15s,x-systemd.idle-timeout=30 0 0
```
`noauto` prevents failing during boot when device is unplugged

`x-systemd.automount` creates a [systemd.automount unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.automount.html)

reload systemd services
```bash
root@host:~# Reload file system services for creating mount services for the external drive
sudo systemctl restart local-fs.target
sudo systemctl restart remote-fs.target
```

test it (unplugged and after plugged in)
```bash
root@host:~# watch 'mount | grep backup-crypted'
systemd-1 on /root/backup-crypted type autofs (rw,relatime,fd=54,pgrp=1,timeout=30,minproto=5,maxproto=5,direct,pipe_ino=790044)
```

### 3. Setup automatic backup as root with visual feedback for an ordinary user

steps
1. create a simple backup script to actual do backup
2. create `systemd.service` to trigger wrapper backup script
3. adjust udev rule to trigger our `systemd.service`

#### 3.1 create a simple backup script to actual do backup
simple backup script `/root/backup-crypted.sh`
```bash 
#!/bin/bash

echo test

echo "press ENTER"
read
```

make it executable and test it
```bash
chmod +x /root/backup-crypted.sh
```
#### 3.2 create `systemd.service` to trigger wrapper backup script

wrapper script `/root/systemd.make_backup.sh` to display as root on user session ([zenity](https://en.wikipedia.org/wiki/Zenity) enables ui dialogs from shell scripts)
```bash
#!/bin/bash

set -eux

BACKUP_SCRIPT=/root/backup-crypted.sh
MOUNT_PATH=/root/backup-crypted

# check environment of user session, can differ
export XDG_RUNTIME_DIR=/run/user/1000
export XAUTHORITY=/home/lars/.Xauthority 
export DISPLAY=:0.0

xterm -title 'backup' -geometry 200x50 -e $BACKUP_SCRIPT

if umount "$MOUNT_PATH"; then
   zenity --info  --text "usb device can be removed"
else
   zenity --error  --text "umount failed"
fi
```

make it executable and test it
```bash
chmod +x /root/systemd.make_backup.sh
```

create new systemd service file
```bash
systemctl edit --force --full usb-drive-backup.service
```

plain service file
```
[Service]
ExecStart=/root/systemd.make_backup.sh
```

test it
```bash
# reload to make changed unit files visible to systemd
systemctl daemon-reload

# trigger manually service
systemctl start usb-drive-backup

# see status 
systemctl status usb-drive-backup
```

adjust service to wait for automounts
```bash
systemctl edit --force --full usb-drive-backup.service
```

adjusted service file
```bash
[Unit]
Requires=root-backup\x2dcrypted.automount
After=root-backup\x2dcrypted.automount

[Service]
ExecStart=/root/systemd.make_backup.sh

[Install]
WantedBy=root-backup\x2dcrypted.automount
WantedBy=graphical.target # prevent errors when no graphical session is available (during boot)
```

again reload systemd
```bash
systemctl daemon-reload
```

#### 3.3 adjust udev rule to trigger our `systemd.service`

add a reference to `usb-drive-backup.service` (see [systemd.device](https://www.freedesktop.org/software/systemd/man/latest/systemd.device.html))
```bash
KERNEL=="sd*", SUBSYSTEMS=="usb", ATTRS{idVendor}=="058f", ATTRS{idProduct}=="6387", TAG+="systemd", ENV{SYSTEMD_WANTS}="usb-drive-backup.service"
```

depending on your system it needs `ENV{UDISKS_IGNORE}==1` to suppress file manager to prompt for a password on plugin (GNOME needs, XFCE does not need it)
```bash
KERNEL=="sd*", SUBSYSTEMS=="usb", ATTRS{idVendor}=="058f", ATTRS{idProduct}=="6387", TAG+="systemd", ENV{SYSTEMD_WANTS}="usb-drive-backup.service", ENV{UDISKS_IGNORE}==1
```

reload udev (to activate changes to the rule, without reboot)
```bash
udevadm control --reload
```

This script will pop up as terminal, window and disappear after a second.

Thats it!

## Debugging

udev logging
```bash
udevadm control --log-priority=debug
journalctl  -f -u systemd-udevd # follows the log
udevadm control --log-priority=info # this is default
```

trigger event without actual  plugin/plugout
```bash
udevadm trigger 
```

various
```bash
dmsetup remove --force usb-crypted
```

Links:

- [https://wiki.archlinux.org/title/Udev](https://wiki.archlinux.org/title/Udev)
- https://askubuntu.com/questions/1283544/server-automount-usb-drive-with-systemd