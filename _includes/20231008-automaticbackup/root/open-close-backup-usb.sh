#!/bin/bash

set -eu


(
  echo "------------------- $(date) --- ${ACTION} ------------"
  #env | sort
  if [[ $ACTION == 'add' ]]; then
	DEVICE_NAME="usb-crypted-$RANDOM$RANDOM" # to cope with retries without the need to reboot the system
	echo $DEVICE_NAME
	if cryptsetup status $DEVICE_NAME > /dev/null; then
		echo "ERROR already opened ... "
		exit 1
	fi
  
	echo "opening"
  	if cryptsetup luksOpen /dev/disk/by-uuid/$ID_FS_UUID $DEVICE_NAME --key-file /root/usb-disk.key ; then
		echo "opened"
  	fi
  	cryptsetup status $DEVICE_NAME

	# propagate device name
	echo "/dev/mapper/$DEVICE_NAME" > /tmp/usb-crypted.device-name
  else
	DEVICE_NAME=$(cat /tmp/usb-crypted.device-name)
	cryptsetup close --debug $DEVICE_NAME
	rm -vf /tmp/usb-crypted.device-name
  fi
  echo "------------------- $(date) ------------------"
  ) >> /tmp/$(basename $0).log 2>&1
