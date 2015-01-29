param (
	[string] $file, #fiie to import other than list.txt
	[string] $server, #queries a single server
	[switch] $help, #displays console help message
	[switch] $console, #output to console.  do not use with -csv
	[switch] $quiet #run silently
)
################################################################################
#                                  ##########                                  #
#                                                                              #
# Gather most necessary network information the DCN project move group sheets  #
#                                                                              #
# Created By: Jes Brouillette                                                  #
# Creation Date: 08/22/09                                                      #
# Updates: 12/01/09                                                            #
#          - Added drive letters and total disk space for physical drives      #
#                                                                              #
# Usage: .\Get_DCNInfo.ps1 [options]                                           #
#                                                                              #
# Switches:                                                                    #
#          -file File.txt  - specify an input file other than list.txt         #
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

$errorActionPreference = "SilentlyContinue"

$ping = New-Object System.Net.NetworkInformation.Ping	
$xml = New-Object XML
$myObj = @()

$count = 0

$csv = "Get-DCNInfo_" + (Get-Date -format "MM-dd-yy.HH.mm.ss") + ".csv"

if ($file -ne "" -and !$server) { $list = Get-Content $file }
elseif ($server) { $list = $server.Split(" ") }
else { $list = Get-Content "list.txt" }

$list = $list | sort -Unique
if ($list.Count) { $total = $list.Count }
else { $total = "1" }

Write-Host "Started:" (Get-Date -Format "HH:mm:ss")

