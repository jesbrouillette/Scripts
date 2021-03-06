<#
	.SYNOPSIS 
		Renames a server, adds it to a domain, and places it into a specific OU.
	.DESCRIPTION
		Join-DomainWithInputs.ps1 Renames a server, then uses native PowerShell to create the AD account, place it into a specific OU, and join the server into the domain.  DNS is also set to the primary and secondary DC's as given in the inputs.
	.PARAMETER $ADFQDN
		Fully Qualified Domain Name in which the object will be moved.
	.PARAMETER $ADUser
		Active Directory user name with permission to join a server to the domain.
	.PARAMETER $DomainPwd
		Password for the domain account.
	.PARAMETER $ADObject
		Active Directory Object to move.		
	.PARAMETER $ADOUTarget
		Organizational Unit Target path.
	.PARAMETER $ADDC
		Active Directory Domain Controller to run the command through.  <OPTIONAL>
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays in the RightScale Dashboard only.
	.NOTES
		Name:       Move-OUObject.ps1
		Author:     Jes Brouillette - RightScale
		Last Edit:  05/10/2010 00:35 CST
		Purpose:	Renames a server, adds it to a domain, and places it into a specific OU.  For use as a RightScript.
#>

#==== Start: Script Variables ================================================#

param (
	[string]$ADFQDN		= $ENV:AD_FQDN,
	[string]$ADUser 	= $ADFQDN + "\" + $ENV:AD_USER,
	[string]$DomainPwd	= $ENV:AD_PWD,
	[string]$ADObject 	= $ENV:AD_Object,
	[string]$ADOUTarget	= $ENV:AD_OU_Target,
	[string]$ADDC		= $ENV:AD_DC
)	

#==== END: Script Variables ==================================================#

$ErrorActionPreference = "Stop"

$ScriptName	= $MyInvocation.MyCommand.Name

$ADPwd		= ConvertTo-SecureString $DomainPwd -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential $ADUser,$ADPwd

#==== END: Script Variables ==================================================#

Write-Host "MOVE-OUOBJECT:  Moving $ADObject to $ADOUTarget."

Try {
	if ($ADDC) { Move-ADObject -Identity $ADObject -TargetPath $ADOUTarget -Credential $DomainCred -Server $ADDC }
	else { Move-ADObject -Identity $ADObject -TargetPath $ADOUTarget -Credential $DomainCred }
}
Catch { Write-Host "MOVE-OUOBJECT:  $ScriptName failed." ; exit }
Finally { Write-Host "MOVE-OUOBJECT:  $ScriptName completed." }