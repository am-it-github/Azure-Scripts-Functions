# Connect to Azure AD
Connect-AzureAD

# Get a list of all groups that start with "grp_az" or "grp-az"
$groups = Get-AzureADGroup -All $true | Where-Object {$_.DisplayName -like "STRING_TO_CHECK_FOR*"}

# Loop through each group and rename it to start with "grp-aad" instead
foreach ($group in $groups) {
    $newName = $group.DisplayName -replace "REGEX_QUERY_FOR_PART_YOU_WANT_TO_CHANGE", "STRING_YOU_WANT_TO_CHANGE_IT_TO"
    Set-AzureADGroup -ObjectId $group.ObjectId -DisplayName $newName
}

# Disconnect from Azure AD
Disconnect-AzureAD
