param (
	[string] $server, # single server to query
	[string] $file, # file to import other than list.txt
	[switch] $creds, # ask for credentials
	[switch] $csv, # export to csv instead of using excel api
	[switch] $all, # gather all info
	[switch] $disk, # gather disk info
	[switch] $hardware, # gather hardware info
	[switch] $network, # gather nic info
	[switch] $os, # gather os info
	[switch] $sl # server list output
)
################################################################################
# Gather all IP information for all active adapters on any workstation/server  #
#                                                                              #
# Created By:      Jes Brouillette                                             #
# Creation Date:   10/22/08                                                    #
# Updated:         10/6/09                                                     #
#                  Added switches for query optiosn directly from command line #
#                  Allowed passthrough credentials                             #
# Usage:           .\Get-MachineInfo.ps1 machinefilename                       #
# Requirements:    Powershell V2 (CTP), Excel 2000 or higher                   #
#                                                                              #
# http://support.microsoft.com/kb/968929                                       #
################################################################################

$erroractionpreference = "SilentlyContinue"

if (!$all -and !$disk -and !$hardware -and !$network -and !$os -and !$sl) {
   	$options = Read-Host -Prompt "Input information needed:`nO for OS Information`nN for Network Information.`nH for Hardware Information.`nD for Disk Information.`nA for All Information`nS for necessary Server List Information"
	if ($options -like "*a*") { $all = $true }
	if ($options -like "*d*") { $disk = $true }
	if ($options -like "*h*") { $hardware = $true }
	if ($options -like "*n*") { $network = $true }
	if ($options -like "*o*") { $os = $true }
}

$excel = New-Object -comobject Excel.Application
$excel.visible = $True 
    
$workBook = $excel.Workbooks.Add()
$workSheet = $workBook.Worksheets.Item(1)

$col = 1
$row = 1

if ($creds) { $cred = get-credential $Credentials }
if ($file) { $list = Get-Content $file }
elseif ($server) { $list = $server }
else { $list = Get-Content "list.txt" }
	
