
export NEW_HOST="$1"

echo "Changing domain to \"$NEW_HOST\""

export BTCPAY_HOST="$NEW_HOST"
export ACME_CA_URI="https://acme-v01.api.letsencrypt.org/directory"

# .env file, last entry win, so just add to the file
echo "BTCPAY_HOST=$BTCPAY_HOST" >> $BTCPAY_ENV_FILE
echo "ACME_CA_URI=$ACME_CA_URI" >> $BTCPAY_ENV_FILE

docker-compose -f "$BTCPAY_DOCKER_COMPOSE" down
docker-compose -f "$BTCPAY_DOCKER_COMPOSE" up -d