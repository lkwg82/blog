#!/bin/bash


until php /configure.php 2> /dev/null; do
	let "count+=1"
	if [ $count -gt 100 ]; then
		echo "failed startup"
		exit 1
	fi
	>&2 echo "db is unavailable - sleeping ($count)"
	sleep 1
done

>&2 echo "db is up"
