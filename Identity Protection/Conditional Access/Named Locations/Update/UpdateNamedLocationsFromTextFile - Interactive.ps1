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

# Function to connect to MgGraph with only TenantID as a parameter
function Connect-MgGraphFunction {
    param (
        [string]$TenantID
    )

    Write-Host -ForegroundColor Cyan "Connecting to $TenantID with Scopes ""Policy.ReadWrite.ConditionalAccess,Policy.Read.All""..."
    Write-Host -ForegroundColor Red "If Prompted, enter Username and Password of account with relevant MsGraph Permissions in the Window that pops up..."
    Connect-MgGraph -NoWelcome -TenantID $TenantID -Scopes Policy.ReadWrite.ConditionalAccess,Policy.Read.All
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

####### START OF PRE-SCRIPT BLOCK #######
Write-Host -ForegroundColor Red "THE PURPOSE OF THIS SCRIPT IS TO UPDATE NAMED IP LOCATION IN AZURE POPULATED FROM A PLAINTEXT LIST OF IPV4 ADDRESSES IN CIDR FORMAT"
Write-Host -ForegroundColor Red "THIS IS THE INTERACTIVE VERSION OF THE SCRIPT INTENDED TO BE RAN MANUALLY BY AN ADMIN USER"
Write-Host -ForegroundColor Red "BEFORE CONTINUING, YOU WILL NEED TO KNOW THE TENANT ID OF THE AZURE ENVIRONMENT YOU WISH TO CONNECT TO AND THE DISPLAY NAME OF THE NAMED LOCATION YOU WISH TO UPDATE"
Read-Host "PRESS ENTER WHEN YOU ARE READY TO CONTINUE..."
####### END OF PRE-SCRIPT BLOCK #######


####### START OF VARIABLES TABLE #######
# Declares the ID of the tenant you want to connect to
$tenantID = Read-Host "Enter the tenant ID you want to Connect to"

# File path for the downloaded IP addresses file
Write-Host -ForegroundColor Cyan "Example of expected path ""C:\users\My OneDrive\Documents\ipv4.txt"
$filePath = Read-Host "Enter the full file path to the ipv4 txt document you want to use. Ensure the filename is included"

###### OPTION 1 (DEFAULT) - Automatically get the NamedLocationID for policy matching Display Name "Blocked VPNs" using Function "Get-NamedLocationId" #####
# Uncomment the next line to use Option 1
$NamedLocationDisplayName = Read-Host "Enter The Display Name of the Named Location you wish to Update"
$NamedLocationID = Get-NamedLocationIdFunction -displayName $NamedLocationDisplayName -tenantID $tenantID
###### END OF OPTION 1 ######
###### OPTION 2 -  Manually Declare the Named Location ID you wish to Update #####
# Uncomment the next line to use Option 2
# $NamedLocationID = Read-Host "Enter the NamedLocationID of the Named Location you wish to Update"
###### END OF OPTION 2 ######
####### END OF VARIABLES TABLE #######

####### START OF SCRIPT BLOCK #######
# Ensure $NamedLocationID is set
Write-Host -ForegroundColor Cyan "Confirming Named Location ID is populated..."
if (-not $NamedLocationID) {
    Write-Error "NamedLocationID is not set. Please ensure you have set it using Option 1 or Option 2."
    exit
}
Write-Host -ForegroundColor Green "Done"

# Call the function to initialize ipRanges and construct params once
Write-Host -ForegroundColor Cyan "Generating Parameter Variable from txt file $filePath..."
$params = Initialize-IpRangesAndParamsFunction -filePath $filePath
Write-Host -ForegroundColor Green "Done"

# Connect to MgGraph with correct Scope using the simplified function
Connect-MgGraphFunction -TenantID $tenantID

# Update the Named Location
Write-Host -ForegroundColor Cyan "Updating Named Location $NamedLocationDisplayName with Location ID $NamedLocationID..."
Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $NamedLocationID -BodyParameter $params
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
####### END OF SCRIPT BLOCK #######
