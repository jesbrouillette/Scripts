#Get-GPOSecurity.ps1

Function Get-GPOSecurity {
    Get-SDMgpo * | select displayname | foreach {
        $gponame=$_.displayname
        Get-SDMgpoSecurity $gponame | foreach {
            $_ | Add-Member -name "GPO" -MemberType "NoteProperty" `
            -value $gponame -passthru 
        }
    }
}

#sample usage
# Get-GPOSecurity
# Get-GPOSecurity | where {$_.trustee -match "sales"}
# Get-GPOSecurity | where {$_.gpo -match "sales"} | Format-Table GPO,Trustee,Permission -autosize
# Get-GPOSecurity | where {$_.permission -match "apply"} | Format-Table GPO,Trustee,Permission -autosize

 
