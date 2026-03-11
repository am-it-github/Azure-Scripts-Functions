# Requires:
# Install-Module Microsoft.Graph -Scope CurrentUser


# THIS SCRIPT CONNECTS TO GRAPH, GETS ALL USERS, FILTERS OUT GUESTS, FILTERS BY THE COMPANY NAME YOU PROVIDE, THEN EXPORTS TO A CSV 
# THIS SCRIPT IS PRIMARILY DESIGNED FOR USE IN TENANTS WITH USERS FROM MULTIPLE COMPANIES 
# THE CSV IT EXPORTS IS DESIGNED TO MATCH THAT OF THE ONE EXPORTED FROM THE ENTRA ID GUI

# -----------------------------
# VARIABLES - EDIT THESE
# -----------------------------
$ExportPath          = "C:\Temp\UPN_Update_Users.csv"
$RequiredCompanyName = "CHANGE ME"
$ExcludeSyncedUsers  = $true

# -----------------------------
# CONNECT TO GRAPH
# -----------------------------
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Authentication

Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

# -----------------------------
# GET USERS
# -----------------------------
# Do not filter userType server-side here.
# Some tenants / Graph paths throw unsupported query errors for this.
$users = Get-MgUser -All `
    -Property "id,displayName,userPrincipalName,userType,onPremisesSyncEnabled,identities,companyName"

# -----------------------------
# FILTER USERS
# -----------------------------
$filteredUsers = $users | Where-Object {
    $_.UserType -ne "Guest" -and
    $_.CompanyName -eq $RequiredCompanyName -and
    (
        -not $ExcludeSyncedUsers -or
        $_.OnPremisesSyncEnabled -ne $true
    )
}

# -----------------------------
# PREVIEW USERS
# -----------------------------
$preview = $filteredUsers |
    Select-Object id, displayName, userPrincipalName, userType, companyName, onPremisesSyncEnabled

Write-Host ""
Write-Host "Users matching export criteria:" -ForegroundColor Cyan
$preview | Format-Table -AutoSize

Write-Host ""
Write-Host "Total users found: $($preview.Count)" -ForegroundColor Yellow
Write-Host "Export path: $ExportPath" -ForegroundColor Yellow

if ($preview.Count -eq 0) {
    Write-Host "No users match the criteria. Nothing to export." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}

# -----------------------------
# CONFIRMATION
# -----------------------------
$confirmation = Read-Host "Type YES to export these users"

if ($confirmation -ne "YES") {
    Write-Host "Export cancelled." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}

# -----------------------------
# BUILD EXPORT DATA
# -----------------------------
$export = $filteredUsers |
    Select-Object `
        id,
        displayName,
        userPrincipalName,
        userType,
        onPremisesSyncEnabled,
        @{Name='identities';Expression={
            if ($_.Identities) {
                ($_.Identities | ForEach-Object {
                    "$($_.SignInType)|$($_.Issuer)|$($_.IssuerAssignedId)"
                }) -join ";"
            }
            else {
                $null
            }
        }},
        companyName

# -----------------------------
# EXPORT CSV
# -----------------------------
$export | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Export complete." -ForegroundColor Green
Write-Host "Users exported: $($export.Count)" -ForegroundColor Cyan
Write-Host "File: $ExportPath" -ForegroundColor Cyan

Disconnect-MgGraph | Out-Null