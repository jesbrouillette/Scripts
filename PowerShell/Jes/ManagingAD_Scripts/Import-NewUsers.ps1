#Import-NewUsers.ps1

#sample CSV heading
# "Name,Firstname,Lastname,SAMAccountname,Telephone,Office,Department,Title,City,Company" 

$file="C:\newusers.csv"

if ((Get-Item $file -ea "silentlycontinue" ).exists) {

    Import-Csv $file | ForEach-Object {
        $OU=('OU=' + $_.Department + ',OU=Employees,DC=mycompany,dc=local')
        
        Write-Host Creating $_.samaccountname -ForegroundColor Green
        
    	New-QADUser -parentcontainer $OU `
        -name ($_.FirstName+' '+$_.LastName) `
        -samAccountName $_.samaccountname -Notes "Imported User Account" `
        -firstname $_.FirstName -lastname $_.LastName `
        -title $_.title -department $_.department -company "mycompany.com" `
        -phonenumber $_.Telephone -userpassword "P@ssw0rd" `
        -office $_.Office -userprincipalname ($_.samaccountname+'@mycompany.com') `
        -displayname ($_.FirstName+' '+$_.LastName) `
        -City ($_.City) `
        -objectattributes @{"Comment"="created by PowerShell"} | 
        Enable-QADUser | Set-QADUser -UserMustChangePassword $True
    
    }

}
else {

    Write-Host "Can't find $file." -ForegroundColor Red
}

