<#
	.SYNOPSIS 
		Renames a server, adds it to a domain, and places it into a specific OU.
	.DESCRIPTION
		Join-DomainWithInputs.ps1 Renames a server, then uses native PowerShell to create the AD account, place it into a specific OU, and join the server into the domain.  DNS is also set to the primary and secondary DC's as given in the inputs.
	.PARAMETER $ADFQDN
		Fully Qualified Domain Name to join.
	.PARAMETER $ADUser
		Active Directory user name with permission to join a server to the domain.
	.PARAMETER $ADOUPath
		OU path to place the new server.
	.PARAMETER $DomainPwd
		Password for the domain account.		
	.PARAMETER $LocUser
		Local user name with permission to join a server to the domain.
	.PARAMETER $LocalPwd
		Password for the local user.
	.PARAMETER $NewSysName
		New name for the server.		
	.PARAMETER $PriDCIP
		IP Address for the Primary Domain Controller.  This will be used as the Primary DNS address.
	.PARAMETER $SecDCIP
		IP Address for the Secondary Domain Controller.  This will be used as the Secondary DNS address.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays in the RightScale Dashboard only.
	.NOTES
		Name:       Join-DomainWithInputs.ps1
		Author:     Jes Brouillette - RightScale
		Last Edit:  05/10/2010 00:35 CST
		Purpose:	Renames a server, adds it to a domain, and places it into a specific OU.  For use as a RightScript.
#>

#==== Start: Script Variables ================================================#

param (
	[string]$ADFQDN		= $ENV:AD_FQDN,
	[string]$ADUser 	= $ADFQDN + "\" + $ENV:AD_USER,
	[string]$ADOUPath 	= $ENV:AD_OU_PATH,
	[string]$DomainPwd	= $ENV:AD_PWD,
	[string]$LocUser	= ".\" + $ENV:LOCAL_USER,
	[string]$LocalPwd	= $ENV:LOCAL_PWD,
	[string]$NewSysName = $ENV:NEWNAME,
	[string]$PriDCIP	= $ENV:AD_DC_IP1,
	[string]$SecDCIP	= $ENV:AD_DC_IP2
)	

#==== END: Script Variables ==================================================#

$ErrorActionPreference = "Stop"

$ScriptName	= $MyInvocation.MyCommand.Name

$NewSysName	= [System.Text.RegularExpressions.Regex]::Replace($NewSysName,"[^1-9a-zA-Z_]","_")

$ADPwd		= ConvertTo-SecureString $DomainPwd -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential $ADUser,$ADPwd

$LocPwd		= ConvertTo-SecureString $LocalPwd -AsPlainText -Force
$LocCred 	= New-Object System.Management.Automation.PSCredential $LocUser,$LocPwd

$CompSys	= gwmi Win32_ComputerSystem -Authentication 6
$NACs		= gwmi Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE"

$Status		= "" | Select Domain,Name,DNS

$DNS		= @()

#==== END: Script Variables ==================================================#

if ($CompSys.Domain -match $ADFQDN) {
	Write-Host "JOIN-DOMAIN:  $($CompSys.Name) is already a member of $($CompSys.Domain).  $ScriptName cannot complete."
	$Status.Domain = 1
} else {
	$Status.Domain = 0
}

if ($CompSys.Name -match $NewSysName) {
	Write-Host "JOIN-DOMAIN:  $($CompSys.Name) is already named $NewSysName.  $ScriptName cannot complete."
	$Status.Name = 1
} else {
	$Status.Name = 0
}

if (!($PriDCIP -and (Test-Connection $PriDCIP -Quiet -Count 1))) {
	Write-Host "JOIN-DOMAIN:  $PriDCIP was not found."
	$Status.DNS = 1
} else {
	$Status.DNS = 0
	$DNS += $PriDCIP
}

if (!($SecDCIP -and (Test-Connection $SecDCIP -Quiet -Count 1))) {
	Write-Host "JOIN-DOMAIN:  $SecDCIP was not found."
} else {
	$Status.DNS = 0
	$DNS += $SecDCIP
}

if ($Status.DNS -eq 1) {
	Write-Host "JOIN-DOMAIN: No DNS servers were able to be contacted.  $ScriptName cannot complete."
}

if ($Status.DNS -eq 0 -and $Status.Domain -eq 0 -and $Status.Name -eq 0) {
	$NACS | % { $_.SetDNSServerSearchOrder($DNS) }
	Rename-Computer -NewName $NewSysName
	Add-Computer -DomainName $ADFQDN -OUPath $ADOUPath -Credential $DomainCred -LocalCredential $LocCred -Options AccountCreate,JoinWithNewName
	Write-Host "JOIN-DOMAIN:  SUCCESS:  Server has been renamed to $NewSysName and joined to $ADFQDN"
	Write-Host "JOIN-DOMAIN:  Rebooting..."
	Restart-Computer -Force
} else {
	Write-Host "JOIN-DOMAIN:  $ScriptName was not able to make changes."
}