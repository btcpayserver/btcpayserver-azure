#!/bin/bash

if ! [ -x "$(command -v git)" ]; then
    apt-get update 2>error
    apt-get install -y git 2>error
fi

: "${BTCPAY_HOST:=$1}"
: "${NBITCOIN_NETWORK:=$2}"
: "${LETSENCRYPT_EMAIL:=$3}"
: "${BTCPAY_DOCKER_REPO:=$4}"
: "${BTCPAY_DOCKER_REPO_BRANCH:=$5}"
: "${LIGHTNING_ALIAS:=$6}"
: "${BTCPAYGEN_CRYPTO1:=$7}"
: "${BTCPAYGEN_CRYPTO2:=$8}"
: "${BTCPAYGEN_CRYPTO3:=$9}"
: "${BTCPAYGEN_CRYPTO4:=$10}"
: "${BTCPAYGEN_CRYPTO5:=$11}"
: "${BTCPAYGEN_CRYPTO6:=$12}"
: "${BTCPAYGEN_CRYPTO7:=$13}"
: "${BTCPAYGEN_CRYPTO8:=$14}"
: "${BTCPAYGEN_CRYPTO9:=$15}"
: "${BTCPAYGEN_LIGHTNING:=$16}"
: "${BTCPAYGEN_REVERSEPROXY:=nginx}"

CUSTOM_SSH_KEY="${17}"
BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage"

if [[ "$CUSTOM_SSH_KEY" ]]; then
    echo "" >> /root/.ssh/authorized_keys
    echo "# User key" >> /root/.ssh/authorized_keys
    echo "$CUSTOM_SSH_KEY" >> /root/.ssh/authorized_keys
    echo "Custom SSH Key added to /root/.ssh/authorized_keys"
fi
sed -i -e '/^PasswordAuthentication / s/ .*/ no/' /etc/ssh/sshd_config
userdel -r -f temp

cd /root
# Configure BTCPAY to have access to SSH
BTCPAY_ENABLE_SSH=true

# Clone btcpayserver-docker
git clone $BTCPAY_DOCKER_REPO
cd btcpayserver-docker
git checkout $BTCPAY_DOCKER_REPO_BRANCH

. ./btcpay-setup.sh -i

[ -x "$(command -v /etc/init.d/sshd)" ] && nohup /etc/init.d/sshd restart &
[ -x "$(command -v /etc/init.d/ssh)" ] && nohup /etc/init.d/ssh restart &
