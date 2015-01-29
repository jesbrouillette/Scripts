#Get-UserGroups.ps1

Function Get-UserGroups {
    Param([string]$user=$(Throw "You must enter a user name"),
          [string]$computer=$env:computername,
          [System.Management.Automation.PSCredential]$credential)
    
    $query="ASSOCIATORS OF {Win32_UserAccount.Domain=`'$computer`',Name=`'$user`'} WHERE ResultClass=Win32_Group"
    
        if ($credential) {
            $Groups=Get-WmiObject -query $query -computername $computer -Credential $credential
        }
        else
        {
            $Groups=Get-WmiObject -query $query -computername $computer 
        }
        
    foreach ($group in $Groups) {
        write $group.name
      }   

} 

#sample usage
# get-usergroups administrator
# get-usergroups  -user JSmith -computer XPDESK01
# get-usergroups  -user JSmith -computer XPDESK01 -credential $savedcred


