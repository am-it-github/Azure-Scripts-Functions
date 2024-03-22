Param(
    [Parameter(mandatory=$true)]
    [Int]$Days_unseen_to_Disable = 360,
    [Switch]$Delete_Old_Devices_True_or_False = $False,
    [Int]$Days_unseen_to_Delete = 1000
    )




##BELOW CONVERTS AN AZURE MANAGED ID CONNECT-AZACCOUNT SIGN IN TOKEN TO SOMETHING THAT CAN BE USED BY THE CONNECT-AZUREAD CMDLET FOR THOSE COMMANDS NOT YET MOVED OVER
$outnull = Connect-azaccount -identity -ErrorAction Stop
$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
$graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
Write-Output "Confirming script is running as System Managed ID"
Write-Output "Running as $($context.Account.Id)"



##THIS CONNECTS TO AZUREAD USING THE LEGACY CONNECT-AZUREAD CMDLET PASSING THE MANAGED ID 
Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id



$DateToDisable = (Get-Date).AddDays(-$Days_unseen_to_Disable)
Write-Output  "Collecting all devices to disable, those last seen before ""$DateToDisable"" (US Date Format)"
Write-Output  "This will take a while..." 
$DevicestoDisable = Get-AzureADDevice -All:$true | Where {($_.ApproximateLastLogonTimeStamp -le $DateToDisable) -and ($_.AccountEnabled -eq $true) -and ($_.ApproximateLastLogonTimeStamp -ne $null)} 
$DevTable1 = $DevicestoDisable | Select DisplayName, ApproximateLastLogonTimeStamp | Sort-Object -Property ApproximateLastLogonTimeStamp | ft
Write-Output  "Setting below devices to ""Disabled"" in AAD"
$DevTable1
foreach ($Device in $DevicestoDisable) {Set-AzureADDevice -ObjectId $Device.ObjectId -AccountEnabled $false}

if($Delete_Old_Devices_True_or_False -eq $true){
$DateToDelete = (Get-Date).AddDays(-$Days_unseen_to_Delete)
Write-Output  "Collecting all devices to delete, pre-disabled devices last seen before ""$DateToDelete"" (US Date Format)"
$DevicestoDelete = Get-AzureADDevice -All:$true | Where {($_.ApproximateLastLogonTimeStamp -le $DateToDelete) -and ($_.AccountEnabled -eq $false) -and ($_.ApproximateLastLogonTimeStamp -ne $null)} 
$DevTable2 = $DevicestoDelete | Select DisplayName, ApproximateLastLogonTimeStamp | Sort-Object -Property ApproximateLastLogonTimeStamp | ft
Write-Output  "Deleting below devices in AAD"
$DevTable2
foreach ($Device in $DevicestoDelete) {Remove-AzureADDevice -ObjectId $Device.ObjectId }
}

Disconnect-AzureAD