

Write-Host -ForegroundColor Yellow "THIS SCRIPT IS DESIGNED TO CONNECT TO AN AZURE TENANT AND SUBSCRIPTION YOU PROVIDE, AND POINT LOGS TO A NEW OR EXISTING STORAGE ACCOUNT FOR KEYVAULT LOGS IN THE SAME SUB"
$UsingExistingSA = Read-Host "Are you using an existing Storage Account (yes or no)"

#IF NOT USING AN EXISTING SA THIS WILL CREATE ONE AND ENABLE LOGS TO USE IT
If ($UsingExistingSA -eq "no"){
Write-Host -ForegroundColor Yellow "YOU WILL BE PROMPTED FOR THE BELOW WHEN PROCEEDING WITH THE SCRIPT - TO MITIGATE ERRORS USE COPY AND PASTE FROM THE ARM PORTAL:" -NoNewline
Write-Host -ForegroundColor Magenta "
TARGET TENANT ID,
TARGET SUBSCRIPTION ID,
EXISTING RESOURCE GROUP NAME,
EXISTING KEY VAULT NAME,
NEW STORAGE ACCOUNT NAME,
NEW STORAGE ACCOUNT REGION,
DESIRED LOG RETENTION TIME"

Pause

#CHANGE THE BELOW BASED ON REQS
    $TenantID = Read-Host -Prompt "Enter the target Tenant ID (Can be Obtained under Tenant Properties in the Azure Portal)"
    $subID = Read-Host -Prompt "Enter the Subscription ID hosting the Key Vault (Can be obtained under Subscriptions in the Azure Portal)"
    $ResourceGroup = Read-Host -Prompt "Enter the name of the EXISTING Resource group you would like to create the new Storage account in for your Keyvault Logs"
    $Keyvault = Read-Host -Prompt "Enter the name of the keyvault you wish to enable auding on"
    $retentiontime = Read-Host -Prompt "Enter the number of days you wish to retain logs"
    $SAName = Read-Host -Prompt "Enter the name for the new Storage account - it must contain between 3 and 24 characters - lower case letters and numbers only"
    $location = Read-Host -Prompt "Enter the Region (uksouth or ukwest)"

#CONNECTS TO AZURE AND PROMPTS FOR CREDS - INFORMS USER OF THIS
   Write-Host -ForegroundColor Red "IF YOU GET ERRORS WITH THE CMDLET ""GET-AZACCOUNT"" NOT BEING RECOGNISED, YOU MAY HAVE THE INCORRECT AZ MODULE INSTALLED
REMOVE IT FROM CONTROL PANEL AND REINSTALL USING CMDLET ""Install-Module -Name Az -Force"""
   Write-Host -ForegroundColor Green "Connecting to Azure Tenant" -NoNewLine
   Write-Host -ForegroundColor Magenta " $tenantID"
    Connect-AzAccount -Tenant $TenantID | Out-Null

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
   Write-Host -ForegroundColor Green "storing logs in" -NoNewLine
   Write-Host -ForegroundColor Magenta " $SAName" -NoNewLine
   Write-Host -ForegroundColor Green " with" -NoNewLine
   Write-Host -ForegroundColor Magenta " $retentiontime" -NoNewLine
   Write-Host -ForegroundColor Green " days logs being retained"-NoNewLine
    Set-AzDiagnosticSetting -ResourceId $KeyvaultID.ResourceId -StorageAccountId $sa.id -Enabled $true -Category "AuditEvent" -RetentionEnabled $true -RetentionInDays $retentiontime -WarningAction:SilentlyContinue


    }


#IF AN EXISTING SA IS BEING USED, THIS OMMITS THE PART THAT CREATES ONE
Else{
Write-Host -ForegroundColor Yellow "YOU WILL BE PROMPTED FOR THE BELOW WHEN PROCEEDING WITH THE SCRIPT - TO MITIGATE ERRORS USE COPY AND PASTE FROM THE ARM PORTAL:"
Write-Host -ForegroundColor Magenta "
TARGET TENANT ID,
TARGET SUBSCRIPTION ID,
EXISTING RESOURCE GROUP NAME,
EXISTING KEY VAULT NAME,
EXISTING STORAGE ACCOUNT NAME,
DESIRED LOG RETENTION TIME"

Pause

#CHANGE THE BELOW BASED ON REQS
    $TenantID = Read-Host -Prompt "Enter the target Tenant ID (Can be Obtained under Tenant Properties in the Azure Portal)"
    $subID = Read-Host -Prompt "Enter the Subscription ID hosting the Key Vault (Can be obtained under Subscriptions in the Azure Portal)"
    $ResourceGroup = Read-Host -Prompt "Enter the name of the EXISTING Resource group you would like to create the new Storage account in for your Keyvault Logs"
    $Keyvault = Read-Host -Prompt "Enter the name of the keyvault you wish to enable auding on"
    $SAName = Read-Host -Prompt "Enter the name of the EXISTING Storage account"
    $retentiontime = Read-Host -Prompt "Enter the number of days you wish to retain logs"


#CONNECTS TO AZURE AND PROMPTS FOR CREDS - INFORMS USER OF THIS
   Write-Host -ForegroundColor Red "IF YOU GET ERRORS WITH THE CMDLET ""GET-AZACCOUNT"" NOT BEING RECOGNISED, YOU MAY HAVE THE INCORRECT AZ MODULE INSTALLED
REMOVE IT FROM CONTROL PANEL AND REINSTALL USING CMDLET ""Install-Module -Name Az -Force"""
   Write-Host -ForegroundColor Green "Connecting to Azure Tenant" -NoNewLine
   Write-Host -ForegroundColor Magenta " $tenantID"
    Connect-AzAccount -Tenant $TenantID | Out-Null

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
   Write-Host -ForegroundColor Green "storing logs in" -NoNewLine
   Write-Host -ForegroundColor Magenta " $SAName" -NoNewLine
   Write-Host -ForegroundColor Green " with" -NoNewLine
   Write-Host -ForegroundColor Magenta " $retentiontime" -NoNewLine
   Write-Host -ForegroundColor Green " days logs being retained"-NoNewLine
    Set-AzDiagnosticSetting -ResourceId $KeyvaultID.ResourceId -StorageAccountId $sa.id -Enabled $true -Category "AuditEvent" -RetentionEnabled $true -RetentionInDays $retentiontime -WarningAction:SilentlyContinue
}





   Write-Host -ForegroundColor Yellow "Script will now pause so you can check the above in the ARM Portal and ensure it has been created correctly
PS Will Disconnect your account upon continuing"
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