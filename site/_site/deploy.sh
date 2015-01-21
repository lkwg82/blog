#!/bin/bash

set -e

rsync  --archive -e ssh --delete-excluded \
	--exclude .git \
	--exclude *.py \
	--exclude *.sh \
	-vr _site/* www2.wirt.lgohlke.de:/var/www/blog
