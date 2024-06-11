#!/bin/bash

set -e

VALIDATOR_NODE_IP_ADDRESS=$1
ORACLE_SERVICE_NODE_IP_ADDRESS=$2
CARBON_HOME_PATH=$3

CARBON_HOME_PATH="${CARBON_HOME_PATH/#\~/$HOME}"

mkdir -p ${CARBON_HOME_PATH}/config/cert

cd ${CARBON_HOME_PATH}/config/cert

rm -f *.pem

# 1. Generate CA's private key and self-signed certificate
openssl req -x509 -newkey rsa:4096 -days 36500 -nodes -keyout ca-key.pem -out ca-cert.pem -subj "/C=SG/ST=Singapore/L=Singapore/O=Switcheo/OU=Switcheo/CN=Switcheo/emailAddress=engineering@switcheo.network"

echo "CA's self-signed certificate"
openssl x509 -in ca-cert.pem -noout -text

# 2. Generate web server's private key and certificate signing request (CSR)
openssl req -newkey rsa:4096 -nodes -keyout server-key.pem -out server-req.pem -subj "/C=SG/ST=Singapore/L=Singapore/O=Switcheo/OU=Switcheo/CN=Switcheo/emailAddress=engineering@switcheo.network"

echo subjectAltName=IP:${VALIDATOR_NODE_IP_ADDRESS} >> server-ext.cnf

# 3. Use CA's private key to sign web server's CSR and get back the signed certificate
openssl x509 -req -in server-req.pem -days 36500 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile server-ext.cnf

echo "Server's signed certificate"
openssl x509 -in server-cert.pem -noout -text

# 4. Generate client's private key and certificate signing request (CSR)
openssl req -newkey rsa:4096 -nodes -keyout client-key.pem -out client-req.pem -subj "/C=SG/ST=Singapore/L=Singapore/O=Switcheo/OU=Switcheo/CN=Switcheo/emailAddress=engineering@switcheo.network"

echo subjectAltName=IP:${ORACLE_SERVICE_NODE_IP_ADDRESS} >> client-ext.cnf

# 5. Use CA's private key to sign client's CSR and get back the signed certificate
openssl x509 -req -in client-req.pem -days 36500 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -extfile client-ext.cnf

echo "Client's signed certificate"
openssl x509 -in client-cert.pem -noout -text
