#Get-DSTree2.ps1

Function Get-DSTree {
    Param([ADSI]$ADSPath="LDAP://DC=mycompany,DC=local",
          [int]$i=0)
    
    [string]$leader=" "
    [int]$pad=$leader.length+$i
    
    $searcher=New-Object directoryservices.directorysearcher
    $searcher.pagesize=100
    $searcher.filter="(&(!objectcategory=person)(!objectcategory=computer)" `
    +"(!objectcategory=group)(!objectcategory=contact)(!objectcategory=domain))"
    $searcher.searchScope="OneLevel"
    $searcher.searchRoot=$ADSPath
    $searcher.PropertiesToLoad.Add("DistinguishedName") | Out-Null
    
    $searcher.FindAll()  | foreach {
        Write-Host ($leader.Padleft($pad)+$_.properties.distinguishedname[0])
        Get-DSTree $_.path ($pad+1)
    }
  }
