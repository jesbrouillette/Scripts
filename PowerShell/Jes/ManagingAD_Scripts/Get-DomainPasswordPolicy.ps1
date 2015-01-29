#Get-DomainPasswordPolicy.ps1

[ADSI]$domain="WinNT://$env:userdomain"

$domain | Format-List `
@{label="Domain";Expression={$env:Userdomain}},`
@{label="MinPwdLength";Expression={$_.MinPasswordLength}},`
@{label="MinPwdAge (Days)";Expression={$_.MinPasswordAge.value/86400}},`
@{label="MaxPwdAge (Days)";Expression={$_.MaxPasswordAge.value/86400}},`
@{label="Password History";Expression={$_.PasswordHistoryLength}},`
@{label="Bad Attempts Allowed";Expression={$_.MaxBadPasswordsAllowed}},`
@{label="LockoutDuration (Min)";Expression={$_.AutoUnlockInterval.value/60}},`
@{label="LockoutObservation (Min)";Expression={$_.LockoutObservationInterval.value/60}}

#If you prefer, change format-list to Select. With 
#this cmdlet the hash table needs to be 'Name' instead of 'label'