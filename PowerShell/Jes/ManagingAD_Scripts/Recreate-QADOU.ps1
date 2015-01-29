#Recreate-QADOU.ps1

#xml file of OU names
$file="c:\employeeOUs.xml"
$imported=Import-Clixml $file

#calculate total number of objects minus 1 because
#we don't need the root OU
[int]$count=($imported | Measure-Object).count-1

$imported | select -Last $count | foreach { 
    $dn=$_.distinguishedname

    $name=$_.ou

    #replace top level OU name with new top level OU
    $dn=$dn.Replace("OU=Employees","OU=BackupOU")

    #get parent distinguishedname
    $parent=$dn.substring($dn.IndexOf(",")+1)

    #get rid of the trailing ' at the end of the distinguishedname
    $parent=$parent.substring(0,$parent.length-1)

    New-QADObject -parent $parent -name $name  `
    -type organizationalunit -Description $_.description 
   }
