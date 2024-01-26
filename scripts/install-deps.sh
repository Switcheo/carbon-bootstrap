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
sudo apt-get install jq -y

if [ -z "$(ldconfig -p | grep libleveldb.so.1$)" ]; then
  echo "-- Installing level db"

  sudo apt-get install build-essential cmake -y

  wget https://github.com/google/leveldb/archive/1.23.tar.gz && \
    tar -zxvf 1.23.tar.gz && \
    wget https://github.com/google/googletest/archive/release-1.11.0.tar.gz && \
    tar -zxvf release-1.11.0.tar.gz && \
    mv googletest-release-1.11.0/* leveldb-1.23/third_party/googletest && \

    wget https://github.com/google/benchmark/archive/v1.5.5.tar.gz && \
    tar -zxvf v1.5.5.tar.gz && \
    mv benchmark-1.5.5/* leveldb-1.23/third_party/benchmark && \

    cd leveldb-1.23 && \
    mkdir -p build && \

    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .. && \
    cmake --build . && \
    sudo cp -P libleveldb.so* /usr/local/lib/ && \
    sudo ldconfig && \
    cd .. && \

    sudo cp -r include/leveldb /usr/local/include/ && \
    cd .. && \

    rm -rf benchmark-1.5.5/ && \
    rm -f v1.5.5.tar.gz && \

    rm -rf googletest-release-1.11.0/ && \
    rm -f release-1.11.0.tar.gz && \

    rm -rf leveldb-1.23/ && \
    rm -f 1.23.tar.gz
fi

if [ -z "$(ldconfig -p | grep librocksdb.so.7.10)" ]; then
  echo "-- Installing rocksdb dependencies"

  sudo apt-get install build-essential cmake libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev -y

  echo "-- Installing gflags"
  wget https://github.com/gflags/gflags/archive/refs/tags/v2.2.2.tar.gz && \
    tar -zxvf v2.2.2.tar.gz && \
    cd gflags-2.2.2 && \

    mkdir -p build && \
    cd build && \

    cmake -DBUILD_SHARED_LIBS=1 -DGFLAGS_INSTALL_SHARED_LIBS=1 .. && \
    sudo make install && \

    cd ../.. && \
    rm -rf gflags-2.2.2 && \
    rm -f v2.2.2.tar.gz

  echo "-- Installing rocksdb"
  wget https://github.com/Switcheo/rocksdb/archive/refs/heads/v7.10.2-patched.tar.gz && \
    tar -zxvf v7.10.2-patched.tar.gz && \
    cd rocksdb-7.10.2-patched && \

    make shared_lib && \
    sudo make install-shared && \
    sudo ldconfig && \

    cd .. && \
    rm -rf rocksdb-7.10.2-patched && \
    rm -f v7.10.2-patched.tar.gz
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
