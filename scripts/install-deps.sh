#!/bin/bash

set -e

echo "-- Installing dependencies --"

SETUP_PSQL_CLIENT=false
SETUP_POSTGRES=false
SETUP_REDIS=false

while getopts ":cpr" opt; do
  case $opt in
    c)
      SETUP_PSQL_CLIENT=true
      ;;
    p)
      SETUP_POSTGRES=true
      ;;
    r)
      SETUP_REDIS=true
      ;;
    h)
      printUsage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      printUsage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      printUsage
      exit 1
      ;;
  esac
done

if [ "$SETUP_POSTGRES" = true ] || [ "$SETUP_PSQL_CLIENT" = true ]; then
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --batch --yes --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
fi

sudo apt update
sudo apt-get install jq perl -y

if [ "$SETUP_POSTGRES" = true ] && [ $(dpkg-query -W -f='${Status}' postgresql-17 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "-- Installing postgresql-17"

  sudo apt-get install postgresql-17 -y
  sudo sed -i.orig '/local\(\s*\)all\(\s*\)postgres/ s|\(\s*\)peer|         127.0.0.1\/32         trust|; /local\(\s*\)all\(\s*\)postgres/ s|local|host|' \
    /etc/postgresql/17/main/pg_hba.conf
  sudo service postgresql restart
fi

if [ "$SETUP_PSQL_CLIENT" = true ] && [ $(dpkg-query -W -f='${Status}' postgresql-client-17 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "-- Installing postgresql-client-17"

  sudo apt-get install postgresql-client-17 -y
fi

if [ "$SETUP_REDIS" = true ] && [ $(dpkg-query -W -f='${Status}' redis-server 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "-- Installing redis"

  sudo apt-get install redis-server -y
fi
