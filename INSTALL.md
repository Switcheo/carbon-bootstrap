# Install Carbon
This guide will explain how to install the `carbond` entrypoint onto your system. With these installed on a server, you can participate in the mainnet as either a Full Node or a Validator.

## Install build requirements
Install `cmake`.

On Ubuntu this can be done with the following:
```bash
sudo apt-get update

sudo apt-get install -y build-essential cmake -y
```

## Install Go
```bash
wget https://dl.google.com/go/go1.17.linux-amd64.tar.gz
tar -xvf go1.17.linux-amd64.tar.gz
sudo mv go /usr/local

echo "" >>~/.bashrc
echo 'export GOPATH=$HOME/go' >>~/.bashrc
echo 'export GOROOT=/usr/local/go' >>~/.bashrc
echo 'export GOBIN=$GOPATH/bin' >>~/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin:$GOBIN' >>~/.bashrc

source ~/.bashrc

rm go1.17.linux-amd64.tar.gz
```

## Install Cleveldb
```bash
wget https://github.com/google/leveldb/archive/1.23.tar.gz
tar -zxvf 1.23.tar.gz

wget https://github.com/google/googletest/archive/release-1.11.0.tar.gz
tar -zxvf release-1.11.0.tar.gz
mv googletest-release-1.11.0/* leveldb-1.23/third_party/googletest

wget https://github.com/google/benchmark/archive/v1.5.5.tar.gz
tar -zxvf v1.5.5.tar.gz
mv benchmark-1.5.5/* leveldb-1.23/third_party/benchmark

cd leveldb-1.23
mkdir -p build

cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ..
cmake --build .
sudo cp -r lib* /usr/local/lib/
sudo ldconfig
cd ..

sudo cp -r include/leveldb /usr/local/include/
cd ..

rm -rf benchmark-1.5.5/
rm -f v1.5.5.tar.gz

rm -rf googletest-release-1.11.0/
rm -f release-1.11.0.tar.gz

rm -rf leveldb-1.23/
rm -f 1.23.tar.gz
```

## Install the binaries
Next, let's install the latest version of `Carbon`.
```bash
wget https://github.com/Switcheo/carbon-testnets/releases/download/v0.0.1/carbon0.0.1.tar.gz
tar -zxvf carbon0.0.1.tar.gz
sudo mv carbond cosmovisor /usr/local/bin
rm carbon0.0.1.tar.gz
```

That will install the `carbond` binary. Verify that everything is OK:
```bash
carbond version --long
```
`carbond` for instance should output something similar to:
```bash
name: carbon
server_name: <appd>
version: 0.0.1-521-g758a7b2
commit: 758a7b27f3e9ec156209eb50f60e6a087c210a02
build_tags: ""
go: go version go1.17 linux/amd64
```

## Install Redis
```bash
sudo apt-get redis-server -y
```

## Install Postgres
```bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get postgres-12 -y
sudo sed -i -e '/^local   all             postgres                                peer$/d' \
    -e 's/ peer/ trust/g' \
    -e 's/ md5/ trust/g' \
    /etc/postgresql/12/main/pg_hba.conf
sudo service postgresql restart
```
