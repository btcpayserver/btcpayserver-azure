
export NEW_HOST="$1"

echo "Changing domain from \"$VIRTUAL_HOST\" to \"$NEW_HOST\""

export VIRTUAL_HOST="$NEW_HOST"
export LETSENCRYPT_HOST="$NEW_HOST"
export ACME_CA_URI="https://acme-v01.api.letsencrypt.org/directory"

cp -f /etc/environment.bak /etc/environment
echo "AZURE_DNS=\"$AZURE_DNS\"" >> /etc/environment
echo "VIRTUAL_HOST=\"$VIRTUAL_HOST\"" >> /etc/environment
echo "LETSENCRYPT_HOST=\"$LETSENCRYPT_HOST\"" >> /etc/environment
echo "BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"" >> /etc/environment
echo "ACME_CA_URI=\"$ACME_CA_URI\"" >> /etc/environment
echo "BITCOIND_NETWORKPARAMETER=\"$BITCOIND_NETWORKPARAMETER\"" >> /etc/environment
echo "NBITCOIN_NETWORK=\"$NBITCOIN_NETWORK\"" >> /etc/environment
echo "BITCOIND_COOKIEFILE=\"$BITCOIND_COOKIEFILE\"" >> /etc/environment

# Put the variable in /etc/profile.d when a user log interactively
touch "/etc/profile.d/btcpay-env.sh"
echo "#!/bin/bash" >> /etc/profile.d/btcpay-env.sh
echo "export AZURE_DNS=\"$AZURE_DNS\"" >> /etc/profile.d/btcpay-env.sh
echo "export VIRTUAL_HOST=\"$VIRTUAL_HOST\"" >> /etc/profile.d/btcpay-env.sh
echo "export LETSENCRYPT_HOST=\"$LETSENCRYPT_HOST\"" >> /etc/profile.d/btcpay-env.sh
echo "export BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"" >> /etc/profile.d/btcpay-env.sh
echo "export ACME_CA_URI=\"$ACME_CA_URI\"" >> /etc/profile.d/btcpay-env.sh
echo "export BITCOIND_NETWORKPARAMETER=\"$BITCOIND_NETWORKPARAMETER\"" >> /etc/profile.d/btcpay-env.sh
echo "export NBITCOIN_NETWORK=\"$NBITCOIN_NETWORK\"" >> /etc/profile.d/btcpay-env.sh
echo "export BITCOIND_COOKIEFILE=\"$BITCOIND_COOKIEFILE\"" >> /etc/profile.d/btcpay-env.sh

docker-compose -f "$BTCPAY_DOCKER_COMPOSE" down
docker-compose -f "$BTCPAY_DOCKER_COMPOSE" up -d