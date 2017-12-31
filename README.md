# BTCPayServer Azure

Instructions to deploy BTCPay Server in [production environment](https://github.com/btcpayserver/btcpayserver-docker/tree/master/Production) hosted in Microsoft Azure.

The following instructions assume you have [Microsoft Azure](https://azure.microsoft.com/) subscription.

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
. changedomain.sh blah.example.com
```

This will change the settings of BTCPay and NGinx to use your domain. Upon restart, a new certificate for your domain will be requested by Let's encrypt.
