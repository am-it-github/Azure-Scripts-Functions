####### START OF FUNCTIONS BLOCK #######

# Function to download the IP file, read IP addresses, initialize the ipRanges array, and construct the params hashtable
function Initialize-IpRangesAndParamsFunction {
    param (
        [string]$url
    )

    # File path for the downloaded IP addresses file
    $filePath = "ipv4.txt"

    # Download the required file from the URL
    Invoke-WebRequest -Uri $url -OutFile $filePath

    # Read IP addresses from the file
    $IPScopes = Get-Content -Path $filePath

    ## Initialize the ipRanges array
    $ipRanges = @()

    ## Loop through each IP address in your txt file and add it to the ipRanges array
    foreach ($IPAddress in $IPScopes) {
        $ipRanges += @{
            "@odata.type" = "#microsoft.graph.iPv4CidrRange"
            cidrAddress = $IPAddress
        }
    }

    ## Construct the final $params hashtable, using the ip ranges array from above
    $params = @{
        "@odata.type" = "#microsoft.graph.ipNamedLocation"
        displayName = "Blocked VPNs"
        isTrusted = $false
        ipRanges = $ipRanges
    }

    return $params
}

function Connect-MgGraphFunction {
    param (
        [string]$TenantID
    )

    # Check if already connected to MgGraph
    if (-not (Get-MgGraphConnectionInfo)) {
        Connect-MgGraph -NoWelcome -TenantID $TenantID -Scopes Policy.ReadWrite.ConditionalAccess,Policy.Read.All
    }
}

# Function to get the Named Location ID for a given display name
function Get-NamedLocationIdFunction {
    param (
        [string]$displayName,
        [string]$tenantID
    )

    # Connect to MgGraph with correct Scope
    Connect-MgGraphFunction -TenantID $tenantID

    # Get the named location for locations matching the given display name
    Write-Host -ForegroundColor Cyan "Getting the Named Location ID for Named Location $displayName..."
    $namedLocation = Get-MgIdentityConditionalAccessNamedLocation | Where-Object { $_.DisplayName -eq $displayName }
    Write-Host -ForegroundColor Green "Done"

    # Extract the ID from the above variable
    return $namedLocation.Id
}
####### END OF FUNCTIONS BLOCK #######
####### START OF VARIABLES TABLE #######
# URL for the IP addresses file that is passed into the Function "Initialize-IpRangesAndParams" when called later
$url = "https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt"

# Declares the ID of the tenant you want to connect to
$tenantID = Read-Host "Enter the tenant ID you want to Connect to"

###### OPTION 1 (DEFAULT) - Automatically get the NamedLocationID for policy matching Display Name "Blocked VPNs" using Function "Get-NamedLocationId" #####
# Uncomment the next line to use Option 1
$NamedLocationDisplayName = "Blocked VPNs"
$NamedLocationID = Get-NamedLocationIdFunction -displayName $NamedLocationDisplayName -tenantID $tenantID
####### END OF OPTION 1 #######
###### OPTION 2 -  Manually Declare the Named Location ID you wish to Update #####
# Uncomment the next line to use Option 2
# $NamedLocationID = "YOUR ID" # To get this, run "get-MgIdentityConditionalAccessNamedLocation"
####### END OF OPTION 2 #######
####### END OF VARIABLES TABLE #######

####### START OF SCRIPT BLOCK #######
# Ensure $NamedLocationID is set
if (-not $NamedLocationID) {
    Write-Error "NamedLocationID is not set. Please ensure you have set it using Option 1 or Option 2."
    exit
}

# Call the function to initialize ipRanges and construct params once
$params = Initialize-IpRangesAndParamsFunction -url $url

# Connect to MgGraph with correct Scope using the simplified function
Connect-MgGraphFunction -TenantID $tenantID

# Update the Named Location
Write-Host -ForegroundColor Cyan "Updating Named Location $NamedLocationDisplayName with Location ID $NamedLocationID..."
Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $NamedLocationID -BodyParameter $params
Write-Host -ForegroundColor Green "Done"

# Disconnects MgGraph
Disconnect-MgGraph
####### END OF SCRIPT BLOCK #######
