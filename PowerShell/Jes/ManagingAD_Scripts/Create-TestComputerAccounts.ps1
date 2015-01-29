#Create-TestComputerAccounts.ps1

Function New-ComputerAccount {
    Param([string]$parent=$(Throw "You must specify a parent container."),
    [string]$name=$(Throw "You must specify a computer name"),
    [string]$description="",
    [string]$location="",
    [string]$operatingSystem="",
    [string]$operatingSystemVersion="",
    [string]$operatingSystemServicePack="",
    [boolean]$Enable=$True
    )

    New-Variable UF_WORKSTATION_TRUST_ACCOUNT 0x1000 -option Constant
    New-Variable UF_ACCOUNTDISABLE  0x2 -option Constant
     If ($enable) {
        $UAC = $UF_WORKSTATION_TRUST_ACCOUNT 
        }
     else   {
         $UAC = $UF_WORKSTATION_TRUST_ACCOUNT -bor $UF_ACCOUNTDISABLE
        }
        
    #Name must be UPPERCASE and 15 or less characters
    $name=$name.ToUpper()
    
    [ADSI]$OU="LDAP://$parent"
    $newcomputer=$OU.create("computer","CN=$name")
    $newcomputer.put("samaccountname",$name+"$")
    $newcomputer.put("userAccountControl", $UAC)
    $newcomputer.setinfo()
    $newcomputer.setpassword($name.ToLower()+"$")
    $newcomputer.put("Description",$description)
    $newcomputer.put("location",$location)
    $newcomputer.put("operatingsystem",$operatingSystem)
    $newcomputer.put("operatingsystemversion",$operatingSystemVersion)
    $newcomputer.put("operatingsystemservicepack",$operatingSystemServicePack)
    $newcomputer.put("dNSHostName",$name.ToLower()+".mycompany.local")
    $newcomputer.setinfo()

}

$start=12
$end=33
$total=($start..$end).count
#define default values
$parent="OU=Company Desktops,DC=mycompany,DC=local"
$description="Sales Desktop"
$location="San Francisco"
$operatingsystem="Windows XP Professional"
$operatingSystemVersion="5.1 (2600)"
$operatingSystemServicePack="Service Pack 2"

$i=0
$start..$end | foreach {
    $i++
    [int]$p=($i/$total)*100
    $name="XPSales$_"
    Write-Progress "Creating Computer" $name -CurrentOperation "$p% complete"
    New-ComputerAccount -parent $parent -name $name `
    -Description $description `
    -location $location -operatingsystem $operatingsystem `
    -operatingsystemversion $operatingSystemVersion `
    -operatingSystemServicePack $operatingSystemServicePack
}

Write-Progress "Creating Computer" "Done!" -Completed
