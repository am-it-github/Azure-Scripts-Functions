# This script is designed to Parse Multiple Groups, with descriptions, and Assign users to the groups
# The group will be created as a non-mail enabled Security Group if it doesnt exist already, and just add users to it if it does
# Note that in its current state, this script will only remove _ from the MailNickName Field - if your group name contains additional characters not allowed for this field you will need to adjust the  $groupName.Replace('_','') section of group creation


# This script requires the Following Entra ID roles
# Groups Administrator
# Read Access to users

# This Script Requires the Following MS Graph API Permissions 
# Group.ReadWrite.All
# User.Read.All


# The expected format of the CSV is as follows

# GroupName,UserPrincipalName,Description
# Example_GroupA,user1@domain.com,Description for Group A
# Example_GroupA,user2@domain.com,Description for Group A
# Example_GroupA,user3@domain.com,Description for Group A
# Example_GroupB,user3@domain.com,Description for Group B
# Example_GroupB,user4@domain.com,Description for Group B



# Change the Below to the Path to your CSV
$Path = "PATH_TO_YOUR_CSV"


# Connect to Graph With Required Scope
Connect-MgGraph -Scopes "Group.ReadWrite.All","User.Read.All"

# Import CSV
$entries = Import-Csv -Path $Path

# Group cache to avoid duplicate creation
$groupCache = @{}

# Define the CSV Entries as Variables
foreach ($entry in $entries) {
    $groupName = $entry.GroupName
    $userUPN = $entry.UserPrincipalName
    $description = $entry.Description

    # Check if group already exists
    if (-not $groupCache.ContainsKey($groupName)) {
        $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue

        if (-not $existingGroup) {
            # Create the group
            $newGroup = New-MgGroup -DisplayName $groupName -Description $description -MailEnabled:$false -MailNickname $groupName.Replace('_','') -SecurityEnabled:$true -GroupTypes @()
            # Get the MS Graph Group ID
            $groupId = $newGroup.Id
        } else {
            $groupId = $existingGroup.Id
        }

        # Cache the group to avoid duplication
        $groupCache[$groupName] = $groupId
    }

    # Get user ID
    $user = Get-MgUser -UserId $userUPN
    if ($user) {
        # Add user to group
        New-MgGroupMember -GroupId $groupCache[$groupName] -DirectoryObjectId $user.Id
    }
}

Disconnect-MgGraph