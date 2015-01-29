param (
	[string] $file, #fiie to import other than list.txt
	[string] $server, #queries a single server
	[switch] $help, #displays console help message
	[switch] $cred, #specify credentials
	[switch] $csv, #output to csv.  do not use with -console
	[switch] $console, #output to console.  do not use with -csv
	[switch] $quiet #run silently
)
################################################################################
#                                  ##########                                  #
#                                                                              #
# Gather most necessary network information the DCN project move group sheets  #
#                                                                              #
# Created By: Jes Brouillette                                                  #
# Creation Date: 08/22/08                                                      #
#                                                                              #
# Updated: 08/13/09                                                            #
#          Removed dependencies on PS2.0                                       #
#          Removed required credentials                                        #
#          Removed input for the list                                          #
#          Added switch for credentials                                        #
#          Added switch for input file                                         #
#                                                                              #
# Updated: 08/23/09                                                            #
#          Added switch for single server                                      #
#          Added switch for console output                                     #
#          Added switch for csv file output                                    #
#          Added switch for help                                               #
#          Added DRAC IP                                                       #
#          Added Speed & Duplex                                                #
#          Added all IP's & SubNets for NICs with multiple IP's set            #
#                                                                              #
# Updated: 08/27/09                                                            #
#          Added HBA query for Qlogic and Emulex fiber SCSI cards              #
#                                                                              #
# Updated: 09/01/09                                                            #
#          Added No Access if the account does not have access to gather info  #
#                                                                              #
# Usage: .\GetNetInfo.ps1 [options]                                            #
#                                                                              #
# Switches:                                                                    #
#          -file File.txt  - specify an input file other than list.txt         #
#          -cred           - prompts for credentials                           #
#          -server         - queries a single server                           #
#          -csv            - output to csv.  do not use with -console          #
#          -console        - output to console.  do not use with -csv          #
#          -help           - shows help                                        #
#          -quiet          - run silently                                      #
#                                                                              #
# NOTE:    This must be run under an account with Admin access to the servers  #
#          you are gathering information from.                                 #
#                                                                              #
#                                  ##########                                  #
################################################################################

$erroractionpreference = "SilentlyContinue"

if ($help) {
	 Sort st "
Gather most necessary network information the DCN project move group sheets
	
Usage: .\GetNetInfo.ps1 [options]
	
Switches:
	-file File.txt  - specify an input file other than list.txt
	-cred           - prompts for credentials
	-server         - queries a single server
	-csv            - output to csv.  do not use with -console
	-console        - output to console.  do not use with -csv
	-help           - shows this message
	-quiet          - run silently
	"
	exit
}

Write-Host "Started:" (Get-Date -Format HH:mm:ss)

if ($file -ne "" -and !$server) { $list = Get-Content $file }
elseif ($server) { $list = $server.Split(" ") }
else { $list = Get-Content "list.txt" }

if ($env:COMPUTERNAME -notmatch "admpls200m" -and !$console ) { $csv = $true ; $quiet = $true }

$ping = New-Object System.Net.NetworkInformation.Ping	

if ($csv -or $console) {
	$outfile = "Get-NetInfo_" + (Get-Date -format "MM-dd-yy.HH.mm.ss") + ".csv"
	$myObj = @()
} else {
	$excel = New-Object -comobject Excel.Application
	$excel.visible = $True 
	$workbook = $excel.Workbooks.Add()
	$worksheet = $workbook.Worksheets.Item(1)
	
	$iRow = 1
	$iCol = 1
	
	$worksheet.Cells.Item($iCol, $iRow) = "Server"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "NIC"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "MAC"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "DHCP"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "IP"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Subnet"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Primary Gateway"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Secondary Gateway"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Primary DNS"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Secondary DNS"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Additional DNS"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Primary WINS"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Secondary WINS"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Speed"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Duplex"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "Connected Speed"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "DRAC IP"
	$iRow = $iRow + 1
	$worksheet.Cells.Item($iCol, $iRow) = "HBA"
	$iRow = 1
	$iCol = $iCol + 1
}
$list = $list | sort -Unique
if ($list.Count) { $total = $list.Count }
else { $total = "1" }

