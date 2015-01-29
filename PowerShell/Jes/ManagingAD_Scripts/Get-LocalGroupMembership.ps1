#Get-LocalGroupMembership.ps1

Function Get-LocalGroupMembership {
    Param([string]$user=$(Throw "You must enter a user name"),
          [string]$computer=$env:computername
    )
    
    [ADSI]$LocalUser="WinNT://$computer/$Name,user"
    
    $groups=$Localuser.psbase.invoke("Groups") | ForEach-Object {
     $_.GetType().InvokeMember("Name", 'GetProperty', `
     $null, $_, $null)
    }
    
    write $groups        
}

#sample usage
#get-localmembership Administrator
#get-localmembership -user "jeff" -computer "XPDESK01"
