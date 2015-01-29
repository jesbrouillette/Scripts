#New-Subnet.ps1

Function New-Subnet {
    Param([string]$ip=$(Throw "You must specify an IP address block like 172.16.10.0/24"))
    
    $forest=[System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    $context=New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext "forest",$forest.name
    $subnet=New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectorySubnet $context,$ip
    $subnet.save()
    
    write $subnet.name
}

#sample usage
# New-Subnet "172.16.10.0/24"

# for ($i=10;$i -lt 250;$i+=10) { New-Subnet "10.100.$i.0/24"}
