#Delete-OldQADUser.ps1

$cutoff=190

#samaccount names of accounts to protect from deletion
$ignore="Administrator","krbtgt","jhicks","jeff","rgbiv"

Get-QADUser -Enabled -SizeLimit 0 -IncludedProperties pwdlastset | 
where {$_.pwdlastset -lt (Get-Date).AddDays(-$cutoff) } | 
where {$ignore -notcontains $_.samaccountname} | Remove-QADObject -confirm