foreach($item in $list) {
	$workSheet.Cells.Item($col, $row) = "Gathering Information From " + $item.ToUpper()
	$col = $col + 1
	
	$ping = new-object System.Net.NetworkInformation.Ping
	$reply = $ping.send($item)

	if ($reply.status –eq "Success") {
		if ($os -or $all -or $sl) {
			$workSheet.Cells.Item($col, $row) = "Gathering OS Information"
			if ($cred) { $wmiOS = get-wmiobject -class "Win32_OperatingSystem" -namespace "root\cimv2" –credential $cred -computername $item }
			else { $wmiOS = get-wmiobject -class "Win32_OperatingSystem" -namespace "root\cimv2" -computername $item }
			$workSheet.Cells.Item($col, $row) = "OS Information Gathered"
			$col = $col + 1
		}
		if ($network -or $all -or $sl) {
			$workSheet.Cells.Item($col, $row) = "Gathering Network Information"
			if ($cred) { $wmiNetwork = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -namespace "root\cimv2" –credential $cred -computername $item }
			else { $wmiNetwork = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -namespace "root\cimv2" -computername $item }
			$workSheet.Cells.Item($col, $row) = "Network Information Gathered"
			$col = $col + 1
		}
		if ($hardware -or $all -or $sl) {
			$workSheet.Cells.Item($col, $row) = "Gathering System Information"
			if ($cred) { $wmiSystem = get-wmiobject -class "Win32_ComputerSystem" -namespace "root\cimv2" –credential $cred -computername $item }
			else { $wmiSystem = get-wmiobject -class "Win32_ComputerSystem" -namespace "root\cimv2" -computername $item }
			$workSheet.Cells.Item($col, $row) = "System Information Gathered"
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "Gathering Processor Information"
			if ($cred) { $wmiProcessor = get-wmiobject -class "Win32_Processor" -namespace "root\cimv2" –credential $cred -computername $item }
			else { $wmiProcessor = get-wmiobject -class "Win32_Processor" -namespace "root\cimv2" -computername $item }
			$workSheet.Cells.Item($col, $row) = "Processor Information Gathered"
			$col = $col + 1
		}
		if ($disk -or $all -or $sl) {
			$workSheet.Cells.Item($col, $row) = "Gathering Disk Information"
			if ($cred) { $wmiDisk = get-wmiobject -class "Win32_LogicalDisk" –credential $cred -computername $item -filter "drivetype=3" }
			else { $wmiDisk = get-wmiobject -class "Win32_LogicalDisk" -computername $item -filter "drivetype=3" }
			$workSheet.Cells.Item($col, $row) = "Disk Information Gathered"
			$col = $col + 1
		}
		
		$col = 1

		$workSheet.Cells.Item($col, $row) = $item.ToUpper()
		$col = $col + 1

		if ($os -or $all -or $sl) {
			$workSheet.Cells.Item($col, $row) = ""
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "OS Information"
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "------------------------------"
			$col = $col + 1
			[string]$NameA = $objItem.Name
			$NameB = $NameA.Split("`|")
			$Name = (([string]$wmiOS.Name).Split("`|"))[0] -replace "Microsoft ","" -replace " Edition","" -replace " x64",""
			$workSheet.Cells.Item($col, $row) = "Operating System:  " + $Name
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "Update Level:  " + $wmiOS.CSDVersion
			$col = $col + 1
			if ($NameB[0] -like "*64*") {
				$OSArchitecture = "64-Bit"
			}
			else {
				$OSArchitecture = "32-Bit"
			}
			$workSheet.Cells.Item($col, $row) = "Bit Level:  " + $OSArchitecture
			$col = $col + 1
			$objDate = [Management.ManagementDateTimeConverter]::toDateTime($wmiOS.InstallDate).toShortDateString()
			$workSheet.Cells.Item($col, $row) = "Date Imaged:  " + $objDate
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "Version:  " + $wmiOS.Version
			$col = $col + 1
		}
		if ($network -or $all -or $sl) {
			$workSheet.Cells.Item($col, $row) = ""
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "Network Information"
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "------------------------------"
			$col = $col + 1
			foreach ($nic in $wmiNetwork) {
				if ($nic.IPEnabled -eq $True) {
					$workSheet.Cells.Item($col, $row) = "Description:  " + $nic.Description 
					$col = $col + 1
					if ($objItem.MACAddress -ne $null) {
						$workSheet.Cells.Item($col, $row) = "MAC:  " + $nic.MACAddress
						$col = $col + 1
					}
  					$workSheet.Cells.Item($col, $row) = "Status:  Enabled"
					$col = $col + 1
					if ($nic.DHCPEnabled -eq $true) {
	  			 	 	$workSheet.Cells.Item($col, $row) = "DHCP:  Yes"
  						$col = $col + 1
					}
					else {
	  			  		$workSheet.Cells.Item($col, $row) = "DHCP:  No"
  						$col = $col + 1
					}
					if ($nic.IPAddress -ne $null) {
  						$workSheet.Cells.Item($col, $row) = "IP:  " + $nic.IPAddress
						$col = $col + 1
					}
					if ($nic.IPSubnet -ne $null) {
						$workSheet.Cells.Item($col, $row) = "Subnet:  " + $nic.IPSubnet
						$col = $col + 1
					}
					if ($nic.DefaultIPGateway -ne $null) {
						$workSheet.Cells.Item($col, $row) = "Primary Gateway:  " + $nic.DefaultIPGateway[0]
						$col = $col + 1
						if ($nic.DefaultIPGateway[1] -ne $null) {
							$workSheet.Cells.Item($col, $row) = "Second Gateway:  " + $nic.DefaultIPGateway[1]
							$col = $col + 1
						}
					}
					if ($nic.DNSServerSearchOrder -ne $null) {
						$workSheet.Cells.Item($col, $row) = "Primary DNS:  " + $nic.DNSServerSearchOrder[0]
  						$col = $col + 1
						if ($nic.DNSServerSearchOrder[1] -ne $null) {
							$workSheet.Cells.Item($col, $row) = "Second DNS:  " + $nic.DNSServerSearchOrder[1]
							$col = $col + 1
							if ($nic.DNSServerSearchOrder[2] -ne $null) {
								$workSheet.Cells.Item($col, $row) = "Third DNS:  " + $nic.DNSServerSearchOrder[2]
								$col = $col + 1
								if ($nic.DNSServerSearchOrder[3] -ne $null) {
									$workSheet.Cells.Item($col, $row) = "Fourth DNS:  " + $nic.DNSServerSearchOrder[3]
									$col = $col + 1
									if ($nic.DNSServerSearchOrder[4] -ne $null) {
										$workSheet.Cells.Item($col, $row) = "Fifth DNS:  " + $nic.DNSServerSearchOrder[4]
										$col = $col + 1
										if ($nic.DNSServerSearchOrder[5] -ne $null) {
											$workSheet.Cells.Item($col, $row) = "Sixth DNS:  " + $nic.DNSServerSearchOrder[5]
											$col = $col + 1
										}
									}
								}
							}
						}
					}
					if ($nic.WINSPrimaryServer -ne $null) {
	  					$workSheet.Cells.Item($col, $row) = "Pri WINS:  " + $nic.WINSPrimaryServer
						$col = $col + 1
					}
					if ($nic.WINSSecondaryServer -ne $null) {
						$workSheet.Cells.Item($col, $row) = "Sec WINS:  " + $nic.WINSSecondaryServer
						$col = $col + 1
					}
					$workSheet.Cells.Item($col, $row) = ""
					$col = $col + 1
				}
				elseif (!$sl) {
					$workSheet.Cells.Item($col, $row) = "Description:  " + $nic.Description 
					$col = $col + 1
					if ($nic.MACAddress -ne $null) {
						$workSheet.Cells.Item($col, $row) = "MAC:  " + $nic.MACAddress
						$col = $col + 1
					}
  					$workSheet.Cells.Item($col, $row) = "Status:  Disabled"
					$col = $col + 1
					$workSheet.Cells.Item($col, $row) = ""
					$col = $col + 1
				}
			}
		}
		if ($hardware -or $all -or $sl) {
			$workSheet.Cells.Item($col, $row) = "Hardware Information"
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "------------------------------"
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "Manufacturer:  " + $wmiSystem.Manufacturer
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "Model:  " + $wmiSystem.Model
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "Memory:  " + [math]::round($wmiSystem.TotalPhysicalMemory / 1gb,1) + "GB"
			$col = $col + 1
			if ($wmiProcessor[0].Manufacturer -ne $null) {
				$workSheet.Cells.Item($col, $row) = "Processor Manufacturer:  " + $wmiProcessor[0].Manufacturer
				$col = $col + 1
				$workSheet.Cells.Item($col, $row) = "Processor Speed:  " + [math]::round($wmiProcessor[0].MaxClockSpeed / 1024,2) + "GHz"
				$col = $col + 1
				$workSheet.Cells.Item($col, $row) = "Processor Type:  " + $wmiProcessor[0].Description
				$col = $col + 1
			}
			if ($wmiSystem.NumberofLogicalProcessors -ne $null) {
				$workSheet.Cells.Item($col, $row) = "Processors:  " + $wmiSystem.NumberOfProcessors
				$col = $col + 1
				$workSheet.Cells.Item($col, $row) = "Processor Cores:  " + $wmiSystem.NumberofLogicalProcessors
				$col = $col + 1
				if (($wmiSystem.NumberofLogicalProcessors / $wmiSystem.NumberOfProcessors) -eq "1") {
					$Core = "Single"
				}
				elseif (($wmiSystem.NumberofLogicalProcessors / $wmiSystem.NumberOfProcessors) -eq "2") {
					$Core = "Dual"
				}
				elseif (($wmiSystem.NumberofLogicalProcessors / $wmiSystem.NumberOfProcessors) -eq "4") {
					$Core = "Quad"
				}
				elseif (($wmiSystem.NumberofLogicalProcessors / $wmiSystem.NumberOfProcessors) -eq "8") {
					$Core = "Octa"
				}
				else {
					$Core = ($wmiSystem.NumberofLogicalProcessors / $wmiSystem.NumberOfProcessors) + " way"
				}
				$workSheet.Cells.Item($col, $row) = "Core Type:  " + $Core
				$col = $col + 1
			}
			else {
				$workSheet.Cells.Item($col, $row) = "Processor Cores:  " + $wmiSystem.NumberOfProcessors
				$col = $col + 1
			}
			$workSheet.Cells.Item($col, $row) = ""
			$col = $col + 1
		}
		if ($disk -or $all -or $sl) {
			$workSheet.Cells.Item($col, $row) = "Disk Information"
			$col = $col + 1
			$workSheet.Cells.Item($col, $row) = "------------------------------"
			$col = $col + 1

			foreach ($hdd in $wmiDisk) {
				$workSheet.Cells.Item($col, $row) = "Disk " + $hdd.Caption
				$col = $col + 1
				$workSheet.Cells.Item($col, $row) = "Size:  " + [Math]::round(($hdd.Size / 1GB),2) + " GB"
				$col = $col + 1
				if (!$sl) { 
					$workSheet.Cells.Item($col, $row) = "Used Space:  " + [Math]::round(($hdd.Size / 1GB) - ($hdd.FreeSpace / 1GB),2) + " GB"
					$col = $col + 1
					$workSheet.Cells.Item($col, $row) = "Free Space:  " + [Math]::round(($hdd.FreeSpace / 1GB),2) + " GB"
					$col = $col + 1
					$workSheet.Cells.Item($col, $row) = "Precent Free Space:  " + [Math]::Truncate((($hdd.FreeSpace / 1Gb)/($hdd.Size / 1GB)) * 100) + "%"
					$col = $col + 1
					$workSheet.Cells.Item($col, $row) = ""
					$col = $col + 1
				}
			}
		}

		$col = 1
		$row = $row + 1
	}
	else {
		$workSheet.Cells.Item($col, $row) = $item.ToUpper()
		$workSheet.Cells.Item($col, $row).Font.ColorIndex = 3
		$col = $col + 1
		$workSheet.Cells.Item($col, $row) = "No Response"
		$workSheet.Cells.Item($col, $row).Font.ColorIndex = 3
		$col = 1
		$row = $row + 1
	}
	$reply = ""
}
$usedRange = $workSheet.UsedRange
$e = $usedRange.EntireColumn.AutoFilter()
$f = $usedRange.EntireColumn.AutoFit()