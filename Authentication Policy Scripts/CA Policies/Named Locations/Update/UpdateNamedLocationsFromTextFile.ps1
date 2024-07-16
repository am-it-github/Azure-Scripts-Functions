
#If you hit NTLM errors due to proxy, manually download the file and save it in same directory as this script
#use wget to download the required file from github and save to current working directory
Invoke-WebRequest -Uri https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt -OutFile ipv4.txt


# Read IP addresses from the file "ipv4.txt"
$IPScopes = Get-Content -Path "ipv4.txt"


###### OPTION 1  #####
# Manually Declare the Named Location ID you wish to Update
# Declares the Named Location ID
# $NamedLocationID = "YOUR ID" #To get this, run "get-MgIdentityConditionalAccessNamedLocation"
###### END OF OPTION 1 ####


###### OPTION 2 (DEFAULT) #####
# COMMENT OUT IF MANUALLY DECLAIRING A NAMED LOCATION ID ABOVE
#Connect to MgGraph with correct Scope
Connect-MgGraph -TenantID $tenantID -Scopes Policy.ReadWrite.ConditionalAccess
# COMMENT OUT IF MANUALLY DECLAIRING A NAMED LOCATION ID ABOVE
# Get the named location for locations matching "Blocked VPNs"
$namedLocation = Get-MgIdentityConditionalAccessNamedLocation | Where-Object { $_.DisplayName -eq "Blocked VPNs" }
# COMMENT OUT IF MANUALLY DECLAIRING A NAMED LOCATION ID ABOVE
# Extract the ID from the above variable
$blockedVPNsId = $namedLocation.Id
###### END OF OPTION 2 ####


#Declares the ID of the tenant you want to connect to
$tenantID = "YOUR_TENANT_ID"


############    DO NOT CHANGE BELOW THIS LINE    #############
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

############    DO NOT CHANGE ABOVE THIS LINE    #############

#Connect to MgGraph with correct Scope
Connect-MgGraph -TenantID $tenantID -Scopes Policy.ReadWrite.ConditionalAccess

# Imports the Module
Import-Module Microsoft.Graph.Identity.ConditionalAccess

# Change $blockedVPNsId to $NamedLocationID if you have gone with Option 1 Above
# Update the Named Location
Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $blockedVPNsId -BodyParameter $params


