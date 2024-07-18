# THE PURPOSE OF THIS SCRIPT IS TO CREATE A NEW NAMED IP LOCATION IN AZURE CONDITIONAL ACCESS POPULATED FROM A PLAINTEXT LIST OF
# IPV4 ADDRESSES IN CIDR FORMAT

# THIS IS THE AUTOMATED VERSION OF THE SCRIPT.
# YOU MUST SET THE TENANT_ID AND ENSURE THE IPV4 DOCUMENT IS DOWNLOADED TO THE SAME DIRECTORY THIS SCRIPT IS EXECUTED FROM
# IF YOU WISH TO UPDATE THE URL USED FOR THE IPV4 DOCUMENT, ENSURE THE URL IS CHANGED
# IF YOU WISH TO CHANGE THE DISPLAY NAME OF THE CREATED POLICY - ENSURE THE $NamedLocationDisplayName IS CHANGED IN THE

####### START OF FUNCTIONS BLOCK #######

# Function to download the IP file, read IP addresses, initialize the ipRanges array, and construct the params hashtable
function Initialize-IpRangesAndParamsFunction {
    param (
        [string]$url,
        [string]$displayName
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
        displayName = $displayName
        isTrusted = $false
        ipRanges = $ipRanges
    }

    return $params
}

# Function to connect to MgGraph with only TenantID as a parameter
function Connect-MgGraphFunction {
    param (
        [string]$TenantID
    )
    Connect-MgGraph -NoWelcome -TenantID $TenantID -Scopes Policy.ReadWrite.ConditionalAccess,Policy.Read.All
}


####### END OF FUNCTIONS BLOCK #######

####### START OF VARIABLES TABLE #######
# URL for the IP addresses file that is passed into the Function "Initialize-IpRangesAndParamsFunction" when called later
$url = "https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt"

# Declares the ID of the tenant you want to connect to
$tenantID = "YOUR_TENANT_ID"

#Declare the Display Name of the Created policy
$NamedLocationDisplayName = "YOUR NAMED POLICY DISPLAY NAME"

####### END OF VARIABLES TABLE #######

####### START OF SCRIPT BLOCK #######
# Call the function to initialize ipRanges and construct params once
$params = Initialize-IpRangesAndParamsFunction -displayName $NamedLocationDisplayName -url $url

# Connect to MgGraph with correct Scope using the simplified function
Connect-MgGraphFunction -TenantID $tenantID

# Update the Named Location
New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params

# Disconnect from MgGraph
Disconnect-MgGraph
####### END OF SCRIPT BLOCK #######
