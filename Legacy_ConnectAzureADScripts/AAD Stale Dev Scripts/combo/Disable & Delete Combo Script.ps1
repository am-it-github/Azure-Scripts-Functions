##THIS CONNECTS TO AZUREAD USING THE LEGACY CONNECT-AZUREAD CMDLET
Connect-AzureAD


#change where applicable, will take wildcards with *
$DevExclusion1 = "NAMETOEXCLUDE1"
$DevExclusion2 = "NAMETOEXCLUDE2"
$DevExclusion3 = "NAMETOEXCLUDE3"
$DevExclusion4 = "*NAMETOEXCLUDE4"



$DateToDisable = (Get-Date).AddDays(-30)
$DateToDelete = (Get-Date).AddDays(-60)


Write-Output  "Collecting all devices to disable, those last seen before ""$DateToDisable"" (US Date Format)"
Write-Output  "This will take a while..."
$DevicestoDisable = Get-AzureADDevice -All:$true | Where {($_.DisplayName -notlike $DevExclusion1) -and ($_.DisplayName -notlike $DevExclusion2) -and ($_.DisplayName -notlike $DevExclusion3) -and ($_.DisplayName -notlike $DevExclusion4) -and ($_.ApproximateLastLogonTimeStamp -le $DateToDisable) -and ($_.AccountEnabled -eq $true) -and ($_.ApproximateLastLogonTimeStamp -ne $null)}
$DevTable1 = $DevicestoDisable | Select DisplayName, ApproximateLastLogonTimeStamp | Sort-Object -Property ApproximateLastLogonTimeStamp | ft
Write-Output  "Setting below devices to ""Disabled"" in AAD"
$DevTable1
foreach ($Device in $DevicestoDisable) {Set-AzureADDevice -ObjectId $Device.ObjectId -AccountEnabled $false}

Write-Output  "Collecting all devices to delete, pre-disabled devices last seen before ""$DateToDelete"" (US Date Format)"
$DevicestoDelete = Get-AzureADDevice -All:$true | Where {($_.DisplayName -notlike $DevExclusion1) -and ($_.DisplayName -notlike $DevExclusion2) -and ($_.DisplayName -notlike $DevExclusion3) -and ($_.DisplayName -notlike $DevExclusion4) -and ($_.ApproximateLastLogonTimeStamp -le $DateToDelete) -and ($_.AccountEnabled -eq $false) -and ($_.ApproximateLastLogonTimeStamp -ne $null)}
$DevTable2 = $DevicestoDelete | Select DisplayName, ApproximateLastLogonTimeStamp | Sort-Object -Property ApproximateLastLogonTimeStamp | ft
Write-Output  "Deleting below devices in AAD"
$DevTable2
foreach ($Device in $DevicestoDelete) {Remove-AzureADDevice -ObjectId $Device.ObjectId }


Disconnect-AzureAD