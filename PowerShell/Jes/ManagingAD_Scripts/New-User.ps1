#New-User.ps1

Function New-User {
#You will need to change the default container path
    Param([string]$OUPath="CN=Users,DC=company,DC=com",
          [string]$Name=$(Throw "You must enter a first and last name"),
          [string]$SAM=$(Throw "You must enter a SAMAccountname"),
          [string]$password="P@ssw0rd",
          [string]$description="Created "+(get-date),
          [string]$upnsuffix="company.com",
          [boolean]$enable=$True,
          [boolean]$forcepwd=$True
    )
    
    #validate that a first and last name was entered
    if ($Name.split(" ").Count -ne 2) {
        Write-Warning "You must enter a first and last name for the name parameter."
        Return       
    }
    
    [ADSI]$OU="LDAP://$OUPath"

    #if OU doesn't exist quit the function
    if (!$OU.DistinguishedName) {
        Write-Warning "Failed to connect to $OUPath"
        return
    } 
      
    #Add the user object as a child to the OU
    $newUser=$OU.Create("user","CN=$name")
    $newUser.Put("sAMAccountName",$SAM)
    
    #commit changes to Active Directory
    $newUser.SetInfo()
    
    #set a password 
    $newUser.SetPassword($password)
    
    #Define some other user properties
    $newUser.Put("DisplayName",$name)
    $newUser.Put("UserPrincipalName","$sam@$upnsuffix")
    $newUser.Put("Description",$description)
   
    #first name
    $newUser.Put("GivenName",$name.split()[0])
     #last name
    $newUser.Put("sn",$name.split()[1])
    
    #enable account = 544
    #disable account = 546
    if ($enable) {
        $uac=544 
        }
    else {
        $uac=546
        }
    
    $newUser.Put("UserAccountControl",$uac)
    
    if ($forcepwd) {
        #flag the account to force password change at next logon
        $newUser.Put("pwdLastSet",0) 
        }
    
    #commit changes to Active Directory
    $newUser.SetInfo()

}

#sample usage
#specify the OU where you want to create the account
# $OU="OU=Testing,DC=mycompany,DC=Local"
# New-User -OUPath $ou -Name "Charlie Tuna" -sam "Ctuna" -upn "mycompany.com"
