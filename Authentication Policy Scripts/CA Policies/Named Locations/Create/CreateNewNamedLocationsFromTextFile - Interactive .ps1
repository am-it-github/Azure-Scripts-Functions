# THE PURPOSE OF THIS SCRIPT IS TO CREATE A NEW NAMED IP LOCATION IN AZURE POPULATED FROM A PLAINTEXT LIST OF 
# IPV4 ADDRESSES IN CIDR FORMAT

# THIS IS THE INTERACTIVE VERSION OF THE SCRIPT INTENDED TO BE RAN MANUALLY BY AN ADMIN USER
# THE SCRIPT WILL PROMPT FOR ALL VARIABLES REQUIRED TO ACHIEVE THE DESIRED RESULT




#Function to download the IP file, read IP addresses, initialize the ipRanges array, and construct the params hashtable
function Initialize-IpRangesAndParams {


    # File path for the downloaded IP addresses file
    $filePath = Read-Host "Enter the full file path to the ipv4 txt document you want to use"

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


Write-Host -ForegroundColor Red "THE PURPOSE OF THIS SCRIPT IS TO CREATE A NEW NAMED IP LOCATION IN AZURE POPULATED FROM A PLAINTEXT LIST OF IPV4 ADDRESSES IN CIDR FORMAT"
Write-Host -ForegroundColor Red "THIS IS THE INTERACTIVE VERSION OF THE SCRIPT INTENDED TO BE RAN MANUALLY BY AN ADMIN USER"
Write-Host -ForegroundColor Red "BEFORE CONTINUING, YOU WILL NEED TO KNOW THE TENANT ID OF THE AZURE ENVIRONMENT YOU WISH TO CONNECT TO AND THE DISPLAY NAME YOU WANT TO SET FOR YOUR NEW NAMED LOCATION"
Read-Host "Press Enter when you are ready to continue"

####### START OF VARIABLES TABLE #######
# Declares the ID of the tenant you want to connect to
$tenantID = Read-Host "Enter the tenant ID you want to Connect to"
####### END OF VARIABLES TABLE #######


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
Write-Host -ForegroundColor Cyan "Creating new Named Location"
New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params
Write-Host -ForegroundColor Green "Done"
