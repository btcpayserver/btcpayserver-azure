#!/bin/bash


# Install docker (https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#set-up-the-repository) and docker-compose 
sudo apt-get update 2>error
sudo apt-get install -y \
    git \
    curl \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    2>error

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install -y docker-ce

# Install docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/1.17.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone btcpayserver
git clone https://github.com/btcpayserver/btcpayserver-docker && cd btcpayserver-docker/Regtest

echo "
description \"Docker-compose up\"
start on startup
pre-start script
    cd `pwd`
end script
exec docker-compose up -d
" > /etc/init/docker-compose-startup.conf

docker-compose up -d
pwd