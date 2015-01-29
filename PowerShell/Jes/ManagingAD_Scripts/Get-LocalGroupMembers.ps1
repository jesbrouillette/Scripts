#Get-LocalGroupMembers.ps1

Function Get-LocalGroupMembers {
    Param([string]$group=$(Throw "You must enter a group name"),
          [string]$computer=$env:computername,
          [System.Management.Automation.PSCredential]$credential
          )
  
$query="ASSOCIATORS OF {Win32_Group.Domain=`'$computer`',Name=`'$group`'} WHERE ResultClass=Win32_UserAccount"

    if ($credential) {
        $members=Get-WmiObject -query $query -computername $computer `
        -Credential $credential
    }
    else
    {
        $members=Get-WmiObject -query $query -computername $computer 
    }
    
foreach ($member in $members) {
    write $member.caption
  }   

} 

#sample usage
#Get-LocalGroupMembers "Administrators"



