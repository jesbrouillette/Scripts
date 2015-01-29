#Get-AllUsers.ps1

Function Get-AllUsers {

    $searcher=New-Object DirectoryServices.DirectorySearcher
    $searcher.Filter="(&(objectcategory=person)(objectclass=user))"
    
    $users=$searcher.FindAll()
    
    $users | foreach {

    $obj = New-Object PSObject
    
    $obj | Add-Member -MemberType NoteProperty -Name DN -Value $_.path
    $obj | Add-Member -MemberType NoteProperty -Name sAMAccountname -Value $_.properties.samaccountname[0]

    write $obj
    }
}

#sample usage
# Get-AllUsers | select -First 5
