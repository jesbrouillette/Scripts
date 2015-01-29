# Get-RSOPUser.ps1

Function Get-RSOPUser {
    Param([string]$user="$env:UserDomain\Administrator",
          [string]$computername=$env:computername)
        
   $domain=$user.split("\")[0]
   $name=$user.split("\")[1]
   
   $account=Get-WmiObject win32_useraccount -Filter "name='$name' AND domain='$domain'"
   
   if ($account) {
        $rsopname=($account.SID).Replace("-","_")  
        write $rsopname
   }
   else {
        Write-Error "Failed to find $user on $computername"
   }

}

#sample usage
# $usersid=Get-RSOPUser -user "mycompany\tsawyer" -computername "XPDesk01"
# Get-WmiObject -namespace root\rsop\user\$usersid -computername "XPDesk01" -Class RSOP_GPO
