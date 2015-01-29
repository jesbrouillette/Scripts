#Update-DisplayName2.ps1

$file="c:\ids.csv"

Import-Csv $file | foreach {
    [ADSI]$user="LDAP://"+ $_.distinguishedname
     Write-Host Updating $user.name $_.EmployeeID
    $user.employeeID=$_.EmployeeID
    $user.SetInfo()
}
