
function Get-FileAndSetIPScopes {
    param (
        [string]$url = "https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt",
        [string]$outputFile = "ipv4.txt"
    )
    
    # Download the file
    Invoke-WebRequest -Uri $url -OutFile $outputFile
    
    # Read IP addresses from the file
    $IPScopes = Get-Content -Path $outputFile
    
    return $IPScopes
}

function Update-IPRangesArray {
    param (
        [array]$IPScopes
    )
    
    # Initialize the ipRanges array
    $ipRanges = @()
    
    # Loop through each IP address and add it to the ipRanges array
    foreach ($IPAddress in $IPScopes) {
        $ipRanges += @{
            "@odata.type" = "#microsoft.graph.iPv4CidrRange"
            cidrAddress = $IPAddress
        }
    }
    
    return $ipRanges
}
function Update-NamedLocation {
    param (
        [array]$ipRanges,
        [string]$namedLocationId = "INSERT YOUR NAMED LOCATION ID" #To get this, run "get-MgIdentityConditionalAccessNamedLocation"
    )
    
    # Construct the final $params hashtable
    $params = @{
        "@odata.type" = "#microsoft.graph.ipNamedLocation"
        displayName = "Blocked VPNs"
        isTrusted = $false
        ipRanges = $ipRanges
    }
    
    # Update the Named Location
    # In order for this to work you must connect to MgGraph with "Connect-MgGraph -TenantID "YOUR-TENANT-ID" -Scopes Policy.ReadWrite.ConditionalAccess"
    # Imports the Module
    Import-Module Microsoft.Graph.Identity.ConditionalAccess
    Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $namedLocationId -BodyParameter $params
}

#Command Block calling the arrays and piping in the required information
$IPScopes = Get-FileAndSetIPScopes
$ipRanges = Update-IPRangesArray -IPScopes $IPScopes
Update-NamedLocation -ipRanges $ipRanges
