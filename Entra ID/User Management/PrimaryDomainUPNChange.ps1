# Requires Microsoft Graph PowerShell SDK
# Install once if needed:
# Install-Module Microsoft.Graph -Scope CurrentUser


# THIS SCRIPT CONNECTS TO GRAPH, AND CHANGES USERS PRIMARY UPNS FROM SOURCEDOMAIN TO TARGETDOMAIN
# THE SCRIPT EXPECTS A CSV IN THE SAME FORMAT AS THAT EXPORTED FROM THE GUI OR USING THE GETCOMPANYUSERS.PS1 SCRIPT


# -----------------------------
# VARIABLES - EDIT THESE
# -----------------------------
$CsvPath                   = "C:\Temp\TESTUserExportTEST.csv"
$SourceDomain              = "CHANGE ME (WHAT THE DOMAIN ALREADY IS)"
$TargetDomain              = "CHANGE ME (WHAT YOU WANT TO CHANGE IT TO)"
$RequiredCompanyName       = "CHANGE ME" # THIS IS A FAILSAFE CATCH
$RequireSourceDomainMatch  = $true # THIS IS A SECOND FAILSAFE

# -----------------------------
# CONNECT TO GRAPH
# -----------------------------
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Authentication

Connect-MgGraph -Scopes "User.ReadWrite.All" -NoWelcome

# -----------------------------
# LOAD CSV
# -----------------------------
if (-not (Test-Path $CsvPath)) {
    throw "CSV not found: $CsvPath"
}

$csvUsers = Import-Csv -Path $CsvPath

if (-not $csvUsers) {
    throw "CSV is empty."
}

# Validate required CSV columns
$requiredColumns = @("id", "displayName", "userPrincipalName", "companyName")
$missingColumns = $requiredColumns | Where-Object { $_ -notin $csvUsers[0].PSObject.Properties.Name }

if ($missingColumns) {
    throw "CSV is missing required column(s): $($missingColumns -join ', ')"
}

# -----------------------------
# BUILD PREVIEW
# -----------------------------
$results = New-Object System.Collections.Generic.List[object]

