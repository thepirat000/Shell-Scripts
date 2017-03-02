#https://programmaticponderings.com/tag/get-tfsitemhistory/
#TFS Power Tools are required

clear

if ( (Get-PSSnapin -Name Microsoft.TeamFoundation.PowerShell -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin Microsoft.TeamFoundation.PowerShell
}

[string] $tfsCollectionPath = "http://tfs/tfs/xxxx"
[string] $locationToSearch = "$/xxx/xxx"
[string] $dateRange = "D2017-02-28T00:00:00~D2017-02-28T23:59:59"
[string] $username = "username"

[Microsoft.TeamFoundation.Client.TfsTeamProjectCollection] $tfs = get-tfsserver $tfsCollectionPath
 
Get-TfsItemHistory $locationToSearch -Server $tfs -Version $dateRange -Recurse -IncludeItems |
    Where-Object { $_.Owner -like "*$username*"} |
    Select-Object -Expand "comment"
    #Select-Object -Expand "workitems" |
    #Select-Object -Expand "Id"
