#!/bin/bash

set -eux
# HOME is populated by incron

BACKUP_SCRIPT=$HOME/backup-crypted.sh
DEVICE_PREFIX="usb-crypted-"
MOUNT_PATH=$HOME/backup-crypted
(
  if [[ $# == 1 ]] && [[ $1 =~ $DEVICE_PREFIX* ]]; then
    DEVICE_NAME="/dev/mapper/$1"
    echo "DEVICE_NAME: $DEVICE_NAME"
  else
    echo "no device name found"
    echo "use sth from:"
    find /dev/mapper -maxdepth 1 -name "$DEVICE_PREFIX*" -type l -printf "%f"
    echo "try '$0 <name>'"
    exit
  fi

  if  [[ -L $DEVICE_NAME ]]; then
    export DISPLAY=:0.0 # this could be different
    if ! mount | grep "$MOUNT_PATH"; then
      if ! sudo mount "$DEVICE_NAME" "$MOUNT_PATH"; then
        zenity --error  --text "Mount failed"
      fi
    fi

    xterm -title 'backup' -geometry 200x50 -e bash -c "$BACKUP_SCRIPT"

    if sudo umount "$MOUNT_PATH"; then
      zenity --info  --text "usb device can be removed"
    else
      zenity --error  --text "umount failed"
    fi
  else
    echo "not there"
  fi


) 2>&1 | tee --append "$HOME/$(basename $0).log"