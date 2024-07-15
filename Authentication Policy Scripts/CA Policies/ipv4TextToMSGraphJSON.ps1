#use wget to download the required file from github and save to current working directory
#This should work but on my laptop is hitting issues due to proxy
Invoke-WebRequest -Uri https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt -OutFile ipv4.txt


# Read IPs from the file
$ips = Get-Content -Path "ipv4.txt"

#Format the IPs into the required JSON structure and store in $ipList
$ipList = @()
foreach ($ip in $ips) {
    $ipList += @{
        ipAddress = $ip
        odataType = "#microsoft.graph.iPv4CidrRange"  # Adjust if necessary for IPv6
    }
}

##### Manually construct the JSON string
$jsonString = "{`n"                                                                       ## Adds "{"" followed by a new line
#### OPTIONAl to add the type - dont think its needed as we will be using this to update a policy, not make a new one
#$jsonString += '    "@odataType": "#microsoft.graph.ipNamedLocation",' + "`n"            ## Adds "@odataType:#microsoft.graph.ipNamedLocation"," followed by new line
#### OPTIONAL - sets name or overwrites existing name
#$jsonString += '    "displayName": "' + "Known VPN IP CIDR Ranges" + '",' + "`n"         ## Adds "displayName:Known VPN UP CIDR RANGES"," followed by new line
$jsonString += '    "isTrusted": ' + $false.ToString().ToLower() + ",`n"                  ## Adds "isTrusted:$False","" followed by new line
$jsonString += '    "ipRanges": [' + "`n"                                                 ## Adds "ipRanges: [""  followed by new line
foreach ($ip in $ipList) {                                                                ## Loops through the array of IP's adding {@odata.type" = "#microsoft.graph.iPv4CidrRange", cidrAddress = "IP.FROM.ARRAY/CIDR},"
    $jsonString += '        {' + "`n"
    $jsonString += '            "@odataType": "' + $ip.odataType + '",' + "`n"
    $jsonString += '            "cidrAddress": "' + $ip.ipAddress + '"' + "`n"
    $jsonString += '        },' + "`n"
}

# Remove the trailing comma
if ($ipList.Count -gt 0) {
    $jsonString = $jsonString.Substring(0, $jsonString.Length - 3) + "}`n"               ## Once all IPs processed, removes the trailing comma from last entry, then adds new line
}
$jsonString += '    ]' + "`n"                                                            ## Closes the Open IpRanges JSON section by adding "]" followed by a new line
$jsonString += "}"                                                                       ## Closes the Entire JSON File by adding a "}""

#Save the JSON to a file with proper encoding
$jsonFilePath = "NamedLocationPolicy.json"
$jsonString | Out-File -FilePath $jsonFilePath -Encoding utf8

# Output the JSON file path to the console
Write-Output "JSON file created at: $jsonFilePath"




