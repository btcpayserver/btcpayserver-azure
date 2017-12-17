# BTCPayServer Azure

Instructions to deploy BTCPay Server with an Microsoft Azure account.
The following instructions a [Microsoft Azure](https://azure.microsoft.com/) account.

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