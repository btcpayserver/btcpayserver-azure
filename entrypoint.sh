#!/bin/bash

sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/btcpayserver/btcpayserver-docker && cd btcpayserver-docker/Regtest
docker-compose up
