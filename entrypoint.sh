#!/bin/bash


# Remove error message from apt-get (https://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory)
sudo dpkg-preconfigure -f noninteractive -p critical
sudo dpkg --configure -a

sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/btcpayserver/btcpayserver-docker && cd btcpayserver-docker/Regtest
docker-compose up
