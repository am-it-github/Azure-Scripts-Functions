# THE PURPOSE OF THIS SCRIPT IS TO UPDATE A NAMED IP LOCATION IN AZURE CONDITIONAL ACCESS FROM A PLAINTEXT LIST OF
# IPV4 ADDRESSES IN CIDR FORMAT

# THIS IS THE AUTOMATED VERSION OF THE SCRIPT.
# YOU MUST SET THE TENANT_ID AND ENSURE THE IPV4 DOCUMENT IS DOWNLOADED TO THE SAME DIRECTORY THIS SCRIPT IS EXECUTED FROM
# IF YOU WISH TO UPDATE THE URL USED FOR THE IPV4 DOCUMENT, ENSURE THE URL IS CHANGED
# IF YOU WISH TO CHANGE THE DISPLAY NAME OF THE CREATED POLICY - ENSURE THE displayName = IS CHANGED IN THE Construct the final $params hashtable WITHIN
# FUNCTION Initialize-IpRangesAndParams


####### START OF FUNCTIONS BLOCK #######
# Function to download the IP file, read IP addresses, initialize the ipRanges array, and construct the params hashtable
function Initialize-IpRangesAndParams {
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

# Function to get the Named Location ID for a given display name
function Get-NamedLocationId {
    param (
        [string]$displayName,
        [string]$tenantID
    )

    # Connect to MgGraph with correct Scope
    Connect-MgGraph -NoWelcome -TenantID $tenantID -Scopes Policy.ReadWrite.ConditionalAccess,Policy.Read.All

    # Get the named location for locations matching the given display name
    $namedLocation = Get-MgIdentityConditionalAccessNamedLocation | Where-Object { $_.DisplayName -eq $displayName }
    # Extract the ID from the above variable
    return $namedLocation
}
####### END OF FUNCTIONS BLOCK #######
####### START OF VARIABLES TABLE #######
# URL for the IP addresses file that is passed into the Function "Initialize-IpRangesAndParams" when called later
$url = "https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt"

# Declares the ID of the tenant you want to connect to
$tenantID = "YOUR_TENANT_ID"


###### OPTION 1 (DEFAULT) - Automatically get the NamedLocationID for policy matching Display Name "Blocked VPNs" using Function "Get-NamedLocationId" #####
# Uncomment the next line to use Option 1
$NamedLocationID = (Get-NamedLocationId -displayName "Blocked VPNs" -tenantID $tenantID).Id
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
$params = Initialize-IpRangesAndParams -url $url

# Connect to MgGraph with correct Scope
Connect-MgGraph -NoWelcome -TenantID $tenantID -Scopes Policy.ReadWrite.ConditionalAccess,Policy.Read.All

# Update the Named Location
Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $NamedLocationID -BodyParameter $params

# Disconnects MgGraph
Disconnect-MgGraph
####### START OF SCRIPT BLOCK #######