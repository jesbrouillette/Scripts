<#
	.SYNOPSIS 
		Gathers system/user information from a computer.
	.DESCRIPTION
		Display-Info.ps1 gathers the memory amounts of all video cards present on a give computer.  This can be run against a remote computer or on the local session.
	.PARAMETER server
		Remote server to query.
	.INPUTS
		None. Piped objects are not accepted.
	.OUTPUTS
		Set-EnvVar_log.csv is created within the same directory as the script.
	.EXAMPLE
		C:\PS> .\Display-Info.ps1
		Displays a GUI box with requested information.
	.EXAMPLE
		C:\PS> .\Display-Info.ps1 -server CodeRed
		Displays a GUI box with requested information from the remove computer CodeRed.
	.NOTES
		Name:       Display-Info.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/11/2010 23:55 CST
		Purpose:  2010 Scripting Games: Advanced Event 7--Creating a Graphical Tool
#>

param (
	[string]$server = "."
)
BEGIN {	
	#Retrieve the members of local groups.
	function Check-GroupMembers {
		Param(
			[string]$group,
			[string]$server = "."
		)
		([ADSI]"WinNT://$server/$group").psbase.Invoke("Members") | % {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
	}
	[Void][reflection.assembly]::loadwithpartialname("System.Windows.Forms")
}
PROCESS {
	DO {
		#Gather data from several WMI Classes
		$computerSystem = gwmi win32_computersystem -ComputerName $server -Property Domain,Name,PartOfDomain,TotalPhysicalMemory
		$memory = gwmi Win32_PerfRawData_PerfOS_Memory -ComputerName $server -Property CommittedBytes,AvailableBytes
		$cpu = gwmi win32_processor -ComputerName $server -Property MaxClockSpeed,NumberOfCores,LoadPercentage
		$logon = gwmi Win32_NetworkLoginProfile -ComputerName $server Name,LastLogon,Caption | sort LastLogon -Descending | select -First 1 
		
		#Self explanitory section
		$user = $logon.Name
		$domain = $computerSystem.Domain
		$computer = $computerSystem.Name
		$domainConnected = $computerSystem.PartOfDomain
		$physicalMem = $computerSystem.TotalPhysicalMemory
		$committedMem = $memory.CommittedBytes
		$availableMem = $memory.AvailableBytes
		$cpuSpeed = $cpu.MaxClockSpeed
		$cpuCores = $cpu.NumberOfCores
		$cpuLoad = $cpu.LoadPercentage
		
		#Gets the members of local groups
		$administrators = Check-GroupMembers "Administrators" $server
		$powerUsers = Check-GroupMembers "Power Users" $server
		$users = Check-GroupMembers "Users" $server

		#Determines which local group the user is a member of
		if ($administrators -contains $logon.caption) { $group = "Administrators" }
		elseif ($powerUsers -contains $logon.caption) { $group = "Power Users" }
		else { $group = "Users" }
		
		#Date calculation for logon duration
		$now = Get-Date
		$logonTime = [DateTime]::ParseExact($logon.LastLogon.Split(".")[0],"yyyyMMddHHmmss",[System.Globalization.CultureInfo]::InvariantCulture)
		$loggedOn = $now - $logontime
		
		
		$Content = @"
User:  $user
Group Membership:  $group
Logon Duration:  $($loggedOn.Hours):$($loggedOn.Minutes):$($loggedOn.Seconds)
Since:  $logonTime

Computer Name:  $computer
Domain/Worksgroup:  $domain
Domain Member:  $domainConnected 

Physical Memory:  $([math]::round(($physicalMem/1gb),2))GB
Committed Memory:  $([math]::round(($committedMem/1gb),2))GB
Available Memory:  $([math]::round(($availableMem/1gb),2))GB

Processor Speed Mhz):  $([math]::round(($cpuSpeed/1024),2))Mhz
Processor Cores:  $cpuCores
CPU Load:  $($cpuLoad)`%

To refresh click "OK" or "Cancel" to exit
"@
		$popup = [system.Windows.Forms.MessageBox]::show($Content,"System Settings","OkCancel")
	}

	#Refresh if the user clicks "Ok".
	Until ($popup -eq "Cancel")
}
END { }