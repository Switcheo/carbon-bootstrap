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
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
fi

sudo apt update

if [[ $(lsb_release -rs) == "20.04" ]]; then
  if [ $(dpkg-query -W -f='${Status}' libleveldb1d 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "-- Installing level db"

    sudo apt-get install libleveldb1d=1.22-3ubuntu2 -y
  fi
elif [[ $(lsb_release -rs) == "18.04" ]]; then
  if [ $(dpkg-query -W -f='${Status}' libleveldb1v5 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "-- Installing level db"

    sudo apt-get install libleveldb1v5=1.20-2 -y
  fi
else
  echo "OS in incompatible with this script."
  exit 1
fi

if [ "$SETUP_POSTGRES" = true ] && [ $(dpkg-query -W -f='${Status}' postgresql-13 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "-- Installing postgresql-13"

  sudo apt-get install postgresql-13 -y
  sudo sed -i.orig '/local\(\s*\)all\(\s*\)postgres/ s|\(\s*\)peer|         127.0.0.1\/32         trust|; /local\(\s*\)all\(\s*\)postgres/ s|local|host|' \
    /etc/postgresql/13/main/pg_hba.conf
  sudo service postgresql restart
fi

if [ "$SETUP_PSQL_CLIENT" = true ] && [ $(dpkg-query -W -f='${Status}' postgresql-client-13 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "-- Installing postgresql-client-13"

  sudo apt-get install postgresql-client-13 -y
fi

if [ "$SETUP_REDIS" = true ] && [ $(dpkg-query -W -f='${Status}' redis-server 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "-- Installing redis"

  sudo apt-get install redis-server -y
fi
