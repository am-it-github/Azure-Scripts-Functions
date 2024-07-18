# THE PURPOSE OF THIS SCRIPT IS TO UPDATE AN EXISTING NAMED IP LOCATION IN AZURE CONDITIONAL ACCESS POPULATED FROM A PLAINTEXT LIST OF 
# IPV4 ADDRESSES IN CIDR FORMAT

# THIS IS THE INTERACTIVE VERSION OF THE SCRIPT. INTENDED TO BE RAN MANUALLY BY AN ADMIN USER
# THE SCRIPT WILL PROMPT FOR ALL VARIABLES REQUIRED TO ACHIEVE THE DESIRED RESULT



#Function to download the IP file, read IP addresses, initialize the ipRanges array, and construct the params hashtable
function Initialize-IpRangesAndParams {


    # File path for the downloaded IP addresses file
    $filePath = Read-Host "Enter the full file path to the ipv4 txt document you want to use"

    # Read IP addresses from the file
    $IPScopes = Get-Content -Path $filePath

    # Add quotes around the file path if it contains spaces
    if ($filePath -match "\s") {
        $filePath = "`"$filePath`""
    }

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

Write-Host -ForegroundColor Red "THE PURPOSE OF THIS SCRIPT IS TO UPDATE NAMED IP LOCATION IN AZURE POPULATED FROM A PLAINTEXT LIST OF IPV4 ADDRESSES IN CIDR FORMAT"
Write-Host -ForegroundColor Red "THIS IS THE INTERACTIVE VERSION OF THE SCRIPT INTENDED TO BE RAN MANUALLY BY AN ADMIN USER"
Write-Host -ForegroundColor Red "BEFORE CONTINUING, YOU WILL NEED TO KNOW THE TENANT ID OF THE AZURE ENVIRONMENT YOU WISH TO CONNECT TO AND THE DISPLAY NAME OF THE NAMED LOCATION YOU WISH TO UPDATE"
Read-Host "Press Enter when you are ready to continue"



####### START OF VARIABLES TABLE #######
# Declares the ID of the tenant you want to connect to
$tenantID = Read-Host "Enter the tenant ID you want to Connect to"
####### END OF VARIABLES TABLE #######


###### OPTION 1 (DEFAULT) - Automatically get the NamedLocationID for policy matching Display Name "Blocked VPNs" using Function "Get-NamedLocationId" #####
# Uncomment the next line to use Option 1
$NamedLocationDisplayName = Read-Host "Enter The Display Name of the Named Location you wish to Update"
Write-Host -ForegroundColor Cyan "Getting the Named Location ID for Named Location $NamedLocationDisplayName"
$NamedLocationID = (Get-NamedLocationId -displayName $NamedLocationDisplayName -tenantID $tenantID).Id
Write-Host -ForegroundColor Green "Done"

###### OPTION 2 -  Manually Declare the Named Location ID you wish to Update #####
# Uncomment the next line to use Option 2
# $NamedLocationID = Read-Host "Enter the NamedLocationID of the Named Location you wish to Update"

####### END OF VARIABLES TABLE #######

# Ensure $NamedLocationID is set
Write-Host -ForegroundColor Cyan "Confirming Named Location ID is populated"
if (-not $NamedLocationID) {
    Write-Error "NamedLocationID is not set. Please ensure you have set it using Option 1 or Option 2."
    exit
}
Write-Host -ForegroundColor Green "Done"

# Call the function to initialize ipRanges and construct params once
Write-Host -ForegroundColor Cyan "Generating Parameter Variable from txt file"
$params = Initialize-IpRangesAndParams
Write-Host -ForegroundColor Green "Done"

#Connect to MgGraph with correct Scope
Write-Host -ForegroundColor Cyan "Connecting to $tenantID with Scopes ""Policy.ReadWrite.ConditionalAccess,Policy.Read.All"""
Write-Host -ForegroundColor Cyan "Enter Username and Password of account with relevant MsGraph Permissions in the Window that pops up"
Connect-MgGraph -NoWelcome -TenantID $tenantID -Scopes Policy.ReadWrite.ConditionalAccess,Policy.Read.All
Write-Host -ForegroundColor Green "Done"

# Update the Named Location
Write-Host -ForegroundColor Cyan "Updating Named Location $NamedLocationDisplayName with Location ID $NamedLocationID"
Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $NamedLocationID -BodyParameter $params
Write-Host -ForegroundColor Green "Done"