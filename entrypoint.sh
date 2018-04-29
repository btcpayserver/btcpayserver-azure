#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

: "${AZURE_DNS:=$1}"
: "${NBITCOIN_NETWORK:=$2}"
: "${LETSENCRYPT_EMAIL:=$3}"
: "${BTCPAY_DOCKER_REPO:=$4}"
: "${BTCPAY_DOCKER_REPO_BRANCH:=$5}"
: "${LIGHTNING_ALIAS:=$6}"
: "${USE_BTC:=$7}"
: "${USE_LTC:=$8}"
: "${USE_CLIGHTNING:=$9}"
: "${ACME_CA_URI:=https://acme-staging.api.letsencrypt.org/directory}"

DOWNLOAD_ROOT="`pwd`"

echo "
-------SETUP-----------
Parameters passed:
AZURE_DNS:$AZURE_DNS
NBITCOIN_NETWORK:$NBITCOIN_NETWORK
LETSENCRYPT_EMAIL:$LETSENCRYPT_EMAIL
BTCPAY_DOCKER_REPO:$BTCPAY_DOCKER_REPO
BTCPAY_DOCKER_REPO_BRANCH:$BTCPAY_DOCKER_REPO_BRANCH
LIGHTNING_ALIAS:$LIGHTNING_ALIAS
USE_BTC:$USE_BTC
USE_LTC:$USE_LTC
USE_CLIGHTNING:$USE_CLIGHTNING
----------------------
ACME_CA_URI:$ACME_CA_URI
DOWNLOAD_ROOT:$DOWNLOAD_ROOT
----------------------
"

BTCPAY_ENV_FILE="`pwd`/.env"
SUPPORTED_CRYPTO_CURRENCIES=""

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

BTCPAY_HOST="$AZURE_DNS"
BTCPAY_DOCKER_COMPOSE="`pwd`/btcpayserver-docker/Production/docker-compose.$SUPPORTED_CRYPTO_CURRENCIES.yml"

export AZURE_DNS
export BTCPAY_DOCKER_COMPOSE
export DOWNLOAD_ROOT
export BTCPAY_ENV_FILE

# Put the variable in /etc/environment for reboot
cp /etc/environment /etc/environment.bak
echo "
AZURE_DNS=\"$AZURE_DNS\"
BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"
DOWNLOAD_ROOT=\"$DOWNLOAD_ROOT\"
BTCPAY_ENV_FILE=\"$BTCPAY_ENV_FILE\"" >> /etc/environment


# Put the variable in /etc/profile.d when a user log interactively
touch "/etc/profile.d/btcpay-env.sh"
echo "
export AZURE_DNS=\"$AZURE_DNS\"
export BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"
export DOWNLOAD_ROOT=\"$DOWNLOAD_ROOT\"
export BTCPAY_ENV_FILE=\"$BTCPAY_ENV_FILE\"" > /etc/profile.d/btcpay-env.sh

chmod +x /etc/profile.d/btcpay-env.sh

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

# Set .env file
touch $BTCPAY_ENV_FILE
echo "
BTCPAY_HOST=$BTCPAY_HOST
ACME_CA_URI=$ACME_CA_URI
NBITCOIN_NETWORK=$NBITCOIN_NETWORK
LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL
LIGHTNING_ALIAS=$LIGHTNING_ALIAS" > $BTCPAY_ENV_FILE

# Schedule for reboot
if [ -d "/etc/systemd/system" ]; then # Use systemd

echo "
[Unit]
Description=BTCPayServer service
After=docker.service network-online.target
Requires=docker.service network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes

ExecStart=/bin/bash -c '. /etc/profile.d/btcpay-env.sh && cd \"\$(dirname \$BTCPAY_ENV_FILE)\" && docker-compose -f \"\$BTCPAY_DOCKER_COMPOSE\" up -d'
ExecStop=/bin/bash -c '. /etc/profile.d/btcpay-env.sh && cd \"\$(dirname \$BTCPAY_ENV_FILE)\" && docker-compose -f \"\$BTCPAY_DOCKER_COMPOSE\" stop'
ExecReload=/bin/bash -c '. /etc/profile.d/btcpay-env.sh && cd \"\$(dirname \$BTCPAY_ENV_FILE)\" && docker-compose -f \"\$BTCPAY_DOCKER_COMPOSE\" restart'

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/btcpayserver.service

systemctl daemon-reload
systemctl enable btcpayserver
systemctl start btcpayserver

else # Use upstart
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
    docker-compose -f "$BTCPAY_DOCKER_COMPOSE" up -d 
fi

cd "`dirname $BTCPAY_ENV_FILE`"

find `pwd` -name "*.sh" -exec chmod +x {} \;
find `pwd` -name "*.sh" -exec ln -s {} /usr/bin \;
find `pwd`/btcpayserver-docker -name "*.sh" -exec chmod +x {} \;
find `pwd`/btcpayserver-docker -name "*.sh" -exec ln -s {} /usr/bin \;
