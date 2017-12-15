#!/bin/bash

# It is running as root
export DNS_NAME="$1"
export VIRTUAL_HOST="$DNS_NAME"
export LETSENCRYPT_HOST="$DNS_NAME"
export BTCPAY_DOCKER_COMPOSE="`pwd`/btcpayserver-docker/Mainnet"
export ACME_CA_URI="https://acme-staging.api.letsencrypt.org/directory"

echo "DNS NAME: $DNS_NAME"


# Put the variable in /etc/environment for reboot
echo "DNS_NAME=\"$DNS_NAME\"" >> /etc/environment
echo "VIRTUAL_HOST=\"$VIRTUAL_HOST\"" >> /etc/environment
echo "LETSENCRYPT_HOST=\"$LETSENCRYPT_HOST\"" >> /etc/environment
echo "BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"" >> /etc/environment
echo "ACME_CA_URI=\"$ACME_CA_URI\"" >> /etc/environment

# Put the variable in /etc/profile.d when a user log interactively
touch "/etc/profile.d/btcpay-env.sh"
echo "#!/bin/bash" >> /etc/profile.d/btcpay-env.sh
echo "export DNS_NAME=\"$DNS_NAME\"" >> /etc/profile.d/btcpay-env.sh
echo "export VIRTUAL_HOST=\"$VIRTUAL_HOST\"" >> /etc/profile.d/btcpay-env.sh
echo "export LETSENCRYPT_HOST=\"$LETSENCRYPT_HOST\"" >> /etc/profile.d/btcpay-env.sh
echo "export BTCPAY_DOCKER_COMPOSE=\"$BTCPAY_DOCKER_COMPOSE\"" >> /etc/profile.d/btcpay-env.sh
echo "export ACME_CA_URI=\"$ACME_CA_URI\"" >> /etc/profile.d/btcpay-env.sh

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

# Clone btcpayserver
git clone https://github.com/btcpayserver/btcpayserver-docker && cd $BTCPAY_DOCKER_COMPOSE

docker-compose up -d

# Schedule for reboot

echo "
# File is saved under /etc/init/start_containers.conf
# After file is modified, update config with : $ initctl reload-configuration

description     \"Start containers (see http://askubuntu.com/a/22105 and http://askubuntu.com/questions/612928/how-to-run-docker-compose-at-bootup)\"

start on filesystem and started docker
stop on runlevel [!2345]

# if you want it to automatically restart if it crashes, leave the next line in
# respawn # might cause over charge

script
    docker-compose -f \"$BTCPAY_DOCKER_COMPOSE/docker-compose.yml\" up -d
end script" > /etc/init/start_containers.conf

initctl reload-configuration