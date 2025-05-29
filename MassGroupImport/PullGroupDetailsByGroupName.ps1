Connect-MgGraph -Scopes "Group.Read.All"

$GroupsFromCsv = Import-Csv -Path "C:\Users\**user**\Downloads\EGroups.csv"

$GroupDetails = @()
foreach ($GroupRow in $GroupsFromCsv) {
    $GroupName = $GroupRow.DisplayName
    
    $Group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
    if ($null -eq $Group) {
        Write-Host "Group '$GroupName' not found." -ForegroundColor Yellow
        continue
    }
    
    $Description = $Group.Description
    
    $Owners = Get-MgGroupOwner -GroupId $Group.Id
    $OwnerUPNs = $Owners | ForEach-Object { Get-MgUser -UserId $_.Id } | Select-Object -ExpandProperty UserPrincipalName
    $OwnersString = $OwnerUPNs -join ","
    
    $Members = Get-MgGroupMember -GroupId $Group.Id
    $MemberUPNs = $Members | ForEach-Object { Get-MgUser -UserId $_.Id } | Select-Object -ExpandProperty UserPrincipalName
    $MembersString = $MemberUPNs -join ","
    
    $GroupDetails += [PSCustomObject]@{
        DisplayName = $Group.DisplayName
        Description = $Description
        Owners      = $OwnersString
        Members     = $MembersString
    }
}

$GroupDetails | Export-Csv -Path "C:\Users\**user**\Downloads\GroupDetailsOutput.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Export completed. Output saved to GroupDetailsOutput.csv" -ForegroundColor Green

Disconnect-MgGraph
