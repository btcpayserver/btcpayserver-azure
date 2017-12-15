#!/bin/bash


# Remove error message from apt-get
sudo apt-get update 2>error
sudo apt-get install -y git curl 2>error

sudo curl -L https://github.com/docker/compose/releases/download/1.18.0-rc2/docker-compose-1.16.1 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

git clone https://github.com/btcpayserver/btcpayserver-docker && cd btcpayserver-docker/Regtest
docker-compose up
