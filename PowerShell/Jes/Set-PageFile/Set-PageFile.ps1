# Set-PageFile.ps1
#
# Sets the Page File size based on Cargill standards as of 1/10/11
#
# All terminal servers get 2x the amount of physical ram allocated for the PageFile
# Non-terminal servers with less than 8G of physical ram get 1.5x the amount of physical ram allocated for the PageFile
# Non-terminal servers with more than 8G of physical ram get 1G more than the amount of physical ram allocated for the PageFile
#
# A reboot is required to apply the changes after the script is completed.
#
# By:  Jes Brouillette
# Created:  1/10/11
# Updates:  None

# Check for TS
switch ((gwmi win32_TerminalServiceSetting).TerminalServerMode) {
	0 { $citrix = $true }
	1 { $citrix = $false }
}

$pagefile = gwmi Win32_PageFileSetting -ComputerName $item

$ram = gwmi Win32_OperatingSystem -ComputerName $item | select TotalVisibleMemorySize
$ram = ($ram.TotalVisibleMemorySize/1kb).tostring()

# All terminal servers get 2x the amount of physical ram allocated for the PageFile
if ($citrix) { $pfsize = $ram * 2 }

else {
	# Non-terminal servers with less than 8G of physical ram get 1.5x the amount of physical ram allocated for the PageFile
	if ($ram -lt 8388608) { $pfsize = $ram * 1.5 }
	# Non-terminal servers with more than 8G of physical ram get 1G more than the amount of physical ram allocated for the PageFile
	else { $pfsize = $ram + 1048576 }
}
		
$pagefile.InitialSize = $pfsize
$pagefile.MaximumSize = $pfsize
$pagefile.Put()