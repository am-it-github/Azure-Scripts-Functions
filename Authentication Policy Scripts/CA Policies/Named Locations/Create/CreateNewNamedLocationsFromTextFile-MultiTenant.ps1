# Function to download the IP file, initialize the ipRanges array, and construct the params hashtable
function Initialize-IpRangesAndParams {
    param (
        [string]$url
    )

    # File path for the downloaded IP addresses file
    $filePath = ".\ipv4.txt"

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


####### START OF VARIABLES TABLE #######
# OPTIONAL - USE ONLY ONE TENANT ID IF REQUIRED, FOREACH LOOP WILL STILL WORK WITH ONLY ONE
# Declare Multiple Tenant IDs as Variable for Quick deployments cross-tenant
$tenantIDs = @("TENANT_ID_1", "TENANT_ID_2", "TENANT_ID_3")

# Create a hash table to map tenant IDs to client IDs
$clientIdMapping = @{
    "TENANT_ID_1" = "CLIENT_ID_1"
    "TENANT_ID_2" = "CLIENT_ID_2"
    "TENANT_ID_3" = "CLIENT_ID_3"
    # Add more tenant-client mappings as needed
}

# URL for the IP addresses file that is passed into the Function "Initialize-IpRangesAndParams" when called later
$url = "https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt"

####### END OF VARIABLES TABLE #######

# Call the function to initialize ipRanges and construct params once
$params = Initialize-IpRangesAndParams -url $url

foreach ($tenant in $tenantIDs) {
    # Retrieve the client ID for the current tenant
    $clientId = $clientIdMapping[$tenant]

    # In order for this to work you must connect to MgGraph
    Connect-MgGraph -NoWelcome -ClientId $clientId -TenantID $tenant -Scopes Policy.ReadWrite.ConditionalAccess

    # Create the Named Location
    New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params
}
