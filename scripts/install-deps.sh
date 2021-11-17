#!/bin/bash

set -e

echo "-- Install dependencies --"

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt update
sudo apt install build-essential cmake jq -y

if [ ! -f "/usr/local/lib/libleveldb.so.1" ]; then
  echo "-- Installing level db"

  sudo apt-get install libleveldb1d -y
fi

if [ $(dpkg-query -W -f='${Status}' postgresql-13 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "-- Installing postgresql-13"
  sudo apt-get install postgresql-13 -y
fi

sudo sed -i.orig '/local\(\s*\)all\(\s*\)postgres/ s|\(\s*\)peer|         127.0.0.1\/32         trust|; s|local|host|' \
  /etc/postgresql/13/main/pg_hba.conf
sudo service postgresql restart

if [ $(dpkg-query -W -f='${Status}' redis-server 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "-- Installing redis"
  sudo apt-get install redis-server -y
fi
