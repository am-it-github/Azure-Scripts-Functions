###   VERSION 2 OF THE SCRIPT
###   THIS VERSION CONTAINS ALL PREVIOUS PARTS STORED AS FUNCTIONS, A NEW CHECK TO SEE IF A NEW OR EXISTING STORAGE ACCOUNT IS GOING TO BE USED,
###   AS WELL AS A MODULE VERSION CHECK AND A FUNCTION
###   TO CHECK IF THE OPERATING USER WANTS TO RERUN THE KEYVAULT PROCESS WITHOUT NEEDING TO FULLY RECONNECT TO THE TENANT EACH TIME



#####STORED FUNCTIONS START


##FUNCTION TO CHECK FOR CORRECT PS MODULE BEING INSTALLED
Function ModuleCheck{
Write-Host -ForegroundColor Yellow "RUNNING PRE-REQ MODULE VERSION CHECK"
$AZModule = Get-InstalledModule Az


If($AZModule.Version -ne "7.5.0"){
Write-Host -ForegroundColor Red "INCORRECT VERSION OF AZ MODULE INSTALLED, SCRIPT WILL NOT RUN CORRECTLY. PLEASE INSTALL CORRECT VERSION AND RETRY SCRIPT"
Write-Host -ForegroundColor Red "THIS CAN BE ACHIEVED BY RUNNING THE FOLLOWING CMDLET AS A LOCAL ADMIN IN POWERSHELL ""Install-Module -Name Az -RequiredVersion 7.5.0 -Force"""
Write-Host -ForegroundColor Red "SCRIPT WILL NOW PAUSE SO YOU CAN COPY THE INSTALL CMDLET. PS WILL CLOSE UPON PRESSING ENTER"
Pause
Break
}

Write-Host -ForegroundColor Green "AZ MODULE V 7.5.0 INSTALLED....CONTINUING TASK SEQUENCE"

}


