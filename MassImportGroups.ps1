Connect-MgGraph -Scopes "Group.ReadWrite.All"

Import-Csv -Path "C:\Users\**user**\Downloads\EGroups.csv" | ForEach-Object {
    $GroupName = "EN-" + $_.DisplayName
    $GroupDescription = $_.GroupDescription
    $OwnerEmails = $_.OwnerEmail -split "," | Where-Object { $_.Trim() -ne "" }
    $MemberEmails = $_.MemberEmails -split "," | Where-Object { $_.Trim() -ne "" }

    if ([string]::IsNullOrEmpty($GroupDescription)) {
        $GroupDescription = $null
    }

    $ExistingGroup = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue

    if ($ExistingGroup) {
        $confirmation = Read-Host "Group '$GroupName' already exists. Do you want to create it again? (Y/N)"
        if ($confirmation -ne 'Y') {
            Write-Host "Skipping group creation for: $GroupName"
            return
        }
    }

    try {
        $GroupParams = @{
            DisplayName     = $GroupName
            MailEnabled     = $false
            SecurityEnabled = $true
            MailNickname    = $GroupName
        }
        
        if ($GroupDescription) {
            $GroupParams["Description"] = $GroupDescription
        }

        $CreatedGroup = New-MgGroup @GroupParams
    } catch {
        Write-Host "Failed to create group: $GroupName. Error: $_"
        continue
    }

    if ($OwnerEmails.Count -gt 0) {
        foreach ($OwnerEmail in $OwnerEmails) {
            $Owner = Get-MgUser -Filter "UserPrincipalName eq '$OwnerEmail'"
            if ($null -ne $Owner) {
                New-MgGroupOwner -GroupId $CreatedGroup.Id -DirectoryObjectId $Owner.Id
            } else {
                Write-Host "Owner $OwnerEmail not found in Azure AD."
            }
        }
    } else {
        Write-Host "No owners found for group: $GroupName, skipping owner assignment."
    }

    if ($MemberEmails.Count -gt 0) {
        foreach ($MemberEmail in $MemberEmails) {
            $Member = Get-MgUser -Filter "UserPrincipalName eq '$MemberEmail'"
            if ($null -ne $Member) {
                New-MgGroupMember -GroupId $CreatedGroup.Id -DirectoryObjectId $Member.Id
            } else {
                Write-Host "Member $MemberEmail not found in Azure AD."
            }
        }
    } else {
        Write-Host "No members found for group: $GroupName, skipping member assignment."
    }
}

Disconnect-MgGraph
