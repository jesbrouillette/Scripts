<#
	.SYNOPSIS 
		Changes existing registry keys.
	.DESCRIPTION
		Set-Reg.ps1 changes existing registry keys.  Before the change a report is generated of existing settings, and checks after the changes were made to validate the new settings.
	.PARAMETER root
		Registry root in which the key is located.
	.PARAMETER key
		Registry key containing the property to change.
	.PARAMETER subnet
		First three octets of the IP subnet to scan and change keys.
	.PARAMETER items
		Array with property names and values to change.  Multiple names/values are accepted as an array of arrays.
		IE: @(@("IsDomainMaster",$false),@("MaintainServerList","No")) would be to changet they key IsDomainMaster to $false, and change MaintainServerList to No.		
	.PARAMETER postLog
		File name for the log containing the post-change settings.
	.PARAMETER preLog
		File name for the log containing the pre-change settings.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays a popup for user notification before logoff.
	.EXAMPLE
		C:\PS> .\Set-Reg.ps1
		Sets default values for IsDomainMaster as FALSE and MaintainServerList as no within the key HKLM:\SYSTEM\CurrentControlSet\services\Browser\Parameters
	.NOTES
		Name:       Set-Reg.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/10/2010 00:35 CST
		Purpose:	2010 Scripting Games: Advanced Event 9--Logging Out Users Forcibly Based on a Program's Launch
#>
[CmdletBinding()]
param (
	
	#Registry root in which the key is located.
	[parameter(Position=0,HelpMessage="Registry root in which the key is located.")]
	[string]$root = "HKLM",

	[parameter(Position=1,HelpMessage="Registry key containing the property to change.")]
	[string]$key = "SYSTEM\CurrentControlSet\services\Browser\Parameters",
	
	[parameter(Position=2,HelpMessage="First three octets of the IP subnet to scan and change keys.")]
	[string]$subnet = "127.0.0",
	
	[parameter(Position=3,HelpMessage="Array with property names and values to change.  Multiple names/values are accepted as an array of arrays.")]
	[array]$items = @(@("IsDomainMaster",$false),@("MaintainServerList","No")),
	
	[parameter(Position=4,HelpMessage="File name for the log containing the post-change settings.")]
	[string]$postLog = "Set-Reg_post.csv",
	
	[parameter(Position=5,HelpMessage="File name for the log containing the pre-change settings.")]
	[string]$preLog = "Set-Reg_pre.csv"
)


BEGIN {

	#Concantenate all IP's on the given subnet.
	#Create a new PSSession to any computer that responds successfully.
	(1..255) | ? { Test-Connection ($subnet + "." + $_) -Count 1 -Quiet } | % { New-PSSession ($subnet + "." + $_) -OutVariable sessions } | Out-Null

	#The first object in each Array within the $itemss object is the registry items searched for.
	$keyNames = @( $items | % { $_[0] } )
	
	#PSComputerName is the Property from each session with the computer name.
	#Since we are connecting directly to the IP it will return the connected to IP address.
	$select = $keyNames + "PSComputerName"

	#ScriptBlock for checking registry settings.
	$checkReg = {
		param (
			[string]$root,
			[string]$key,
			[array]$items
		)
		Get-ItemProperty ($root + ":\" + $key) -Name $keyNames | % {
			$service = gwmi win32_service -filter "Name='browser'" -Property Name,StartMode,State
			Add-Member -Name Service -MemberType NoteProperty -Value $service.Name -InputObject $_ | Out-Null
			Add-Member -Name StartMode -MemberType NoteProperty -Value $service.StartMode -InputObject $_ | Out-Null
			Add-Member -Name State -MemberType NoteProperty -Value $service.State -InputObject $_ -PassThru
		}
	}
	
	#ScriptBlock for setting registry settings.
	$setReg = {
		param (
			[string]$root,
			[string]$key,
			[array]$items
		)
		#Because $items is an array of arrays $_ would return an array instead of the necessary strings.
		#Adding [0] returns the items name and [1] is the string that it needs to be set to.
		$items | % { Set-ItemProperty ($root + ":\" + $key) -Name $_[0] -Value $_[1] }
	}
}

PROCESS {
	#Gather existing settings.
	#Select does not pickup the PSSession information, so the ComputerIP has to be generated using a HashTable for the property.
	$check = Invoke-Command -session $sessions -ScriptBlock $checkReg -ArgumentList $root,$key,$items |
		Select @{Name="ComputerIP";Expression={$_.PSComputerName}},IsDomainMaster,MaintainServerList,Service,StartMode,State | 
		Export-Csv $preLog -NoTypeInformation
		
	#Changes registry values
	$set = Invoke-Command -Session $sessions -ScriptBlock $setReg -ArgumentList $root,$key,$items

	#Gather post change settings.
	#Select does not pickup the PSSession information, so the ComputerIP has to be generated using a HashTable for the property.
	$check = Invoke-Command -session $sessions -ScriptBlock $checkReg -ArgumentList $root,$key,$items |
		Select @{Name="ComputerIP";Expression={$_.PSComputerName}},IsDomainMaster,MaintainServerList,Service,StartMode,State | 
		Export-Csv $postLog -NoTypeInformation
}

END {
	
	#Remove any existing sessions created by this script.
	$sessions | Remove-PSSession
}