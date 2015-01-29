#Create-TestQADComputerAccounts.ps1

$start=1
$end=10
$total=($start..$end).count

#define default values
$parent="OU=Servers,DC=mycompany,DC=local"
$description="Test Server"
$location="Miami"
$operatingsystem="Windows Server 2003"
$operatingSystemVersion="5.2 (3790)"
$operatingSystemServicePack="Service Pack 2"
$UAC=4096   #4098 = disabled

$i=0

$start..$end | foreach {
    $i++
    [int]$p=($i/$total)*100
    $name="TESTSERVER$_"
    $sam=$name+"$"
    $dns=$name.ToLower()+".mycompany.local"

    Write-Progress "Creating Computer" $name -CurrentOperation "$p% complete"
    
    New-QADObject -ParentContainer $parent -Name $name `
    -type "computer" -Description $description -ObjectAttributes @{
    samaccountname=$sam;useraccountcontrol=$UAC;location=$location; `
    operatingsystem=$operatingsystem;operatingSystemServicePack=$operatingSystemServicePack; `
    operatingSystemVersion=$operatingSystemVersion;dNSHostName=$dns } 
}

Write-Progress "Creating Computer" "Done!" -Completed