foreach($item in $list) {
	$msg = "Gathering information for: " + $item ; $msg
	$count +=1
	$item = $item.Replace(" ","")
	$reply = $ping.send($item)

	if ($reply.status –eq "Success") {
		
		#-----------------------------------
		#Network Info
		#-----------------------------------
		
		$nics = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -namespace "root\cimv2" -computername $item | Where { $_.IpEnabled -Match "True" -and $_.IPAddress -ne "0.0.0.0" }
		
		if ($nics) {
			$diskspace = 0
			$logicaldisk = gwmi -class Win32_LogicalDisk -ComputerName $item -Filter "DriveType=3"
			$deviceids = $logicaldisk | % { $_.DeviceID + "\" ; $diskspace += $_.Size }
			$drives = [string]::join(";",$deviceids)
			$diskspace = ([math]::round(($diskspace / 1gb),2)).ToString() + " GB"
			$links = get-wmiobject -class "MSNdis_LinkSpeed" -namespace "root\WMI" -computername $item | Where { $_.Active -Match "True" }
			$devices = Get-WmiObject -Class Win32_PnPEntity -Namespace "root\cimv2" -ComputerName $item | Where { $_.Manufacturer -eq "QLogic" -or $_.Manufacturer -match "Emulex" }
			
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
				foreach ($subKeyName in $subKeyNames) {
					$subKey = $baseKey.OpenSubKey("$subKeyName")
					$ID = $subKey.GetValue("NetCfgInstanceId")
					if ($ID -eq $nic.SettingId)	{
						$componentID = $subKey.GetValue("ComponentID")
						$driverDesc = $subKey.GetValue("DriverDesc")
						if ($componentID -match "ven_14e4") {
							$SD = $subKey.GetValue("RequestedMediaType")
							$enum = $subKey.OpenSubKey("Ndi\Params\RequestedMediaType\Enum")
							$sdValue = $enum.GetValue("$SD")
						} elseif ($componentID -match "ven_1022") {
							$SD = $subKey.GetValue("EXTPHY")
							$enum = $subKey.OpenSubKey("Ndi\Params\EXTPHY\Enum")
							$sdValue = $enum.GetValue("$SD")
						} elseif ($componentID -match "ven_8086") {
							$SD = $subKey.GetValue("SpeedDuplex")
							$enum = $subKey.OpenSubKey("Ndi\savedParams\SpeedDuplex\Enum")
							$enum1 = $subKey.OpenSubKey("Ndi\Params\SpeedDuplex\Enum")
							if ($enum) { $sdValue = $enum.GetValue("$SD") }
							elseif ($enum1) { $sdValue = $enum1.GetValue("$SD") }
						} elseif ($componentID -match "b06bdrv") {
							$specialSD = @"
*SpeedDuplex
"@
							if ($subKey.GetValue($specialSD)) { $SD = $subKey.GetValue($specialSD) }
							else { $SD = $subKey.GetValue("req_medium") }
							$enum = $subKey.OpenSubKey("Ndi\Params\req_medium\Enum")
							$enum1 = $subKey.OpenSubKey("BRCMndi\params\req_medium\Enum")
							$enum2 = $subKey.OpenSubKey("BRCMndi\params\$specialSD\Enum")
							if ($enum) { $sdValue = $enum.GetValue("$SD") }
							elseif ($enum1) { $sdValue = $enum1.GetValue("$SD") }
							elseif ($enum2) { $sdValue = $enum2.GetValue("$SD") }
						} elseif ($driverDesc -match "VMWare") {
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
	
				if ($nic.Description -notmatch "VMWare" -or $nic.Description -notmatch "AMD PCNET") {
					$drac = get-wmiobject -class "Dell_RemoteAccessServicePort" -namespace "root\cimv2\Dell" -computername $item
					if ($drac.AccessInfo -eq "0.0.0.0") {
						$chassis = get-wmiobject -class "DELL_Chassis" -namespace "root\cimv2\Dell" -computername $item
						if ($chassis.ChassisTypes -eq 25)  { $dracIP = "Blade" }
						else { $dracIP = "Not Configured" }
					} else { $dracIP = $drac.AccessInfo }
				} else { $dracIP = "No DRAC" }
				
				if ($devices) {
					$hbas = @()
					foreach ($device in $devices) { $hbas += $device.Manufacturer }
					$hba = $hbas | Sort-Object -Unique
				} else { $hba = "none" }
				
				#-----------------------------------
				#Backup Software Info
				#-----------------------------------
				
				$wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item | Where {$_.name -match "Symantec Backup" -or $_name -match "CommVault"}
				foreach ($wmiApp in $wmiProduct) {
					if ($wmiApp.name -match "Symantec Backup") { $BESR = "Yes" ; break}
					else { $BESR = "No" }
				}
				foreach ($wmiApp in $wmiProduct) {
					if ($wmiApp.name -match "CommVault") { $CommVault = "Yes" ; break}
					else { $CommVault = "No" }
				}
				
				#-----------------------------------
				#BESR Storage Info
				#-----------------------------------
				
				$bESR_Drives = ""

				if ($BESR -eq "Yes") {
					if ((test-path "\\$item\C$\ProgramData") -eq $true) {
							$startFolder = "\\$item\C$\ProgramData\Symantec\Backup Exec System Recovery\Schedule\"
							$testpath = $True
					}
					elseif ((test-path "\\$item\C$\Documents and Settings\All Users.WINDOWS\Application Data\Symantec\Backup Exec System Recovery\Schedule") -eq $true) {
							$startFolder = "\\$item\C$\Documents and Settings\All Users.WINDOWS\Application Data\Symantec\Backup Exec System Recovery\Schedule\"
							$testpath = $True
					}
					elseif ((Test-Path "\\$item\C$\Documents and Settings\All Users\Application Data\symantec\Backup Exec System Recovery\Schedule") -eq $true) {
						$startFolder = "\\$item\C$\Documents and Settings\All Users\Application Data\symantec\Backup Exec System Recovery\Schedule\"
							$testpath = $True
					}
					if ($testpath -eq $True) {
						$config = Get-ChildItem $startFolder * | ? {$_.Name -like "*.pqj"} | Sort-Object LastWriteTime -descending | % {$_.FullName}
						if ($config.Count) { $xml.Load($config[0]) }
						else { $xml.Load($config) }
						$bESR_Location = $xml.ImageJob.Location1.DisplayPath.Get_InnerText()
						$bESR_Drives = $xml.imagejob | Get-Member | ? { $_.Name -match "volume" } | % { $_.Name } | % { $xml.imagejob.$_.Get_InnerText() }
						$testpath = $False
					}
					else { $bESR_Location = "unknown" }
				}
				else { $bESR_Location = "" }
				
				#-----------------------------------
				#Write Data
				#-----------------------------------
				
				$row = "" | Select Server,Status,Drives,DiskSpace,NIC,MAC,DHCP,IP,Subnet,PriGtwy,SecGtwy,PriDNS,SecDNS,OtherDNS,PriWINS,SecWINS,Speed,Duplex,ConnectedSpeed,DRACIP,HBA,BESR,BESR_Location,BESR_Drives,CommVault
				$row.Server = $nic.DNSHostName
				$row.Status = "Active"
				$row.Drives = $drives
				$row.DiskSpace = $diskspace
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
				$row.HBA = $hba.ToString()
				$row.BESR = $bESR
				$row.BESR_Location = $bESR_Location
				$row.BESR_Drives = [string]::join(";",$bESR_Drives)
				$row.CommVault = $commVault
				$myObj += $row
			}
			write-host $item "- Successful" -NoNewline
		}
		else {
			$row = "" | Select Server,Status,Drives,DiskSpace,NIC,MAC,DHCP,IP,Subnet,PriGtwy,SecGtwy,PriDNS,SecDNS,OtherDNS,PriWINS,SecWINS,Speed,Duplex,ConnectedSpeed,DRACIP,HBA,BESR,BESR_Location,BESR_Drives,CommVault
			$row.Server = $item
			$row.NIC = "No Access"
			$myObj += $row
			write-host $item "- No Access" -NoNewline
		}
	}
	else {
		$row = "" | Select Server,Status,Drives,DiskSpace,NIC,MAC,DHCP,IP,Subnet,PriGtwy,SecGtwy,PriDNS,SecDNS,OtherDNS,PriWINS,SecWINS,Speed,Duplex,ConnectedSpeed,DRACIP,HBA,BESR,BESR_Location,BESR_Drives,CommVault
		$row.Server = $item
		$row.NIC = "Timed Out"
		$myObj += $row
		write-host $item "- Timed Out" -NoNewline
	}
	if (($count % 15) -eq 0 -or $count -eq $list.Count -and $count -ne 0) { Write-Host " " $count "of" $list.Count " servers checked" }
	$nics = $null
	$reply = $null
}

if ($console) { $myObj | Format-List}
else { $myObj | Export-Csv $csv -NoTypeInformation }
Write-Host "Finished:" (Get-Date -Format "HH:mm:ss")