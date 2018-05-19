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

# Clone btcpayserver-docker
git clone $BTCPAY_DOCKER_REPO
cd btcpayserver-docker
git checkout $BTCPAY_DOCKER_REPO_BRANCH

. ./btcpay-setup.sh -i
