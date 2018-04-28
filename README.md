# BTCPayServer Azure

Instructions to deploy BTCPay Server in [production environment](https://github.com/btcpayserver/btcpayserver-docker/tree/master/Production) hosted in Microsoft Azure.

The following instructions assume you have [Microsoft Azure](https://azure.microsoft.com/) subscription.

You can see our video for an overview:

[![BTCPay - One Click Setup](http://img.youtube.com/vi/Bxs95BdEMHY/mqdefault.jpg)](http://www.youtube.com/watch?v=Bxs95BdEMHY "BTCPay - One Click Setup")

---

It must be noted that even if this repository's goal is to make deployment on Azure easy, you can use it on your own VM, see [Running without Azure](#running-without-azure).

---

# Deploy via Microsoft Azure Portal

Click on this button and follow instructions:

[![Deploy to Azure](https://azuredeploy.net/deploybutton.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbtcpayserver%2Fbtcpayserver-azure%2Fmaster%2Fazuredeploy.json)

# Deploy with PowerShell

## Step 1: Download and install Azure PowerShell

You can do it by [using PowerShell command line](https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-5.0.0) or manually via [Web Platform Installer or MSI](https://docs.microsoft.com/en-us/powershell/azure/other-install?view=azurermps-5.0.0).

## Step 2: Authenticate to Azure

In PowerShell, you first need to authenticate to azure:

```
# This will popup a windows to authenticate to azure
Login-AzureRmAccount 
```

If you have multiple subscriptions, select the one you want:

```
# List your subscriptions
Get-AzureRmSubscription

# Select the one you want
Get-AzureRmSubscription –SubscriptionId "your subscription" | Select-AzureRmSubscription
```

## Step 3: Run the deployment

Create a new BTCPay Server instance:

```
.\deployOnAzure.ps1 -ResourceGroupName "myawesomebtcpay" -Network "mainnet"
```

Valid Network values are:

* mainnet
* testnet
* regtest

For ResourceGroupName, use only alphabetic lower case.

This might take around 5 minutes.

It will print you the DNS name of your server `myawesomebtcpay.southcentralus.cloudapp.azure.com`, you can browse to it to enjoy your BTCPay instance.

# Deploy on Linux

TODO: Write shell scripts using [Az tool](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-secured-vm-from-template), [other link](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli), [other link](https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/azure-resource-manager/resource-group-template-deploy-cli.md), [best link](http://markheath.net/post/deploying-arm-templates-azure-cli).

# How to change the domain name

By default, you will have a domain name assigned ending with `xxx.cloudapp.azure.com`. Because Let's Encrypt does not allow us to get HTTPS certificate for the `azure.com` domain, you need your own domain.

Then, add a CNAME record in your name server pointing to `xxx.cloudapp.azure.com`.

Connect then with SSH to your VM and run

```
sudo su -
changedomain.sh blah.example.com
```

This will change the settings of BTCPay and NGinx to use your domain. Upon restart, a new certificate for your domain will be requested by Let's encrypt.

# How to update BTCPay

Just pull the latest changes of the docker-compose and restart the docker service.

```
sudo su -
btcpay-update.sh
```

# How to restart BTCPay

Reboot docker:

```
sudo su -
btcpay-restart.sh
```

Or reboot the server:

```
sudo su -
reboot
```

# How to update the btcpay-* tools

```
sudo su -
cd $DOWNLOAD_ROOT
if [ ! -d "btcpayserver-azure" ]; then
    git clone https://github.com/btcpayserver/btcpayserver-azure
fi
cd btcpayserver-azure
git pull
cp *.sh ..
```

# Under the hood

Here are the step on provisioning done by Azure (so you can do it yourelf):

* Azure provision a new virtual machine
* Then copy all the sh files of this repository inside the new virtual machine
* Azure then execute `entrypoint.sh` passing the following arguments taken from the wizard:
    1. The initial DNS name
    2. The network (mainnet, testnet, regtest)
    3. Let's encrypt email
    4. Supported crypto currencies separated by '-'
    5. Docker repository url used for fetching the docker-compose
    6. The branch of this repository
* `entrypoint.sh` does the following actions:
    1. Copy the parameters inside `/etc/environment` and `/etc/profile.d/btcpay-env.sh` so they can be accessed via environment variable globally
    2. Add also those parameters  in the `.env` file which will be used by the `docker-compose`
    3. Install `docker-compose` and `git`
    4. Clone the `btcpayserver-docker` repository
    5. Configure upstart in `/etc/init/start_containers.conf` to start `docker-compose` if the machine reboot
    6. Start `docker-compose` in the directory of the `.env` as working directory
    7. Create symbolic links to `/usr/bin` to the other `btcpay-*.sh` utility scripts

Example of `/etc/environment`:

```
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
AZURE_DNS="dwoiqdwqb.westeurope.cloudapp.azure.com"
BTCPAY_DOCKER_COMPOSE="/var/lib/waagent/custom-script/download/0/btcpayserver-docker/Production/docker-compose.btc-ltc.yml"
BTCPAY_ENV_FILE="/var/lib/waagent/custom-script/download/0/.env"
DOWNLOAD_ROOT="/var/lib/waagent/custom-script/download/0"
```

Example of `/etc/profile.d/btcpay-env.sh`:

```
export AZURE_DNS="dwoiqdwqb.westeurope.cloudapp.azure.com"
export BTCPAY_DOCKER_COMPOSE="/var/lib/waagent/custom-script/download/0/btcpayserver-docker/Production/docker-compose.btc-ltc.yml"
export DOWNLOAD_ROOT="/var/lib/waagent/custom-script/download/0"
export BTCPAY_ENV_FILE="/var/lib/waagent/custom-script/download/0/.env"
```

Example of `.env` file:

```
BTCPAY_HOST=test-btc-ltc.forkbitpay.ninja
ACME_CA_URI=https://acme-v01.api.letsencrypt.org/directory
NBITCOIN_NETWORK=testnet
LETSENCRYPT_EMAIL=me@example.com
```

Example of `/etc/init/start_containers.conf` file:

```
# File is saved under /etc/init/start_containers.conf
# After file is modified, update config with : $ initctl reload-configuration

description     "Start containers (see http://askubuntu.com/a/22105 and http://askubuntu.com/questions/612928/how-to-run-docker-compose-at-bootup)"

start on filesystem and started docker
stop on runlevel [!2345]

# if you want it to automatically restart if it crashes, leave the next line in
# respawn # might cause over charge

script
    . /etc/profile.d/btcpay-env.sh
    cd "`dirname $BTCPAY_ENV_FILE`"
    docker-compose -f "$BTCPAY_DOCKER_COMPOSE" up -d
end script
```

Note that `AZURE_DNS` is not really used anywhere except for debugging purpose.
When you want to start/stop docker, for the environment variables in `.env` to be taken into account, you need to start from its folder:

```
cd "`dirname $BTCPAY_ENV_FILE`"
docker-compose -f "$BTCPAY_DOCKER_COMPOSE" up
```

# Running without Azure <a name="running-without-azure" />

You can run `./entrypoing.sh` without Azure, on your own Linux machine:

```
#Configure your DNS record (eg. btcpay.example.com)
#Make sure it point to this VM and that port 80 and 443 are open

# Clone the repository
git clone https://github.com/btcpayserver/btcpayserver-azure/

# Enter into this folder
cd btcpayserver-azure

export AZURE_DNS=btcpay.example.com
export NBITCOIN_NETWORK=mainnet
export LETSENCRYPT_EMAIL=admin@example.com
export BTCPAY_DOCKER_REPO=https://github.com/btcpayserver/btcpayserver-docker/
export BTCPAY_DOCKER_REPO_BRANCH=master
export LIGHTNING_ALIAS="my-node"
export USE_BTC=True
export USE_LTC=True
export USE_CLIGHTNING=True
export ACME_CA_URI=https://acme-v01.api.letsencrypt.org/directory
. ./entrypoint.sh
```

You can then browse https://btcpay.example.com/ and enjoy your new node and all commands documented here (like `btcpay-update.sh`) and on the [btcpay-docker](https://github.com/btcpayserver/btcpayserver-docker) repository.