foreach ($row in $csvUsers) {
    $csvId                = ($row.id).Trim()
    $csvDisplayName       = ($row.displayName).Trim()
    $csvCurrentUpn        = ($row.userPrincipalName).Trim()
    $csvCompanyName       = ($row.companyName).Trim()

    if ([string]::IsNullOrWhiteSpace($csvId)) {
        $results.Add([pscustomobject]@{
            Id              = $csvId
            DisplayName     = $csvDisplayName
            CurrentUPN      = $csvCurrentUpn
            TargetUPN       = $null
            CompanyName     = $csvCompanyName
            Status          = "Skipped"
            Reason          = "Blank id in CSV"
        })
        continue
    }

    try {
        $user = Get-MgUser -UserId $csvId -Property "id,displayName,userPrincipalName,companyName,onPremisesSyncEnabled"
    }
    catch {
        $results.Add([pscustomobject]@{
            Id              = $csvId
            DisplayName     = $csvDisplayName
            CurrentUPN      = $csvCurrentUpn
            TargetUPN       = $null
            CompanyName     = $csvCompanyName
            Status          = "Skipped"
            Reason          = "User not found in Entra by id"
        })
        continue
    }

    if (-not $user) {
        $results.Add([pscustomobject]@{
            Id              = $csvId
            DisplayName     = $csvDisplayName
            CurrentUPN      = $csvCurrentUpn
            TargetUPN       = $null
            CompanyName     = $csvCompanyName
            Status          = "Skipped"
            Reason          = "User not found in Entra by id"
        })
        continue
    }

    if ($user.OnPremisesSyncEnabled -eq $true) {
        $results.Add([pscustomobject]@{
            Id              = $user.Id
            DisplayName     = $user.DisplayName
            CurrentUPN      = $user.UserPrincipalName
            TargetUPN       = $null
            CompanyName     = $user.CompanyName
            Status          = "Skipped"
            Reason          = "User appears to be synced from on-prem"
        })
        continue
    }

    if ($user.CompanyName -ne $RequiredCompanyName) {
        $results.Add([pscustomobject]@{
            Id              = $user.Id
            DisplayName     = $user.DisplayName
            CurrentUPN      = $user.UserPrincipalName
            TargetUPN       = $null
            CompanyName     = $user.CompanyName
            Status          = "Skipped"
            Reason          = "companyName does not match required value"
        })
        continue
    }

    $currentUpn = $user.UserPrincipalName

    if ([string]::IsNullOrWhiteSpace($currentUpn) -or ($currentUpn -notmatch "@")) {
        $results.Add([pscustomobject]@{
            Id              = $user.Id
            DisplayName     = $user.DisplayName
            CurrentUPN      = $currentUpn
            TargetUPN       = $null
            CompanyName     = $user.CompanyName
            Status          = "Skipped"
            Reason          = "Current UPN is blank or invalid"
        })
        continue
    }

    if ($RequireSourceDomainMatch -and ($currentUpn.ToLower().EndsWith("@$($SourceDomain.ToLower())") -eq $false)) {
        $results.Add([pscustomobject]@{
            Id              = $user.Id
            DisplayName     = $user.DisplayName
            CurrentUPN      = $currentUpn
            TargetUPN       = $null
            CompanyName     = $user.CompanyName
            Status          = "Skipped"
            Reason          = "Current UPN does not end with source domain"
        })
        continue
    }

    $localPart = $currentUpn.Split("@")[0]
    $newUpn = "$localPart@$TargetDomain"

    if ($currentUpn -eq $newUpn) {
        $results.Add([pscustomobject]@{
            Id              = $user.Id
            DisplayName     = $user.DisplayName
            CurrentUPN      = $currentUpn
            TargetUPN       = $newUpn
            CompanyName     = $user.CompanyName
            Status          = "Skipped"
            Reason          = "UPN already matches target"
        })
        continue
    }

    $results.Add([pscustomobject]@{
        Id              = $user.Id
        DisplayName     = $user.DisplayName
        CurrentUPN      = $currentUpn
        TargetUPN       = $newUpn
        CompanyName     = $user.CompanyName
        Status          = "Ready"
        Reason          = ""
    })
}

# -----------------------------
# SHOW PREVIEW
# -----------------------------
Write-Host ""
Write-Host "Preview of proposed changes:" -ForegroundColor Cyan
$results |
    Select-Object Id, DisplayName, CurrentUPN, TargetUPN, CompanyName, Status, Reason |
    Format-Table -AutoSize

$ready = $results | Where-Object { $_.Status -eq "Ready" }

Write-Host ""
Write-Host "Users ready for update: $($ready.Count)" -ForegroundColor Yellow

if ($ready.Count -eq 0) {
    Write-Host "Nothing to update. Exiting." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}

# -----------------------------
# CONFIRMATION
# -----------------------------
$confirmation = Read-Host "Type YES to apply these UPN changes"

if ($confirmation -ne "YES") {
    Write-Host "Cancelled. No changes were made." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}

# -----------------------------
# APPLY CHANGES
# -----------------------------
Write-Host ""
Write-Host "Applying changes..." -ForegroundColor Cyan

foreach ($item in $ready) {
    try {
        Update-MgUser -UserId $item.Id -UserPrincipalName $item.TargetUPN -ErrorAction Stop

        $item.Status = "Updated"
        $item.Reason = ""
        Write-Host "Updated: $($item.DisplayName) -> $($item.TargetUPN)" -ForegroundColor Green
    }
    catch {
        $item.Status = "Failed"
        $item.Reason = $_.Exception.Message
        Write-Host "Failed: $($item.DisplayName) -> $($_.Exception.Message)" -ForegroundColor Red
    }
}

# -----------------------------
# FINAL SUMMARY
# -----------------------------
Write-Host ""
Write-Host "Final results:" -ForegroundColor Cyan
$results |
    Select-Object Id, DisplayName, CurrentUPN, TargetUPN, CompanyName, Status, Reason |
    Format-Table -AutoSize

Disconnect-MgGraph | Out-Null