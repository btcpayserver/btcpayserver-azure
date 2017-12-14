# This
# Assume your ran logged to azure with
# Login-AzureRmAccount 
# Then you selected your subscript with
# Get-AzureRmSubscription –SubscriptionName "your subscription" | Select-AzureRmSubscription
param([String]$ResourceGroupName)

$rg = $ResourceGroupName

$usr = ([char[]]([char]'a'..[char]'z') + ([char[]]([char]'A'..[char]'Z')) + 0..9 | Sort-Object {Get-Random})[0..8] -join ''
$pass = ([char[]]([char]'a'..[char]'z') + ([char[]]([char]'A'..[char]'Z')) + 0..9 | Sort-Object {Get-Random})[0..16] -join ''

$parameters = `
@{"adminUsername" = $usr;`
  "adminPassword" = $pass;}

New-AzureRmResourceGroup -Name $rg -Location "South Central US"
New-AzureRmResourceGroupDeployment -ResourceGroupName $rg -TemplateFile "azuredeploy.json" -TemplateParameterObject $parameters


$site = (Get-AzureRmPublicIpAddress -ResourceGroupName $rg).DnsSettings.Fqdn

$cmd = "ssh $usr@$site"

$temp = "Username: $usr`n"
$temp += "Password: $pass`n"
$temp += "Machine address: $site`n"
$temp += "Command line: $cmd`n"
$temp += "Command line copied to keyboard"

Write-Host $temp

# Copy link of VM to clipboard
$cmd | Set-Clipboard