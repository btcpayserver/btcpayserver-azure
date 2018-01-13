cd "`dirname $BTCPAY_DOCKER_COMPOSE`"  
git pull
git checkout $BTCPAY_DOCKER_REPO_BRANCH
 cd "`dirname $BTCPAY_ENV_FILE`"
docker-compose -f $BTCPAY_DOCKER_COMPOSE down
docker-compose -f $BTCPAY_DOCKER_COMPOSE up -d