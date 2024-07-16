#use wget to download the required file from github and save to current working directory
#This should work but on my laptop is hitting issues due to proxy
Invoke-WebRequest -Uri https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt -OutFile ipv4.txt


# Read IP addresses from the file "ipv4.txt"
$IPScopes = Get-Content -Path "ipv4.txt"
# Declares the Named Location ID for use in the Update cmdlet later
# YOU CAN MANUALLY DO THIS BY UNCOMMENTING THE BELOW
# $NamedLocationID = "YOUR ID" #To get this, run "get-MgIdentityConditionalAccessNamedLocation"
# Get the named location and store the Id in a variable
$namedLocation = Get-MgIdentityConditionalAccessNamedLocation | Where-Object { $_.DisplayName -eq "Blocked VPNs" }
$blockedVPNsId = $namedLocation.Id

# Initialize the ipRanges array
$ipRanges = @()

# Loop through each IP address in your txt file and add it to the ipRanges array
foreach ($IPAddress in $IPScopes) {
    $ipRanges += @{
        "@odata.type" = "#microsoft.graph.iPv4CidrRange"
        cidrAddress = $IPAddress
    }
}

# Construct the final $params hashtable, using the ip ranges array from above
$params = @{
    "@odata.type" = "#microsoft.graph.ipNamedLocation"
    displayName = "Blocked VPNs"
    isTrusted = $false
    ipRanges = $ipRanges
}

# Update the Named Location
# In order for this to work you must connect to MgGraph with "Connect-MgGraph -TenantID "YOUR-TENANT-ID" -Scopes Policy.ReadWrite.ConditionalAccess"
Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $blockedVPNsId -BodyParameter $params


