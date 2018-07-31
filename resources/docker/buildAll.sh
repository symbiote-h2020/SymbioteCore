#!/bin/bash
#Apache
cp configuration/config.txt apache/
cp configuration/cert/cert.pem configuration/cert/chain.pem configuration/cert/privkey.pem apache/configuration/
docker build -t symbiote-apache apache/

#SymbioteCore
cp configuration/config.txt symbioteCore/
cp configuration/cert/fullchain.pem configuration/cert/privkey.pem symbioteCore/configuration/cert/
docker build -t symbiote-core symbioteCore/
