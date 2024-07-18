$PolicyName = "Name Here"

##CREATES THE NEW POLICY
#CHANGE ANY OF THESE TO :FALSE OR :TRUE DEPENDING WHAT YOU WANT TO ACHIEVE
Connect-ExchangeOnline
New-AuthenticationPolicy -Name $PolicyName -AllowBasicAuthImap -AllowBasicAuthPowershell -AllowBasicAuthWebServices -AllowBasicAuthSmtp -AllowBasicAuthRpc -AllowBasicAuthActiveSync -AllowBasicAuthReportingWebServices -AllowBasicAuthAutodiscover -AllowBasicAuthMapi -AllowBasicAuthPop -AllowBasicAuthOutlookService -AllowBasicAuthOfflineAddressBook


##APPLIES THE POLICY TO THE 2 USERS
Set-User -Identity "USERNAME" -AuthenticationPolicy $PolicyName

##SHOW WHO NEW POLICY IS ASSIGNED TOO
$DN = Get-AuthenticationPolicy | Where-Object -Property Name -eq $PolicyName 
$PolicyDN = $DN.DistinguishedName
Get-User -Filter "AuthenticationPolicy -eq '$PolicyDN'"


##IF ANY ISSUES ARE FOUND
#Remove-AuthenticationPolicy -Identity $PolicyName

##CONFIRM YOUR NEW POLICY HASNT BEEN SET AS THE DEFAULT (RESULT SHOULD BE BLANK)]
Get-OrganizationConfig | Format-Table DefaultAuthenticationPolicy

Disconnect-ExchangeOnline