# =========================
# CONFIGURATION
# =========================
$DomainToFind = "enterdomainhere.com"
$OutputRoot   = "C:\Temp\DomainDependencyReport"

# =========================
# AUDIT-ONLY SAFETY LOCKS
# =========================
$AuditOnly = $true
$BlockAnyChanges = $true

if (-not $AuditOnly -or -not $BlockAnyChanges) {
    throw "This script is hard-locked to audit-only mode."
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =========================
# FUNCTIONS
# =========================
function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "==== $Message ====" -ForegroundColor Cyan
}

function Add-Result {
    param(
        [Parameter(Mandatory = $true)]
        [object]$List,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$ObjectType,

        [Parameter(Mandatory = $true)]
        [string]$ObjectId,

        [Parameter(Mandatory = $false)]
        [string]$DisplayName = "",

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [string]$MatchedValue,

        [Parameter(Mandatory = $false)]
        [string]$Source = "ManualSweep"
    )

    $null = $List.Add([pscustomobject]@{
        Category     = $Category
        ObjectType   = $ObjectType
        ObjectId     = $ObjectId
        DisplayName  = $DisplayName
        Property     = $PropertyName
        MatchedValue = $MatchedValue
        Source       = $Source
    })
}

function Get-MatchingValues {
    param(
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Domain
    )

    $matches = [System.Collections.ArrayList]::new()

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        foreach ($item in $Value) {
            if ($null -ne $item) {
                $text = $item.ToString()
                if ($text.ToLower().Contains($Domain.ToLower())) {
                    $null = $matches.Add($text)
                }
            }
        }
    }
    else {
        $text = $Value.ToString()
        if ($text.ToLower().Contains($Domain.ToLower())) {
            $null = $matches.Add($text)
        }
    }

    return @($matches)
}

function Ensure-Module {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        throw "Required module '$ModuleName' is not installed. Install Microsoft Graph PowerShell first."
    }
}

function Ensure-GraphConnection {
    Ensure-Module -ModuleName "Microsoft.Graph.Authentication"

    $ctx = Get-MgContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        Write-Section "Connecting to Microsoft Graph"
        Connect-MgGraph -Scopes @(
            "Domain.Read.All",
            "Directory.Read.All",
            "Application.Read.All",
            "User.Read.All",
            "Group.Read.All",
            "OrgContact.Read.All"
        ) -NoWelcome | Out-Null
    }
}

function Resolve-DomainReferenceDetails {
    param(
        [Parameter(Mandatory = $true)]
        [array]$References
    )

    $resolved = [System.Collections.ArrayList]::new()

    foreach ($ref in $References) {
        $odataType = $null
        $displayName = $null
        $upn = $null
        $mail = $null

        if ($ref.PSObject.Properties.Name -contains "AdditionalProperties" -and $ref.AdditionalProperties) {
            if ($ref.AdditionalProperties.ContainsKey("@odata.type")) {
                $odataType = $ref.AdditionalProperties["@odata.type"]
            }
            if ($ref.AdditionalProperties.ContainsKey("displayName")) {
                $displayName = $ref.AdditionalProperties["displayName"]
            }
            if ($ref.AdditionalProperties.ContainsKey("userPrincipalName")) {
                $upn = $ref.AdditionalProperties["userPrincipalName"]
            }
            if ($ref.AdditionalProperties.ContainsKey("mail")) {
                $mail = $ref.AdditionalProperties["mail"]
            }
        }

        if (-not $odataType -and ($ref.PSObject.Properties.Name -contains "OdataType")) {
            $odataType = $ref.OdataType
        }

        $null = $resolved.Add([pscustomobject]@{
            Id                = $ref.Id
            ODataType         = $odataType
            DisplayName       = $displayName
            UserPrincipalName = $upn
            Mail              = $mail
            Source            = "DomainNameReferences"
        })
    }

    return @($resolved)
}

function Invoke-PagedGraphGet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    $items = [System.Collections.ArrayList]::new()
    $nextUri = $Uri

    while (-not [string]::IsNullOrWhiteSpace($nextUri)) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $nextUri -OutputType PSObject

        if ($null -ne $response) {
            if ($response.PSObject.Properties.Name -contains "value") {
                foreach ($item in @($response.value)) {
                    $null = $items.Add($item)
                }
            }
            else {
                $null = $items.Add($response)
            }
        }

        if ($response -and ($response.PSObject.Properties.Name -contains "@odata.nextLink")) {
            $nextUri = $response.'@odata.nextLink'
        }
        else {
            $nextUri = $null
        }
    }

    return @($items)
}