##FUNCTION TO BE CALLED ELSEWHERE TO GET TENANT ID AND SUB
Function ObtainWorkingDirAndConnect{
Write-Host -ForegroundColor Yellow "YOU WILL FIRST BE PROMPTED FOR THE TARGET TENANT ID TO CONNECT TO - TO MITIGATE ERRORS USE COPY AND PASTE FROM THE ARM PORTAL:"
Write-Host -ForegroundColor Magenta "TARGET TENANT ID"
$TenantID = Read-Host -Prompt "Enter the target Tenant ID (Can be Obtained under Tenant Properties in the Azure Portal)"


#CONNECTS TO AZURE AND PROMPTS FOR CREDS - INFORMS USER OF THIS
   Write-Host -ForegroundColor Red "IF YOU GET ERRORS WITH THE CMDLET ""GET-AZACCOUNT"" NOT BEING RECOGNISED, YOU MAY HAVE THE INCORRECT AZ MODULE INSTALLED
REMOVE IT FROM CONTROL PANEL AND REINSTALL USING CMDLET ""Install-Module -Name Az -Force"""
   Write-Host -ForegroundColor Green "Connecting to Azure Tenant" -NoNewLine
   Write-Host -ForegroundColor Magenta " $tenantID"
    Connect-AzAccount -Tenant $TenantID | Out-Null
}


##FUNCTION TO BE CALLED ELSEWHERE WHEN USING NEW GROUP
#IF NO SA EXISTS THIS CREATES ONE AND ENABLES LOGGING
Function CreateNewGroupEnableLogging{
Write-Host -ForegroundColor Yellow "YOU WILL BE PROMPTED FOR THE BELOW WHEN PROCEEDING WITH THE SCRIPT - TO MITIGATE ERRORS USE COPY AND PASTE FROM THE ARM PORTAL:" -NoNewline
Write-Host -ForegroundColor Magenta "TARGET SUBSCRIPTION ID
EXISTING RESOURCE GROUP NAME,
EXISTING KEY VAULT NAME,
NEW STORAGE ACCOUNT NAME,
NEW STORAGE ACCOUNT REGION,
DESIRED LOG RETENTION TIME"

Pause

#CHANGE THE BELOW BASED ON REQS
    $subID = Read-Host -Prompt "Enter the Subscription ID hosting the Key Vault (Can be obtained under Subscriptions in the Azure Portal)"
    $ResourceGroup = Read-Host -Prompt "Enter the name of the EXISTING Resource group you would like to create the new Storage account in for your Keyvault Logs"
    $Keyvault = Read-Host -Prompt "Enter the name of the keyvault you wish to enable auding on"
    $SAName = Read-Host -Prompt "Enter the name for the new Storage account - it must contain between 3 and 24 characters - lower case letters and numbers only"
    $location = Read-Host -Prompt "Enter the Region (uksouth or ukwest)"
    $retentiontime = Read-Host -Prompt "Enter the number of days you wish to retain logs"


#SET THE WORKING SUBSCRIPTION - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Setting the working Subscription to" -NoNewLine
   Write-Host -ForegroundColor Magenta " $subId"
    Set-AzContext -SubscriptionId $subID | Out-Null

#BELOW MAKES A NEW SA FOR THE KEY VAULT LOGS - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Creating a new Standard Storage Account in" -NoNewline
   Write-Host -ForegroundColor Magenta " $ResourceGroup" -NoNewline
   Write-Host -ForegroundColor Green " called" -NoNewLine
   Write-Host -ForegroundColor Magenta " $SAName" -NoNewLine
   Write-Host -ForegroundColor Green " in region" -NoNewLine
   Write-Host -ForegroundColor Magenta " $location"
   Write-Host -ForegroundColor Red "This can take up to 30 seconds - don't panic if it looks stuck"
    New-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $SAName -Type "Standard_LRS" -Location $location | Out-Null

#BELOW OBTAINS STORAGE ACCOUNT ID AND THEN SETS IT AS THE VARIABLE $sa.id - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Obtaining the Resource ID for" -NoNewLine
   Write-Host -ForegroundColor Magenta " $SAName"
    $sa = Get-AzStorageAccount -Name $SAName -ResourceGroup $ResourceGroup
    $sa.id | Out-Null

#BELOW WILL THEN GET THE RELEVANT KEYVAULT YOU WANT TO ENABLE LOGGING ON - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Obtaining the Resource ID for" -NoNewLine
   Write-Host -ForegroundColor Magenta " $KeyVault"
    $KeyvaultID = Get-AzKeyVault -VaultName $Keyvault -WarningAction:SilentlyContinue
    $KeyvaultID.ResourceId | Out-Null

#BELOW WILL THEN SET AUDITING TO ENABLED (WITH NO MAX RETENTION TIME)
    #Set-AzDiagnosticSetting -ResourceId $Keyvault.ResourceId -StorageAccountId $sa.id -Enabled $true -Category "AuditEvent"

#BELOW SETS SAME AS ABOVE BUT WILL SET A RETENTION TIME SET ABOVE - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Enabling Logging for" -NoNewLine
   Write-Host -ForegroundColor Magenta " $Keyvault," -NoNewLine
   Write-Host -ForegroundColor Green " storing logs in" -NoNewLine
   Write-Host -ForegroundColor Magenta " $SAName" -NoNewLine
   Write-Host -ForegroundColor Green " with" -NoNewLine
   Write-Host -ForegroundColor Magenta " $retentiontime" -NoNewLine
   Write-Host -ForegroundColor Green " days logs being retained"-NoNewLine
    Set-AzDiagnosticSetting -ResourceId $KeyvaultID.ResourceId -StorageAccountId $sa.id -Enabled $true -Category "AuditEvent" -RetentionEnabled $true -RetentionInDays $retentiontime -WarningAction:SilentlyContinue

}


##FUNCTION TO BE CALLED ELSEWHERE WHEN USING EXISING GROUP
#IF AN EXISTING SA IS BEING USED, THIS OMMITS THE PART THAT CREATES ONE
Function UseExistingGroupEnableLogging{
Write-Host -ForegroundColor Yellow "YOU WILL BE PROMPTED FOR THE BELOW WHEN PROCEEDING WITH THE SCRIPT - TO MITIGATE ERRORS USE COPY AND PASTE FROM THE ARM PORTAL:"
Write-Host -ForegroundColor Magenta "TARGET SUBSCRIPTION ID
EXISTING RESOURCE GROUP NAME,
EXISTING KEY VAULT NAME,
EXISTING STORAGE ACCOUNT NAME,
DESIRED LOG RETENTION TIME"

Pause
    $subID = Read-Host -Prompt "Enter the Subscription ID hosting the Key Vault (Can be obtained under Subscriptions in the Azure Portal)"
    $ResourceGroup = Read-Host -Prompt "Enter the name of the EXISTING Resource group you would like to create the new Storage account in for your Keyvault Logs"
    $Keyvault = Read-Host -Prompt "Enter the name of the keyvault you wish to enable auding on"
    $SAName = Read-Host -Prompt "Enter the name of the EXISTING Storage account"
    $retentiontime = Read-Host -Prompt "Enter the number of days you wish to retain logs"


 #SET THE WORKING SUBSCRIPTION - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Setting the working Subscription to" -NoNewLine
   Write-Host -ForegroundColor Magenta " $subId"
    Set-AzContext -SubscriptionId $subID | Out-Null

#BELOW OBTAINS A STORAGE ACCOUNT WITHIN A SUB AND RG, PULLS THE ID AND THE SETS IT AS THE VARIABLE $sa.id - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Obtaining the Resource ID for" -NoNewLine
   Write-Host -ForegroundColor Magenta " $SAName"
    $sa = Get-AzStorageAccount -Name $SAName -ResourceGroup $ResourceGroup
    $sa.id | Out-Null

#BELOW WILL THEN GET THE RELEVANT KEYVAULT YOU WANT TO ENABLE LOGGING ON - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Obtaining the Resource ID for" -NoNewLine
   Write-Host -ForegroundColor Magenta " $KeyVault"
    $KeyvaultID = Get-AzKeyVault -VaultName $Keyvault -WarningAction:SilentlyContinue
    $KeyvaultID.ResourceId | Out-Null

#BELOW WILL THEN SET AUDITING TO ENABLED (WITH NO MAX RETENTION TIME)
    #Set-AzDiagnosticSetting -ResourceId $Keyvault.ResourceId -StorageAccountId $sa.id -Enabled $true -Category "AuditEvent"

#BELOW SETS SAME AS ABOVE BUT WILL SET A RETENTION TIME SET ABOVE - INFORMS USER OF THIS
   Write-Host -ForegroundColor Green "Enabling Logging for" -NoNewLine
   Write-Host -ForegroundColor Magenta " $Keyvault," -NoNewLine
   Write-Host -ForegroundColor Green " storing logs in" -NoNewLine
   Write-Host -ForegroundColor Magenta " $SAName" -NoNewLine
   Write-Host -ForegroundColor Green " with" -NoNewLine
   Write-Host -ForegroundColor Magenta " $retentiontime" -NoNewLine
   Write-Host -ForegroundColor Green " days logs being retained"-NoNewLine
    Set-AzDiagnosticSetting -ResourceId $KeyvaultID.ResourceId -StorageAccountId $sa.id -Enabled $true -Category "AuditEvent" -RetentionEnabled $true -RetentionInDays $retentiontime -WarningAction:SilentlyContinue
}


##FUNCTION THAT RUNS THE CHECK FOR GROUP, THEN THE RELEVANT FUNCTION FROM ABOVE
#RUNS CHECK FOR EXISTING SA, THEN RUNS THROUGH ONE OF ABOVE FUNCTIONS
Function EnableKVLoggingTaskSet{
#CALLS ABOVE FUNCTION TO CHECK PARAMETERS OF REQUEST
Write-Host -ForegroundColor Yellow "Are you using an existing Storage Account"
$UsingExistingSA = Read-Host " ( Y / N ) "

#IF NOT USING AN EXISTING SA CALL FUNCTION THAT CREATES ONE AND ENABLES LOGGING
If ($UsingExistingSA -eq "n"){CreateNewGroupEnableLogging}

#IF USING AN EXISTING GROUP CALL FUNCTION THAT ENABLES LOGGING ONLY
Else{UseExistingGroupEnableLogging}
}


##FUNCTION TO BE CALLED ELSEWHERE TO SEE IF TASKSET IS TO BE RUN AGAIN
#CURRENTLY TESTING AND MAY NOT WORK AS INTENDED
Function RecheckQuery{

Write-host "Would you like to run this on a different vault? (Default is No)" -ForegroundColor Yellow

    $Readhost = Read-Host " ( Y / N ) "
    Switch ($ReadHost)
     {
       Y {Write-host "Running existing group check"-ForegroundColor Yellow ; $recheck=$true; EnableKVLoggingTaskSet; RecheckQuery}
       N {Write-Host "Script Completed"-ForegroundColor Yellow; $recheck=$false; break}
       Default {Write-Host "Script Completed"-ForegroundColor Yellow; $recheck=$false; break}
     }

}


##FUNCTION TO BE CALLED ELSEWHERE WHICH DISCONNECT AZ AND CLEARS VARIABLES
Function DisconnectAndClean{
##SANITISES THE VARIABLES AND DISCONNECTS THE SESSION
   Write-Host -ForegroundColor Yellow "Script will now pause so you can check the above in the ARM Portal and ensure it has been created correctly"
   Write-Host -ForegroundColor Red "PS Will Disconnect your account upon continuing"
Pause

#DISCONNECTS THE AZ ACCOUNT
   Write-Host -ForegroundColor Green "Disconnecting from Azure"
    Disconnect-AzAccount | Out-Null

#NULLS VARIABLES TO REDUCE FUTURER ERRORS
   Write-Host -ForegroundColor Green "Nulling Variables"
    $TenantID = ""
    $subID = ""
    $ResourceGroup = ""
    $Keyvault = ""
    $KeyvaultID = ""
    $sa = ""
    $SAName = ""
    $location = ""
    $retentiontime = ""
    }


#####STORED FUNCTIONS END




#####SCRIPT SEQUENCE START


#INFORMS USER OF THE PURPOSE OF THIS SCRIPT AND WHAT THEY WILL REQUIRE
Write-Host -ForegroundColor Yellow
"THIS SCRIPT IS DESIGNED TO CONNECT TO AN AZURE TENANT AND SUBSCRIPTION YOU PROVIDE, AND POINT LOGS TO A NEW OR EXISTING STORAGE ACCOUNT FOR KEYVAULT LOGS IN THE SAME SUB"


#CALLS ABOVE FUNCTION TO CHECK THE CORRECT PS MODULE IS INSTALLED
ModuleCheck


#CALLS ABOVE FUNCTION TO SET WORKING TENANT AND SIGN IN TO AZ
ObtainWorkingDirAndConnect


#CALLS ABOVE FUNCTION TO RUN THROUGH CHECK THEN CREATION OR EXISTING SA
EnableKVLoggingTaskSet


#CALLS ABOVE FUNCTION TO CHECK IF USER WISHES TO RERUN ON ANOTHER KEYVAULT
RecheckQuery


#IF USER DOES NOT WISH TO RUN IT AGAIN DISCONNECTS FROM AZ AND NULLS ALL VARIABLES
DisconnectAndClean


Write-Host -ForegroundColor Red "Script will terminate and close upon continuing"
Pause


#####SCRIPT SEQUENCE END
