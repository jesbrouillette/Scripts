#Import-Users.ps1

$data="newusers.csv"
$imported=Import-Csv $data 

#retrieve list of csv column headings
#Each column heading should correspond to an
#ADSI user property name
$properties=$imported |Get-Member -type noteproperty | `
where {$_.name -ne "OU"  -and $_.name -ne "Password" `
-and $_.name -ne "Name" -and $_.name -ne "sAMAccountName"}

 for ($i=0;$i -lt $imported.count;$i++) {
    Write-Host "Creating User" $imported[$i].Name "in" $imported[$i].OU
    
    [ADSI]$OU=("LDAP://"+$imported[$i].OU)
   
    $newUser=$OU.Create("user","CN="+$imported[$i].Name)
    $newUser.Put("sAMAccountName",$imported[$i].samAccountname)
    #commit changes to Active Directory
    $newUser.SetInfo()
    #set a password 
    $newUser.SetPassword($imported[$i].Password)
       
       foreach ($prop in $properties) {

        #set additional properties
        $value=$imported[$i].($prop.name)
        if ($value.length -gt 0) {
            #only set properties that have values
            $newUser.put($prop.name,$value)
            }
        }
        
    $newUser.SetInfo()
    #repeat for next imported user
 }
 