function Get-SafeDisplayName {
    param(
        [AllowNull()]
        [string]$DisplayName,

        [AllowNull()]
        [string]$Fallback1,

        [AllowNull()]
        [string]$Fallback2
    )

    if (-not [string]::IsNullOrWhiteSpace($DisplayName)) { return $DisplayName }
    if (-not [string]::IsNullOrWhiteSpace($Fallback1))   { return $Fallback1 }
    if (-not [string]::IsNullOrWhiteSpace($Fallback2))   { return $Fallback2 }
    return "<unknown>"
}

# =========================
# STARTUP
# =========================
if ([string]::IsNullOrWhiteSpace($DomainToFind)) {
    throw "Set `$DomainToFind at the top of the script."
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    throw "Set `$OutputRoot at the top of the script."
}

$script:GraphApiVersion = "v1.0"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$safeDomainName = $DomainToFind.Replace(".", "_")
$ReportFolder = Join-Path $OutputRoot ("DomainScan_{0}_{1}" -f $safeDomainName, $timestamp)

New-Item -ItemType Directory -Path $ReportFolder -Force | Out-Null

Write-Host ""
Write-Host "READ-ONLY MODE: This script does not modify, delete, or update anything." -ForegroundColor Green
Write-Host "It only scans for references to the target domain and exports results for manual review." -ForegroundColor Green
Write-Host "Target domain: $DomainToFind" -ForegroundColor Yellow
Write-Host "Output folder: $ReportFolder" -ForegroundColor Yellow

# =========================
# CONNECT
# =========================
Ensure-GraphConnection

# =========================
# VALIDATE DOMAIN
# =========================
Write-Section "Checking domain exists"

try {
    $domainObj = Get-MgDomain -DomainId $DomainToFind
}
catch {
    throw "Domain '$DomainToFind' was not found in this tenant."
}

Write-Host ("Domain found: {0}" -f $domainObj.Id) -ForegroundColor Green
Write-Host ("IsVerified: {0} | IsDefault: {1} | IsInitial: {2}" -f $domainObj.IsVerified, $domainObj.IsDefault, $domainObj.IsInitial)

$allFindings = [System.Collections.ArrayList]::new()

# =========================
# DIRECT DOMAIN REFERENCES
# =========================
Write-Section "Querying built-in domainNameReferences"

