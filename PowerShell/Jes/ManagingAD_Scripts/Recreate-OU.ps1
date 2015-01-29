#Recreate-OU.ps1

#csv file of OU names
$file="c:\employeeOUs.csv"

Import-Csv $file | foreach { 
    $dn=$_.distinguishedname
    
    #replace top level OU name with new top level OU
    $dn=$dn.Replace("OU=Employees","OU=BackupOU")
    
    #get parent distinguishedname
    $parent=$dn.substring($dn.IndexOf(",")+1)
    
    Write-Host Creating $_.name under $parent -ForegroundColor Cyan
    
    #connect to the parent OU
    [ADSI]$parentOU="LDAP://"+$parent
    
    #create the child OU
    $ou=$parentOU.Create("organizationalunit","OU="+$_.name)
    $ou.SetInfo()
}
