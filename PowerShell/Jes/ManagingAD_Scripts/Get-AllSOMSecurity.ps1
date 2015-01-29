#Get-AllSOMSecurity.ps1

Function Get-AllSOMSecurity {
    #search OUs and domain root
    $searcher=New-Object System.DirectoryServices.DirectorySearcher
    $searcher.filter="(|(Objectclass=organizationalunit)(objectclass=domain))"
    
    $results=$searcher.findall()
    
    $results | foreach {
        $dn=$_.properties.distinguishedname[0]
        
        Get-SDMSOMSecurity $dn | foreach {
            #add the DN to each permission
            $_ | Add-Member -MemberType "NoteProperty" -Name "DN" -Value $dn -passthru
        }
    }    
}

#sample usage 
# Get-AllSOMSecurity | select DN,Trustee,Permission,Inherited
# Get-AllSOMSecurity | Format-Table -groupby DN Trustee,Permission,Inherited -autosize
# Get-AllSOMSecurity | where {$_.Trustee -match "IT Admins"} | select DN,Permission,Inherited
