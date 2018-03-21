#!/bin/bash

# It is running as root
export AZURE_DNS="$1"
export NBITCOIN_NETWORK="$2"
export LETSENCRYPT_EMAIL="$3"
export BTCPAY_DOCKER_REPO="$4"
export BTCPAY_DOCKER_REPO_BRANCH="$5"
export LIGHTNING_ALIAS="$6"
export USE_BTC="$7"
export USE_LTC="$8"
export USE_CLIGHTNING="$9"

# Remove superflous s
LIGHTNING_ALIAS=`echo $LIGHTNING_ALIAS | sed 's/^s\(.*\)/\1/'`

echo ""
echo "-------SETUP-----------"
echo "Parameters passed:"
echo "AZURE_DNS:$AZURE_DNS"
echo "NBITCOIN_NETWORK:$NBITCOIN_NETWORK"
echo "LETSENCRYPT_EMAIL:$LETSENCRYPT_EMAIL"
echo "BTCPAY_DOCKER_REPO:$BTCPAY_DOCKER_REPO"
echo "BTCPAY_DOCKER_REPO_BRANCH:$BTCPAY_DOCKER_REPO_BRANCH"
echo "LIGHTNING_ALIAS:$LIGHTNING_ALIAS"
echo "USE_BTC:$USE_BTC"
echo "USE_LTC:$USE_LTC"
echo "USE_CLIGHTNING:$USE_CLIGHTNING"
echo "----------------------"
echo ""

export DOWNLOAD_ROOT="`pwd`"
export BTCPAY_ENV_FILE="`pwd`/.env"
export SUPPORTED_CRYPTO_CURRENCIES=""

if [ "$USE_BTC" == "True" ]; then
    SUPPORTED_CRYPTO_CURRENCIES="$SUPPORTED_CRYPTO_CURRENCIES-btc"
fi

if [ "$USE_LTC" == "True" ]; then
    SUPPORTED_CRYPTO_CURRENCIES="$SUPPORTED_CRYPTO_CURRENCIES-ltc"
fi

if [ "$SUPPORTED_CRYPTO_CURRENCIES" == "" ]; then
    SUPPORTED_CRYPTO_CURRENCIES="-btc"
fi

if [ "$USE_CLIGHTNING" == "True" ]; then
    SUPPORTED_CRYPTO_CURRENCIES="$SUPPORTED_CRYPTO_CURRENCIES-clightning"
fi

# Remove superflous -
SUPPORTED_CRYPTO_CURRENCIES=`echo $SUPPORTED_CRYPTO_CURRENCIES | sed 's/^-\(.*\)/\1/'`

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
echo "export AZURE_DNS=\"$AZURE_DNS\"" >> /etc/profile.d/btcpay-env.sh
echo "export BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"" >> /etc/profile.d/btcpay-env.sh
echo "export DOWNLOAD_ROOT=\"$DOWNLOAD_ROOT\"" >> /etc/profile.d/btcpay-env.sh
echo "export BTCPAY_ENV_FILE=\"$BTCPAY_ENV_FILE\"" >> /etc/profile.d/btcpay-env.sh

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

# Clone btcpayserver-docker
git clone $BTCPAY_DOCKER_REPO
cd btcpayserver-docker
git checkout $BTCPAY_DOCKER_REPO_BRANCH
cd ..

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
    cd \"`dirname \$BTCPAY_ENV_FILE`\"
    docker-compose -f \"\$BTCPAY_DOCKER_COMPOSE\" up -d
end script" > /etc/init/start_containers.conf

initctl reload-configuration

# Set .env file
touch $BTCPAY_ENV_FILE
echo "BTCPAY_HOST=$BTCPAY_HOST" >> $BTCPAY_ENV_FILE
echo "ACME_CA_URI=$ACME_CA_URI" >> $BTCPAY_ENV_FILE
echo "NBITCOIN_NETWORK=$NBITCOIN_NETWORK" >> $BTCPAY_ENV_FILE
echo "LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL" >> $BTCPAY_ENV_FILE
echo "LIGHTNING_ALIAS=$LIGHTNING_ALIAS" >> $BTCPAY_ENV_FILE

cd "`dirname $BTCPAY_ENV_FILE`"
docker-compose -f "$BTCPAY_DOCKER_COMPOSE" up -d 

find `pwd` -name "*.sh" -exec chmod +x {} \;
find `pwd` -name "*.sh" -exec ln -s {} /usr/bin \;
find `pwd`/btcpayserver-docker -name "*.sh" -exec chmod +x {} \;
find `pwd`/btcpayserver-docker -name "*.sh" -exec ln -s {} /usr/bin \;