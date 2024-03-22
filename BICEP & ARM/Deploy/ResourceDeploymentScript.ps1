
Function Pause ($Message = "SCRIPT FINISHED. PRESS ANY KEY TO EXIT.") {
  # Check if running in PowerShell ISE
  If ($psISE) {
     # "ReadKey" not supported in PowerShell ISE.
     # Show MessageBox UI
     $Shell = New-Object -ComObject "WScript.Shell"
     $Button = $Shell.Popup("Click OK to Finish.", 0, "Checks Complete", 0)
     Return
  }

  $Ignore =
     16,  # Shift (left or right)
     17,  # Ctrl (left or right)
     18,  # Alt (left or right)
     20,  # Caps lock
     91,  # Windows key (left)
     92,  # Windows key (right)
     93,  # Menu key
     144, # Num lock
     145, # Scroll lock
     166, # Back
     167, # Forward
     168, # Refresh
     169, # Stop
     170, # Search
     171, # Favorites
     172, # Start/Home
     173, # Mute
     174, # Volume Down
     175, # Volume Up
     176, # Next Track
     177, # Previous Track
     178, # Stop Media
     179, # Play
     180, # Mail
     181, # Select Media
     182, # Application 1
     183  # Application 2

  Write-Host -NoNewline $Message
  While ($KeyInfo.VirtualKeyCode -Eq $Null -Or $Ignore -Contains $KeyInfo.VirtualKeyCode) {
     $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
  }
}

Function BicepUpgrade{
  Write-Host -ForegroundColor Red "Checking for BICEP Updates"
az bicep upgrade
}
Function ConnectAzure {
  Write-Host -ForegroundColor Red "Connecting to AZ Account"
  Connect-AzAccount
  }

Function BicepLocation {
  $global:BicepDirectory = Read-Host "Please paste the Path to the Folder hosting your BICEP Templates"
  $global:BicepFile = Read-Host "Please paste the name of the Target Bicep File"
  $global:BicepFullPath = "$BicepDirectory\$BicepFile"
  Write-Host -ForegroundColor Red "Setting the working Directory to ""$BicepDirectory"""
  Set-Location -Path $BicepDirectory
  }

Function ParamCheck {
  Write-Host -ForegroundColor Green "Are you supplying a parameter file to use with this deployment? (Default is No)"
      $UsingParam = Read-Host " ( Y / N ) "
      Switch ($UsingParam)
  {
         Y {UsingParam}
         N {NoParam}
         Default {NoParam}
  }
  }





Function DeploymentSettings {

    $Global:TargetSubscription = Read-Host "Please provide the name of the subscription you would like to deploy the template to"

    Write-Host -ForegroundColor Red "Setting subscription to ""$TargetSubscription"""
    Set-AzContext $TargetSubscription

    $Global:TargetResourceGroup = Read-Host "Please provide the name of the Resource group you would like to deploy the template to"

    Write-Host -ForegroundColor Red "Setting Resource group to ""$TargetResourceGroup"""
    Set-AzDefault -ResourceGroupName $TargetResourceGroup
}



Function UsingParam {
  $ParamDirectory = Read-Host "Please provide the path to the folder containing the parameter file you wish to use"
  $ParamFile = Read-Host "Please provide the file name of the parameter file you wish to use"
  DeploymentSettings
  $Global:DeploymentName = Read-Host "Enter a Name for this deployment - Re-using a deployment name will sync changes to those resources - a unique name will deploy all resources as new"
  $ParamFullPath = "$ParamDirectory\$ParamFile"
  Write-Host -ForegroundColor Red "Deploying ""$BicepFile"" with ""$ParamFile"""

  New-AzResourceGroupDeployment -Name $DeploymentName -TemplateFile $BicepFullPath -TemplateParameterFile $ParamFullPath
  }
Function NoParam {
DeploymentSettings
$DeploymentName = Read-Host "Enter a Name for this deployment - Re-using a deployment name will sync changes to those resources - a unique name will deploy all resources as new"
Write-Host -ForegroundColor Red "Deploying ""$BicepFile"""
New-AzResourceGroupDeployment -Name $DeploymentName -TemplateFile $BicepFullPath

  }

Function RecheckQuery{

    Write-host "Would you like to run another deployment whilst still connected to Azure? (Default is No)" -ForegroundColor Green

        $Readhost = Read-Host " ( Y / N ) "
        Switch ($ReadHost)
         {
           Y {Write-host "RERUNNING"-ForegroundColor Yellow ; BicepLocation; ParamCheck; RecheckQuery}
           N {Write-Host "COMPLETED, PRESS ANY KEY TO FINISH..."-ForegroundColor Green; break}
           Default {Write-Host "COMPLETED, PRESS ANY KEY TO FINISH..."-ForegroundColor Green; break}
         }
        }


#Call BicepUpgrade Function
BicepUpgrade

#Call ConnectAzure Function
ConnectAzure

#Call BicepLocation Function
BicepLocation

#Call ParamCheck Function
ParamCheck

#Call ReCheck Function
RecheckQuery

Write-Host -ForegroundColor Red "Disconnecting AZ Account"

Disconnect-AzAccount

#PAUSES SCRIPT TO PREVENT WINDOW CLOSING
Pause