$count = 0
foreach($item in $list) {
	$count +=1
	$item = $item.Replace(" ","")
	if ($quiet) { $msg = "Gathering information for: " + $item ; $msg}
	
	# pings the servers to see if they are online
	$reply = $ping.send($item)

	if ($reply.status –eq "Success") {
		# gathers all nic information for each nic in each server
		if ($cred) { $creds = Get-Credential }
		if ($cred) { $nics = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -namespace "root\cimv2" -credential $creds -computername $item | Where{$_.IpEnabled -Match "True"} }
		else { $nics = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -namespace "root\cimv2" -computername $item | Where{$_.IpEnabled -Match "True"} }
		
		if ($nics) {
			if ($cred) { $links = get-wmiobject -class "MSNdis_LinkSpeed" -namespace "root\WMI" -credential $creds -computername $item | Where{$_.Active -Match "True"} }
			else { $links = get-wmiobject -class "MSNdis_LinkSpeed" -namespace "root\WMI" -computername $item | Where{$_.Active -Match "True"} }
			if ($cred) { $devices = Get-WmiObject -Class Win32_PnPEntity -Namespace "root\cimv2" -Credential $creds -ComputerName $item | Where {$_.Manufacturer -eq "QLogic" -or $_.Manufacturer -match "Emulex" } }
			else { $devices = Get-WmiObject -Class Win32_PnPEntity -Namespace "root\cimv2" -ComputerName $item | Where {$_.Manufacturer -eq "QLogic" -or $_.Manufacturer -match "Emulex" } }
			
			foreach ($nic in $nics) {
				if ($nic.DHCPEnabled -eq "TRUE") {
					$dhcp = "Enabled"
				} else {
					$dhcp = "Disabled"
				}
				if ($nic.IPAddress.Count -gt 1) {
					$ipCount = 0
					foreach ($address in $nic.IPAddress) {
						if ($ipCount -eq 0) { $ip = $address }
						else { $ip = $ip + "`/" + $address }
						$ipCount += 1
					}
				}
				else { [string]$ip = $nic.IPAddress }
				if ($nic.IPSubnet.Count -gt 1) {
					$ipCount = 0
					foreach ($address in $nic.IPSubnet) {
						if ($ipCount -eq 0) { $subnet = $address }
						else { $subnet = $subnet + "`/" + $address }
						$ipCount += 1
					}
				}
				else { [string]$subnet = $nic.IPSubnet }
				
				$registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $item)
				$baseKey = $registry.OpenSubKey("SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}")
				$subKeyNames = $baseKey.GetSubKeyNames()
				$sdValue = ""
				ForEach ($subKeyName in $subKeyNames) {
					$subKey = $baseKey.OpenSubKey("$subKeyName")
					$ID = $subKey.GetValue("NetCfgInstanceId")
					If ($ID -eq $nic.SettingId)	{
						$componentID = $subKey.GetValue("ComponentID")
						$driverDesc = $subKey.GetValue("DriverDesc")
						If ($componentID -match "ven_14e4") {
							$SD = $subKey.GetValue("RequestedMediaType")
							$enum = $subKey.OpenSubKey("Ndi\Params\RequestedMediaType\Enum")
							$sdValue = $enum.GetValue("$SD")
						} ElseIf ($componentID -match "ven_1022") {
							$SD = $subKey.GetValue("EXTPHY")
							$enum = $subKey.OpenSubKey("Ndi\Params\EXTPHY\Enum")
							$sdValue = $enum.GetValue("$SD")
						} ElseIf ($componentID -match "ven_8086") {
							$SD = $subKey.GetValue("SpeedDuplex")
							$enum = $subKey.OpenSubKey("Ndi\savedParams\SpeedDuplex\Enum")
							$enum1 = $subKey.OpenSubKey("Ndi\Params\SpeedDuplex\Enum")
							if ($enum) { $sdValue = $enum.GetValue("$SD") }
							elseif ($enum1) { $sdValue = $enum1.GetValue("$SD") }
						} ElseIf ($componentID -match "b06bdrv") {
							$SD = $subKey.GetValue("req_medium")
							$enum = $subKey.OpenSubKey("Ndi\Params\req_medium\Enum")
							$enum1 = $subKey.OpenSubKey("BRCMndi\params\req_medium\Enum")
							if ($enum) { $sdValue = $enum.GetValue("$SD") }
							elseif ($enum1) { $sdValue = $enum1.GetValue("$SD") }
						} ElseIf ($driverDesc -match "VMWare") {
							$SD = $subKey.GetValue("EXTPHY")
							$enum = $subKey.OpenSubKey("Ndi\Params\EXTPHY\Enum")
							$sdValue = $enum.GetValue("$SD")
						} Else { $sdValue = "unknown" }
						if ($sdValue -eq "Hardware Default") {
							$speed = $sdValue
							$duplex = $sdValue
						} elseif ($sdValue -eq "") {
							$speed = "unknown"
							$duplex = "unknown"
						} else {
							$sdSplit = $sdValue.Split("`/")
							$sdSplit1 = $sdValue.Split(" ")
							if ($sdSplit.Count -gt 1) {
								$speed = $sdSplit[0]
								$duplex = $sdSplit[1]
							} elseif ($sdSplit.Count -gt 1 -and $sdSplit -notcontains "auto") {
								$speed = $sdSplit[0]
								$duplex = $sdSplit[1]
							} elseif ($sdSplit1.Count -gt 1 -and $sdSplit1[2]) {
								$speed = $sdSplit1[0] + " " + $sdSplit1[1]
								$duplex = $sdSplit1[2] + $sdSplit1[3]
							} else {
								$speed = $sdValue
								$duplex = $sdValue
							}
						}
					}
				}
				$nicDesc = ((($nic.Description).Replace("`(","")).Replace("`)","")).Replace("`/","")
				foreach ($link in $links) {
					$linkInst = ((($link.InstanceName).Replace("`(","")).Replace("`)","")).Replace("`/","")
					if ($linkInst -match $nicDesc) {
						$connectedSpeed = $link.NdisLinkSpeed
						if ($connectedSpeed -eq 10000000) { $connectedSpeed = "1Gbps" }
						elseif ($connectedSpeed -eq 1000000) { $connectedSpeed = "100Mbps" }
						else { $connectedSpeed = "uncommon" }
						$found = $TRUE
					} elseif ($found) {  }
					else {$connectedSpeed = "unknown" }
				}
				$found = $FALSE
	
				if ($nic.Description -notmatch "VMWare") {
					if ($cred) { $drac = get-wmiobject -class "Dell_RemoteAccessServicePort" -namespace "root\cimv2\Dell" -credential $creds -computername $item }
					else { $drac = get-wmiobject -class "Dell_RemoteAccessServicePort" -namespace "root\cimv2\Dell" -computername $item }
					if ($drac.AccessInfo -eq "0.0.0.0") {
						if ($cred) { $chassis = get-wmiobject -class "DELL_Chassis" -namespace "root\cimv2\Dell" -credential $creds -computername $item }
						else { $chassis = get-wmiobject -class "DELL_Chassis" -namespace "root\cimv2\Dell" -computername $item }
						if ($chassis.ChassisTypes -eq 25)  { $dracIP = "Blade" }
						else { $dracIP = "Not Configured" }
					} else { $dracIP = $drac.AccessInfo }
				}
				
				if ($devices) {
					$hbas = @()
					foreach ($device in $devices) {
						$deviceRow = $device.Manufacturer
						$hbas += $deviceRow
					}
					$hba = $hbas | Sort-Object -Unique
				} else { $hba = "" }
				if ($csv -or $console) {
					$row = "" | Select Server,NIC,MAC,DHCP,IP,Subnet,PriGtwy,SecGtwy,PriDNS,SecDNS,OtherDNS,PriWINS,SecWINS,Speed,Duplex,ConnectedSpeed,DRACIP,HBA
					$row.Server = $nic.DNSHostName
					$row.NIC = $nic.Description
					$row.MAC = $nic.MACAddress
					$row.DHCP = $nic.DHCPEnabled
					$row.IP = $ip
					$row.Subnet = $subnet
					$row.PriGtwy = $nic.DefaultIPGateway[0]
					$row.SecGtwy = $nic.DefaultIPGateway[1]
					$row.PriDNS = $nic.DNSServerSearchOrder[0]
					$row.SecDNS = $nic.DNSServerSearchOrder[1]
					$row.OtherDNS = $nic.DNSServerSearchOrder[2]
					$row.PriWINS = $nic.WINSPrimaryServer
					$row.SecWINS = $nic.WINSSecondaryServer
					$row.Speed = $speed
					$row.Duplex = $duplex
					$row.ConnectedSpeed = $connectedSpeed
					$row.DRACIP = $dracIP
					$row.HBA = $hba
					$myObj += $row
				} else {
					# inputs results into excel
					$worksheet.Cells.Item($iCol, $iRow) = $nic.DNSHostName
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.Description 
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.MACAddress
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.DHCPEnabled
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $ip
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $subnet
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.DefaultIPGateway[0]
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.DefaultIPGateway[1]
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.DNSServerSearchOrder[0]
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.DNSServerSearchOrder[1]
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.DNSServerSearchOrder[2]
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.WINSPrimaryServer
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $nic.WINSSecondaryServer
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $speed
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $duplex
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $connectedSpeed
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $dracIP
					$iRow = $iRow + 1
					$worksheet.Cells.Item($iCol, $iRow) = $hba
					$iRow = 1
					$iCol = $iCol + 1
				}
			}
		} elseif ($csv -or $console) {
			$row = "" | Select Server,NIC,MAC,DHCP,IP,Subnet,PriGtwy,SecGtwy,PriDNS,SecDNS,OtherDNS,PriWINS,SecWINS,Speed,Duplex,ConnectedSpeed,DRACIP,HBA
			$row.Server = $item
			$row.NIC = "No Access"
			$myObj += $row
			if (!$quiet) { $msg = $item +  " - No Access" ; Write-Host $msg -NoNewline }
		} else {
			$worksheet.Cells.Item($iCol, $iRow) = $item
			$worksheet.Cells.Item($iCol, $iRow).Font.ColorIndex = 3
			$iRow = $iRow + 1
			$worksheet.Cells.Item($iCol, $iRow) = "No Access"
			$worksheet.Cells.Item($iCol, $iRow).Font.ColorIndex = 3
			$iRow = 1
			$iCol = $iCol + 1
			 Sort st " - No Access" -NoNewline
		}
	} else {
		if ($csv -or $console) {
			$row = "" | Select Server,NIC,MAC,DHCP,IP,Subnet,PriGtwy,SecGtwy,PriDNS,SecDNS,OtherDNS,PriWINS,SecWINS,Speed,Duplex,ConnectedSpeed,DRACIP,HBA
			$row.Server = $item
			$row.NIC = "Timed Out"
			$myObj += $row
		} else {
			$worksheet.Cells.Item($iCol, $iRow) = $item
			$worksheet.Cells.Item($iCol, $iRow).Font.ColorIndex = 3
			$iRow = $iRow + 1
			$worksheet.Cells.Item($iCol, $iRow) = "Timed Out"
			$worksheet.Cells.Item($iCol, $iRow).Font.ColorIndex = 3
			$iRow = 1
			$iCol = $iCol + 1
		}
		if (!$quiet) { $msg = $item +  " - Timed Out" ; Write-Host $msg -NoNewline }
	}
	$nics = $null
	$reply = $null

	if (($count % 15) -eq 0 -or $count -eq $list.Count -and $count -ne 0 -and !$quiet) {
		Write-Host " " $count "of" $list.Count " servers checked"
	}

}

if ($csv) {
	$myObj | Select Server,NIC,MAC,DHCP,IP,Subnet,PriGtwy,SecGtwy,PriDNS,SecDNS,OtherDNS,PriWINS,SecWINS,Speed,Duplex,ConnectedSpeed,DRACIP,HBA | Export-Csv $outfile -NoTypeInformation -Force
} elseif ($console) {
	$myObj | Select Server,NIC,MAC,DHCP,IP,Subnet,PriGtwy,SecGtwy,PriDNS,SecDNS,OtherDNS,PriWINS,SecWINS,Speed,Duplex,ConnectedSpeed,DRACIP,HBA | Format-List
} else {
	$excelRange = $worksheet.UsedRange
	$filter = $excelRange.EntireColumn.AutoFilter()
	$fit = $excelRange.EntireColumn.AutoFit()
}

if (!$quiet) { $msg =  "Finished:" (Get-Date -Format HH:mm:ss) ; $msg }