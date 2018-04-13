cd "`dirname $BTCPAY_DOCKER_COMPOSE`"  
git pull
cd "`dirname $BTCPAY_ENV_FILE`"
docker-compose -f $BTCPAY_DOCKER_COMPOSE up -d

cd btcpayserver-docker
find `pwd` -name "*.sh" -exec chmod +x {} \; 2>/dev/null
find `pwd` -name "*.sh" -exec ln -s {} /usr/bin \; 2>/dev/null