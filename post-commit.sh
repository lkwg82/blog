#!/bin/bash

set -e
#set -x

baseDir=$(git rev-parse --show-toplevel)
file=_includes/footer.html

version=$(git log  -n1 --format=format:"%ci %H")
message="updated version info"

if [ "$(git log  -n1 --format=format:"%s")" != "$message" ] ;then

	sed -e 's#<span class="version">.*</span>#<span class="version">last changed '"$version"'</span>#' -i $file
	git commit --no-verify -m 'updated version info' $file
fi