try {
    $domainReferenceResults = @(Get-MgDomainNameReference -DomainId $DomainToFind -All -ErrorAction Stop)
    $resolvedRefs = @(Resolve-DomainReferenceDetails -References $domainReferenceResults)

    foreach ($r in $resolvedRefs) {
        $nameToShow = Get-SafeDisplayName -DisplayName $r.DisplayName -Fallback1 $r.UserPrincipalName -Fallback2 $r.Mail
        $typeToShow = if ([string]::IsNullOrWhiteSpace($r.ODataType)) { "unknown" } else { $r.ODataType }

        Add-Result -List $allFindings `
            -Category "DirectDomainDependency" `
            -ObjectType $typeToShow `
            -ObjectId $r.Id `
            -DisplayName $nameToShow `
            -PropertyName "domainNameReferences" `
            -MatchedValue $DomainToFind `
            -Source "DomainNameReferences"
    }

    @($resolvedRefs) | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "01_DomainNameReferences.csv")
    Write-Host ("Found {0} direct domain reference objects." -f @($resolvedRefs).Count) -ForegroundColor Yellow
}
catch {
    Write-Warning ("Failed to read domainNameReferences: {0}" -f $_.Exception.Message)
}

# =========================
# USERS
# =========================
Write-Section "Sweeping users"

$users = @(Get-MgUser -All -Property "id,displayName,userPrincipalName,mail,proxyAddresses,identities,onPremisesUserPrincipalName,otherMails")

foreach ($u in $users) {
    $userDisplayName = Get-SafeDisplayName -DisplayName $u.DisplayName -Fallback1 $u.UserPrincipalName -Fallback2 $u.Mail

    $fields = @{
        userPrincipalName           = $u.UserPrincipalName
        mail                        = $u.Mail
        proxyAddresses              = $u.ProxyAddresses
        onPremisesUserPrincipalName = $u.OnPremisesUserPrincipalName
        otherMails                  = $u.OtherMails
    }

    foreach ($kvp in $fields.GetEnumerator()) {
        $matches = @(Get-MatchingValues -Value $kvp.Value -Domain $DomainToFind)
        foreach ($m in $matches) {
            Add-Result -List $allFindings `
                -Category "User" `
                -ObjectType "microsoft.graph.user" `
                -ObjectId $u.Id `
                -DisplayName $userDisplayName `
                -PropertyName $kvp.Key `
                -MatchedValue $m
        }
    }

    if ($u.Identities) {
        foreach ($identity in $u.Identities) {
            $issuer = $identity.Issuer
            $signInType = $identity.SignInType
            $issuerAssignedId = $identity.IssuerAssignedId

            foreach ($candidate in @($issuer, $issuerAssignedId)) {
                if ($candidate -and $candidate.ToString().ToLower().Contains($DomainToFind.ToLower())) {
                    $identityText = "signInType={0}; issuer={1}; issuerAssignedId={2}" -f $signInType, $issuer, $issuerAssignedId
                    Add-Result -List $allFindings `
                        -Category "User" `
                        -ObjectType "microsoft.graph.user" `
                        -ObjectId $u.Id `
                        -DisplayName $userDisplayName `
                        -PropertyName "identities" `
                        -MatchedValue $identityText
                    break
                }
            }
        }
    }
}

# =========================
# GROUPS
# =========================
Write-Section "Sweeping groups"

$groups = @(Get-MgGroup -All -Property "id,displayName,mail,proxyAddresses,mailNickname")

foreach ($g in $groups) {
    $groupDisplayName = Get-SafeDisplayName -DisplayName $g.DisplayName -Fallback1 $g.Mail -Fallback2 $g.MailNickname

    $fields = @{
        mail           = $g.Mail
        proxyAddresses = $g.ProxyAddresses
        mailNickname   = $g.MailNickname
    }

    foreach ($kvp in $fields.GetEnumerator()) {
        $matches = @(Get-MatchingValues -Value $kvp.Value -Domain $DomainToFind)
        foreach ($m in $matches) {
            Add-Result -List $allFindings `
                -Category "Group" `
                -ObjectType "microsoft.graph.group" `
                -ObjectId $g.Id `
                -DisplayName $groupDisplayName `
                -PropertyName $kvp.Key `
                -MatchedValue $m
        }
    }
}

# =========================
# ORG CONTACTS
# =========================
Write-Section "Sweeping org contacts"

try {
    $contacts = @(Get-MgContact -All -Property "id,displayName,mail,proxyAddresses")

    foreach ($c in $contacts) {
        $contactDisplayName = Get-SafeDisplayName -DisplayName $c.DisplayName -Fallback1 $c.Mail -Fallback2 $null

        $fields = @{
            mail           = $c.Mail
            proxyAddresses = $c.ProxyAddresses
        }

        foreach ($kvp in $fields.GetEnumerator()) {
            $matches = @(Get-MatchingValues -Value $kvp.Value -Domain $DomainToFind)
            foreach ($m in $matches) {
                Add-Result -List $allFindings `
                    -Category "OrgContact" `
                    -ObjectType "microsoft.graph.orgContact" `
                    -ObjectId $c.Id `
                    -DisplayName $contactDisplayName `
                    -PropertyName $kvp.Key `
                    -MatchedValue $m
            }
        }
    }
}
catch {
    Write-Warning ("Org contact sweep failed: {0}" -f $_.Exception.Message)
}

# =========================
# APPLICATIONS
# =========================
Write-Section "Sweeping applications"

$appUri = "https://graph.microsoft.com/$script:GraphApiVersion/applications?`$top=999&`$select=id,displayName,identifierUris,web,spa,publicClient"
$appItems = @(Invoke-PagedGraphGet -Uri $appUri)

foreach ($app in $appItems) {
    $id = $app.id
    $name = Get-SafeDisplayName -DisplayName $app.displayName -Fallback1 $null -Fallback2 $null

    foreach ($uri in @($app.identifierUris)) {
        if ($uri -and $uri.ToString().ToLower().Contains($DomainToFind.ToLower())) {
            Add-Result -List $allFindings `
                -Category "Application" `
                -ObjectType "microsoft.graph.application" `
                -ObjectId $id `
                -DisplayName $name `
                -PropertyName "identifierUris" `
                -MatchedValue $uri
        }
    }

    if ($app.web) {
        foreach ($prop in @("homePageUrl", "logoutUrl")) {
            $val = $app.web.$prop
            if ($val -and $val.ToString().ToLower().Contains($DomainToFind.ToLower())) {
                Add-Result -List $allFindings `
                    -Category "Application" `
                    -ObjectType "microsoft.graph.application" `
                    -ObjectId $id `
                    -DisplayName $name `
                    -PropertyName ("web.{0}" -f $prop) `
                    -MatchedValue $val
            }
        }

        foreach ($uri in @($app.web.redirectUris)) {
            if ($uri -and $uri.ToString().ToLower().Contains($DomainToFind.ToLower())) {
                Add-Result -List $allFindings `
                    -Category "Application" `
                    -ObjectType "microsoft.graph.application" `
                    -ObjectId $id `
                    -DisplayName $name `
                    -PropertyName "web.redirectUris" `
                    -MatchedValue $uri
            }
        }
    }

    if ($app.spa) {
        foreach ($uri in @($app.spa.redirectUris)) {
            if ($uri -and $uri.ToString().ToLower().Contains($DomainToFind.ToLower())) {
                Add-Result -List $allFindings `
                    -Category "Application" `
                    -ObjectType "microsoft.graph.application" `
                    -ObjectId $id `
                    -DisplayName $name `
                    -PropertyName "spa.redirectUris" `
                    -MatchedValue $uri
            }
        }
    }

    if ($app.publicClient) {
        foreach ($uri in @($app.publicClient.redirectUris)) {
            if ($uri -and $uri.ToString().ToLower().Contains($DomainToFind.ToLower())) {
                Add-Result -List $allFindings `
                    -Category "Application" `
                    -ObjectType "microsoft.graph.application" `
                    -ObjectId $id `
                    -DisplayName $name `
                    -PropertyName "publicClient.redirectUris" `
                    -MatchedValue $uri
            }
        }
    }
}

# =========================
# SERVICE PRINCIPALS
# =========================
Write-Section "Sweeping service principals"

$spUri = "https://graph.microsoft.com/$script:GraphApiVersion/servicePrincipals?`$top=999&`$select=id,displayName,servicePrincipalNames,replyUrls,homepage,loginUrl,logoutUrl,servicePrincipalType"
$spItems = @(Invoke-PagedGraphGet -Uri $spUri)

foreach ($sp in $spItems) {
    $spDisplayName = Get-SafeDisplayName -DisplayName $sp.displayName -Fallback1 $null -Fallback2 $null

    $fields = @{
        servicePrincipalNames = $sp.servicePrincipalNames
        replyUrls             = $sp.replyUrls
        homepage              = $sp.homepage
        loginUrl              = $sp.loginUrl
        logoutUrl             = $sp.logoutUrl
    }

    foreach ($kvp in $fields.GetEnumerator()) {
        $matches = @(Get-MatchingValues -Value $kvp.Value -Domain $DomainToFind)
        foreach ($m in $matches) {
            Add-Result -List $allFindings `
                -Category "ServicePrincipal" `
                -ObjectType "microsoft.graph.servicePrincipal" `
                -ObjectId $sp.id `
                -DisplayName $spDisplayName `
                -PropertyName $kvp.Key `
                -MatchedValue $m
        }
    }
}

# =========================
# EXPORT RESULTS
# =========================
Write-Section "De-duplicating and exporting results"

$deduped = @(
    $allFindings |
    Sort-Object Category, ObjectType, ObjectId, Property, MatchedValue, Source -Unique
)

$deduped | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "02_AllFindings.csv")

$summary = @(
    $deduped |
    Group-Object Category, ObjectType, Property |
    Sort-Object Count -Descending |
    ForEach-Object {
        [pscustomobject]@{
            Count      = $_.Count
            Category   = $_.Group[0].Category
            ObjectType = $_.Group[0].ObjectType
            Property   = $_.Group[0].Property
        }
    }
)

$summary | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "03_Summary.csv")

$deduped | Where-Object { $_.Category -eq "User" }                   | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "04_Users.csv")
$deduped | Where-Object { $_.Category -eq "Group" }                  | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "05_Groups.csv")
$deduped | Where-Object { $_.Category -eq "OrgContact" }             | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "06_OrgContacts.csv")
$deduped | Where-Object { $_.Category -eq "Application" }            | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "07_Applications.csv")
$deduped | Where-Object { $_.Category -eq "ServicePrincipal" }       | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "08_ServicePrincipals.csv")
$deduped | Where-Object { $_.Category -eq "DirectDomainDependency" } | Export-Csv -NoTypeInformation -Path (Join-Path $ReportFolder "09_DirectDomainDependencies.csv")

# =========================
# DISPLAY SUMMARY
# =========================
Write-Section "Summary"

if (@($summary).Count -gt 0) {
    $summary | Format-Table -AutoSize
}
else {
    Write-Host "No matches found for domain '$DomainToFind'." -ForegroundColor Green
}

Write-Host ""
Write-Host ("Finished. Output folder: {0}" -f (Resolve-Path $ReportFolder)) -ForegroundColor Green
Write-Host ("Total findings: {0}" -f @($deduped).Count) -ForegroundColor Green
Write-Host "No changes were made." -ForegroundColor Green