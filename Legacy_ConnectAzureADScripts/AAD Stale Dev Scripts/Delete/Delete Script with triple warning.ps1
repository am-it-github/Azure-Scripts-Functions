$path = "input path for csv export"

Connect-AzureAD
$dt = (Get-Date).AddDays(-160) 
Write-Host -ForegroundColor Green "Setting the check for last activity date to ""$dt"" (US Date Format)"

Write-Host -ForegroundColor Green "Collecting all DISABLED devices last seen before ""$dt"" (US Date Format) NOTE THIS SCRIPT WILL NOT INCLUDE DEVICES WITH AN NA CHECK IN DATE"
Write-Host -ForegroundColor Red "This will take a while..." 


$Devices = Get-AzureADDevice -All:$true | Where {($_.ApproximateLastLogonTimeStamp -le $dt) -and ($_.AccountEnabled -eq $false) -and ($_.ApproximateLastLogonTimeStamp -ne $null)} 

#BELOW EXPORTS THE IN SCOPE DEVICES TO A CSV IN ORDER TO KEEP TRACK OF WHATS BEEN DELETED
$CSV = $Devices | Select DisplayName, AccountEnabled, ApproximateLastLogonTimeStamp 
$csv | Export-csv "$path" -NoTypeInformation

Write-Host -ForegroundColor Green "Script will now pause before continuing - Please check date is correct"
Write-Host -ForegroundColor Green "Upon continuing the following devices will be DELETED, the table presented is sorted by date from oldest to newest"
Write-Host -ForegroundColor Green "Ensure no objects are beyond the desired date."

Pause

$DevTable = $Devices | Select DisplayName, AccountEnabled, ApproximateLastLogonTimeStamp | Sort-Object -Property ApproximateLastLogonTimeStamp | ft 

$DevTable

Pause

Write-Host -ForegroundColor Red "UPON CONTINUING THE LIST OF DEVICES ABOVE WILL PERMANENTLY BE DELETED FROM AAD - ARE YOU SURE YOU WISH TO CONTINUE?! DEFAULT IS NO"
$ContCheck1 = Read-Host " ( Y / N ) " 

If ($ContCheck1 -eq "n"){
Write-Host -ForegroundColor Green "Disconnecting from Azure AD and terminating script"
Disconnect-AzureAd
Break
}

If ($ContCheck1 -eq "y"){
Write-Host -ForegroundColor Red "JUST DOUBLE CHECKING.... ARE YOU SURE YOU WISH TO DELETE THE ABOVE DEVICES?! DEFAULT IS NO"
$ContCheck2 = Read-Host " ( Y / N ) "


If ($ContCheck2 -eq "n"){
Write-Host -ForegroundColor Green "Disconnecting from Azure AD and terminating script"
Disconnect-AzureAd
Break
}

If ($ContCheck2 -eq "y"){
Write-Host -ForegroundColor Red "FINAL WARNING, DO YOU REALLY WISH TO PERMANENTLY DELETE THE ABOVE DEVICES. CONFIRM AND PRESS ENTER TO BEING DELETION DEFAULT IS NO"
$ContCheck3 = Read-Host " ( Y / N ) "

If ($ContCheck3 -eq "n"){
Write-Host -ForegroundColor Green "Disconnecting from Azure AD and terminating script"
Disconnect-AzureAd
Break
}

If ($ContCheck3 -eq "y"){
Pause
Write-Host -ForegroundColor Red "DELETING DEVICES"
foreach ($Device in $Devices) { Remove-AzureADDevice -ObjectId $Device.ObjectId }
}
}
}


Write-Host -ForegroundColor Red "DISCONNECTING FROM AZURE AD"
Disconnect-AzureAD