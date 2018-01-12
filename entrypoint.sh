#!/bin/bash

# It is running as root
export AZURE_DNS="$1"
export NBITCOIN_NETWORK="$2"
export LETSENCRYPT_EMAIL="$3"
export SUPPORTED_CRYPTO_CURRENCIES="$4"

export DOWNLOAD_ROOT="`pwd`"
export BTCPAY_ENV_FILE="`pwd`/btcpayserver-docker/Production/.env"

export BTCPAY_HOST="$AZURE_DNS"
export BTCPAY_DOCKER_COMPOSE="`pwd`/btcpayserver-docker/Production/docker-compose.$SUPPORTED_CRYPTO_CURRENCIES.yml"
export ACME_CA_URI="https://acme-staging.api.letsencrypt.org/directory"

echo "DNS NAME: $AZURE_DNS"

# Put the variable in /etc/environment for reboot
cp /etc/environment /etc/environment.bak
echo "AZURE_DNS=\"$AZURE_DNS\"" >> /etc/environment
echo "BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"" >> /etc/environment
echo "DOWNLOAD_ROOT=\"$DOWNLOAD_ROOT\"" >> /etc/environment
echo "BTCPAY_ENV_FILE=\"$BTCPAY_ENV_FILE\"" >> /etc/environment


# Put the variable in /etc/profile.d when a user log interactively
touch "/etc/profile.d/btcpay-env.sh"
echo "AZURE_DNS=\"$AZURE_DNS\"" >> /etc/profile.d/btcpay-env.sh
echo "BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"" >> /etc/profile.d/btcpay-env.sh
echo "DOWNLOAD_ROOT=\"$DOWNLOAD_ROOT\"" >> /etc/profile.d/btcpay-env.sh
echo "BTCPAY_ENV_FILE=\"$BTCPAY_ENV_FILE\"" >> /etc/profile.d/btcpay-env.sh

# Install docker (https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#set-up-the-repository) and docker-compose 
apt-get update 2>error
apt-get install -y \
    git \
    curl \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    2>error

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install -y docker-ce

# Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.17.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone btcpayserver
git clone https://github.com/btcpayserver/btcpayserver-docker

docker-compose -f "$BTCPAY_DOCKER_COMPOSE" up -d 

# Schedule for reboot

echo "
# File is saved under /etc/init/start_containers.conf
# After file is modified, update config with : $ initctl reload-configuration

description     \"Start containers (see http://askubuntu.com/a/22105 and http://askubuntu.com/questions/612928/how-to-run-docker-compose-at-bootup)\"

start on filesystem and started docker
stop on runlevel [!2345]

# if you want it to automatically restart if it crashes, leave the next line in
# respawn # might cause over charge

script
    . /etc/profile.d/btcpay-env.sh
    docker-compose -f \"$BTCPAY_DOCKER_COMPOSE\" up -d
end script" > /etc/init/start_containers.conf

initctl reload-configuration

# Set .env file
touch $BTCPAY_ENV_FILE
echo "BTCPAY_HOST=$BTCPAY_HOST" >> $BTCPAY_ENV_FILE
echo "ACME_CA_URI=$ACME_CA_URI" >> $BTCPAY_ENV_FILE
echo "NBITCOIN_NETWORK=$NBITCOIN_NETWORK" >> $BTCPAY_ENV_FILE
echo "LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL" >> $BTCPAY_ENV_FILE

chmod +x changedomain.sh
chmod +x btcpay-restart.sh
chmod +x btcpay-update.sh
ln -s `pwd`/changedomain.sh /usr/bin/changedomain.sh
ln -s `pwd`/btcpay-restart.sh /usr/bin/btcpay-restart.sh
ln -s `pwd`/btcpay-update.sh /usr/bin/btcpay-update.sh