# Prompt for the Azure tenant and subscription context
$tenantId = Read-Host "Enter the Azure tenant ID"
$subscriptionId = Read-Host "Enter the Azure subscription ID"
Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId

# Define the resource group name and web app name
$resourceGroupName = Read-Host "Enter the resource group name"
$webAppName = Read-Host "Enter the web app name"

# Get the web app object
$webApp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName

# Get the private IP address of the web app
$privateIp = $webApp.SiteConfig.AppSettings["WEBSITE_PRIVATE_IP"]

# Output the private IP address
Write-Output "The private IP address of the web app $webAppName is $privateIp."
