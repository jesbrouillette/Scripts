# Get-DSTree.ps1

Function Get-DSTree {

    Param([string]$container,[int]$i=0)
    
    [string]$rootDN="LDAP://"+$container
    [string]$leader=" "
    [int]$pad=$leader.length+$i
    
    Write-Host ($leader.Padleft($pad)+$container)
    
    $dse=New-Object DirectoryServices.DirectoryEntry $rootDN
    
    $dse.psbase.children | where {$_.objectcategory -notmatch "Person" `
    -AND $_.objectcategory -notmatch "Computer" `
    -AND $_.objectcategory -notmatch "Group" `
    -AND $_.objectcategory -notmatch "Contact"} | 
     ForEach-Object {
        [string]$dn=$_.distinguishedName
         Get-DSTree $dn ($pad+1)
     }  
}

#sample usage
# Get-DSTree "mycompany.local"
