Write-Host "Connecting to Azure"
Connect-AzAccount

Write-Host "Exporting untagged resources to a CSV file and the terminal"
Write-Host "*************************************************************"

$tenantId = Read-Host "Provide the Tenant ID to check for untagged resources (All Subscriptions will be checked)"
$filePath = Read-Host "Provide the folder path and file name for the csv"

$results = @()

$subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId } | Where-Object { $_.Name -notlike "*Visual Studio*" }
foreach ($subscription in $subscriptions) {
  Select-AzSubscription -SubscriptionId $subscription.Id

  Write-Host "Getting resources for subscription: $($subscription.Name)"
  $Resources = Get-AzResource
  foreach($resource in $resources){
      if ($null -eq $resource.Tags)
      {
          Write-Output "Resource Name: $($resource.Name), Resource Type: $($resource.ResourceType), Resource Group: $($resource.ResourceGroupName), Subscription: $($subscription.Name)"
          $result = [PSCustomObject] @{
            'Resource Name' = $resource.Name
            'Resource Type' = $resource.ResourceType
            'Resource Group' = $resource.ResourceGroupName
            'Subscription' = $subscription.Name
          }
          $results += $result
      }
  }
}

$results | Export-Csv $filePath -NoTypeInformation
