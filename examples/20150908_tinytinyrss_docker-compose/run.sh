#!/bin/bash

set -e
#set -x
function checkInstalled {
	which $1 >/dev/null  || echo install $1 with $2
}

TTRSS_DIR=tt-rss_

checkInstalled "git" "install git"

export PATH=$PATH:~/.local/bin/
checkInstalled "docker-compose" "install docker-compose with 'sudo pip install docker-compose'"

if [ -d $TTRSS_DIR ];
then
   cd $TTRSS_DIR
   git pull
   git fetch
   cd ..
else
   git clone https://tt-rss.org/git/tt-rss.git $TTRSS_DIR
fi

cd $TTRSS_DIR
chmod -fR 0777 cache/images cache/upload cache/export cache/js feed-icons lock || echo "fails: in case of rerun"
cd ..

docker-compose build 
docker-compose up -d 

echo let pgdb run init
sleep 10

rm -f $TTRSS_DIR/config.php || echo -n 
curl -s -o /dev/null 'http://localhost:9108/install/' --data 'op=installschema&DB_TYPE=pgsql&DB_USER=postgres&DB_PASS=mysecretpassword&DB_NAME=postgres&DB_HOST=db&DB_PORT=&SELF_URL_PATH=http%3A%2F%2Flocalhost%3A9108%2F'
cp setup_data/config.php $TTRSS_DIR

