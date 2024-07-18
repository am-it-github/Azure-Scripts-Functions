#Connect to Azure
Connect-AzureAD

#Change below to UPN
$user = Get-AzureADUser -ObjectId "Username"

#Check existing policy (Should be Blank originally)
Get-AzureADUser -ObjectId $user.ObjectId | Select-Object PasswordPolicies

#Set PW to not expire
Set-AzureADUser -ObjectId $user.ObjectId -PasswordPolicies "DisablePasswordExpiration"

#Check existing policy (Should now show DisablePasswordExpiration)
Get-AzureADUser -ObjectId $user.ObjectId | Select-Object PasswordPolicies

Disconnect-AzureAD