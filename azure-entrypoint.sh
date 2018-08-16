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
: "${BTCPAYGEN_LIGHTNING:=$9}"
: "${BTCPAYGEN_REVERSEPROXY:=nginx}"
: "${ACME_CA_URI:=https://acme-staging.api.letsencrypt.org/directory}"

CUSTOM_SSH_KEY="${10}"
BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage"

# Setup SSH access via private key
ssh-keygen -t rsa -f /root/.ssh/id_rsa_btcpay -q -P ""
echo "# Key used by BTCPay Server" >> /root/.ssh/authorized_keys
cat /root/.ssh/id_rsa_btcpay.pub >> /root/.ssh/authorized_keys
if [[ "$CUSTOM_SSH_KEY" ]]; then
    echo "" >> /root/.ssh/authorized_keys
    echo "# User key" >> /root/.ssh/authorized_keys
    echo "$CUSTOM_SSH_KEY" >> /root/.ssh/authorized_keys
    echo "Custom SSH Key added to /root/.ssh/authorized_keys"
fi
sed -i -e '/^PasswordAuthentication / s/ .*/ no/' /etc/ssh/sshd_config
userdel -r -f temp

# Configure BTCPAY to have access to SSH
BTCPAY_HOST_SSHKEYFILE=/root/.ssh/id_rsa_btcpay

# Clone btcpayserver-docker
git clone $BTCPAY_DOCKER_REPO
cd btcpayserver-docker
git checkout $BTCPAY_DOCKER_REPO_BRANCH

. ./btcpay-setup.sh -i

[ -x "$(command -v /etc/init.d/sshd)" ] && nohup /etc/init.d/sshd restart &
[ -x "$(command -v /etc/init.d/ssh)" ] && nohup /etc/init.d/ssh restart &
