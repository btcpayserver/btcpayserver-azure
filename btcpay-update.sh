cd "`dirname $BTCPAY_DOCKER_COMPOSE`"  
git pull
 cd "`dirname $BTCPAY_ENV_FILE`"
docker-compose -f $BTCPAY_DOCKER_COMPOSE down
docker-compose -f $BTCPAY_DOCKER_COMPOSE up -d