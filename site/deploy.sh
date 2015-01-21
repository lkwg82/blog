#!/bin/bash

set -e

./post-commit.sh
jekyll build

rsync  --archive -e ssh --delete-excluded \
	--exclude .git \
	--exclude *.py \
	--exclude *.sh \
	-vr _site/* blogHost:/var/www/blog
