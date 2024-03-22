$TargetSubscription = Read-Host "Enter Subscription hosting the targets"
$resourceGroupName = Read-Host "Enter resource group name"
$resourceName = Read-Host "Enter resource name"
$resourceType = Read-Host "Enter resource type"
$ExportPath = Read-Host "Enter Export file location"

Connect-AzAccount

Set-AzContext -Subscription $TargetSubscription

$resource = Get-AzResource `
  -ResourceGroupName $resourceGroupName `
  -ResourceName $resourceName `
  -ResourceType $resourceType

Export-AzResourceGroup `
  -ResourceGroupName $resourceGroupName `
  -Resource $resource.ResourceId `
  -Path $ExportPath `
  -Force
