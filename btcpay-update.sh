cd "`dirname $BTCPAY_ENV_FILE`" && git pull && docker-compose -f $BTCPAY_DOCKER_COMPOSE down && docker-compose -f $BTCPAY_DOCKER_COMPOSE up -d