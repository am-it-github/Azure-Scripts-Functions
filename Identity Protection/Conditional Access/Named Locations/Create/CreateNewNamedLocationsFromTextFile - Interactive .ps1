# THE PURPOSE OF THIS SCRIPT IS TO CREATE A NEW NAMED IP LOCATION IN AZURE POPULATED FROM A PLAINTEXT LIST OF 
# IPV4 ADDRESSES IN CIDR FORMAT

# THIS IS THE INTERACTIVE VERSION OF THE SCRIPT INTENDED TO BE RAN MANUALLY BY AN ADMIN USER
# THE SCRIPT WILL PROMPT FOR ALL VARIABLES REQUIRED TO ACHIEVE THE DESIRED RESULT



####### START OF FUNCTIONS BLOCK #######
# Function to download the IP file, read IP addresses, initialize the ipRanges array, and construct the params hashtable
function Initialize-IpRangesAndParamsFunction {
    param (
        [string]$filePath
    )

    # Read IP addresses from the file
    $IPScopes = Get-Content -Path $filePath

    $displayName = Read-Host "Enter the Display Name for the Named Location you wish To Create"

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

    # Check if already connected to MgGraph
    $currentConnectionInfo = Get-MgGraphConnectionInfo
    if ($currentConnectionInfo) {
        if ($currentConnectionInfo.TenantId -ne $TenantID) {
            Write-Warning "Already connected to MgGraph with a different TenantID: $($currentConnectionInfo.TenantId)"
            Write-Warning "Disconnecting from Incorrect TenantID"
            Disconnect-MgGraph
        } else {
            Write-Output "Already connected to MgGraph with TenantID: $TenantID"
            return
        }
    }

    Write-Output "Connecting to MgGraph with TenantID: $TenantID..."
    Connect-MgGraph -NoWelcome -TenantID $TenantID -Scopes Policy.ReadWrite.ConditionalAccess,Policy.Read.All
    Write-Output "Connected to MgGraph with TenantID: $TenantID"
}
####### END OF FUNCTIONS BLOCK #######

####### START OF PRE-SCRIPT BLOCK #######
Write-Host -ForegroundColor Red "THE PURPOSE OF THIS SCRIPT IS TO CREATE A NEW NAMED IP LOCATION IN AZURE POPULATED FROM A PLAINTEXT LIST OF IPV4 ADDRESSES IN CIDR FORMAT"
Write-Host -ForegroundColor Red "THIS IS THE INTERACTIVE VERSION OF THE SCRIPT INTENDED TO BE RAN MANUALLY BY AN ADMIN USER"
Write-Host -ForegroundColor Red "BEFORE CONTINUING, YOU WILL NEED TO KNOW THE TENANT ID OF THE AZURE ENVIRONMENT YOU WISH TO CONNECT TO AND THE DISPLAY NAME YOU WANT TO SET FOR YOUR NEW NAMED LOCATION"
Read-Host "PRESS ENTER WHEN YOU ARE READY TO CONTINUE..."
####### END OF PRE-SCRIPT BLOCK #######

####### START OF VARIABLES TABLE #######
# Declares the ID of the tenant you want to connect to
$tenantID = Read-Host "Enter the tenant ID you want to Connect to"

# File path for the downloaded IP addresses file
Write-Host -ForegroundColor Cyan "Example of expected path ""C:\users\My OneDrive\Documents\ipv4.txt"
$filePath = Read-Host "Enter the full file path to the ipv4 txt document you want to use. Ensure the filename is included"
####### END OF VARIABLES TABLE #######

####### START OF SCRIPT BLOCK #######
# Call the function to initialize ipRanges and construct params once
Write-Host -ForegroundColor Cyan "Generating Parameter Variable from txt file $filePath..."
$params = Initialize-IpRangesAndParamsFunction -filePath $filePath
Write-Host -ForegroundColor Green "Done"

# Connect to MgGraph with correct Scope using the simplified function
Connect-MgGraphFunction -TenantID $tenantID

# Update the Named Location
Write-Host -ForegroundColor Cyan "Creating new Named Location..."
New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params
Write-Host -ForegroundColor Green "Done"

# Ask the user if they want to stay connected to MgGraph
$stayConnected = Read-Host "Do you want to stay connected to MgGraph? (Y/N)"

if ($stayConnected -eq "N") {
    Write-Host -ForegroundColor Cyan "Disconnecting from MgGraph..."
    Disconnect-MgGraph
    Write-Host -ForegroundColor Green "Disconnected from MgGraph"
} else {
    Write-Host -ForegroundColor Green "You are still connected to MgGraph"
}
####### END OF SCRIPT #######
