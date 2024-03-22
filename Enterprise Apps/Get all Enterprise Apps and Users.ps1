#USE ONLY IN CLOUD CONSOLE
#cd ./clouddrive/PSConsoleExports/

#CONNECTS TO AZURE
Connect-AzureAD
#GETS APPS AND NAME WITH OBJECT ID
$apps = Get-AzureADServicePrincipal -All:$true |?{$_.Tags -eq "WindowsAzureActiveDirectoryIntegratedApp"}| Select-Object ObjectId,displayname

#EXTRACTS THE OBJECT ID OF ALL APPS
	$AppObjectID = $apps.objectid

#TURNS THE STRING OF OBJECTIDS INTO AN ARRAY
	$AppObjectIDArray = $AppObjectID -split " "

#PIPES EACH MEMBER OF THE ARRAY AND THEN GETS THE APP NAME AND MEMBERS, THEN EXPORTS TO CSV
$AppObjectIDArray | foreach {
Get-AzureADServiceAppRoleAssignment -ObjectId $_ | Select ResourceDisplayName,PrincipalDisplayName
	} | Export-Csv appsandusers2.csv




