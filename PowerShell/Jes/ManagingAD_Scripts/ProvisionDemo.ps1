#ProvisionDemo.ps1

$groups="Sales Staff","Mobile Users","Las Vegas Staff"
$OU="OU=Sales,OU=Employees,DC=mycompany,DC=local"

$user=New-QADUser -name "Cass Ino" -ParentContainer $OU `
-samAccountName "cino " -UserPassword "P@ssw0rd" `
-firstname "Cass" -LastName "Ino" `
-userprincipalname "cass@mycompany.com" -City "Las Vegas" `
-department "Sales" -Title "Account Rep" -company "Big Company" | 
Enable-QADUser | Set-QADUser -UserMustChangePassword $True

$groups | foreach {Add-QADGroupMember $_ $user} | Out-Null

Get-QADUser $user | select Name,Title,Department,City,MemberOf

