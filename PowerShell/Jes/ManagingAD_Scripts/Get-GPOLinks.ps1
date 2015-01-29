#Get-GPOLinks.ps1
#this function requires the free PowerShell GPO cmdlets from GPOGuy.com

Function Get-GPOLinks {
  
#get all GPO objects and save them
$all=Get-SDMgpo *

#search OUs and domain root
$searcher=New-Object System.DirectoryServices.DirectorySearcher
$searcher.filter="(|(Objectclass=organizationalunit)(objectclass=domain))"

$results=$searcher.findall()

$results | foreach {
    $dn=$_.properties.distinguishedname[0]
    #get GPO Links
    $gplink=Get-SDMgplink $dn
    
    if ($gplink.count -gt 0) {
    #enumerate each linked GPO
        foreach ($gpo in $gplink) {
           $gpmatch = $all | where {$_.id -eq $gpo.gpoid} 
           #there may be multiple matches for a single GPO
           $gpmatch | foreach {
            $_ | Add-Member -Name "DN" -MemberType NoteProperty -Value $dn -force
            $_ | Add-Member -Name "Enabled" -MemberType NoteProperty -Value $gpo.Enabled -force
            $_ | Add-Member -Name "Enforced" -MemberType NoteProperty -Value $gpo.Enforced -force
            $_ | Add-Member -Name "SOMLinkOrder" -MemberType NoteProperty -Value $gpo.SOMLinkOrder -force
           write $_
            }
         } 
    }      
  }
}

#sample usage
# Get-GPOLinks 
# Get-GPOLinks | select DN,Displayname,*time,enabled,enforced
# Get-GPOLinks | where {$_.displayname -like "*sales*"}  | select dn,displayname,enabled,enforced
# Get-GPOLinks | where {!$_.enabled} | Select DN,Displayname



