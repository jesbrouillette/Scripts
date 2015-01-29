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
# Creation Date: 08/22/08                                                      #
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

$SymProtectorAuto = New-Object -ComObject Symantec.ProtectorAuto

Write-Host "Started:" (Get-Date -Format "HH:mm:ss")

foreach($item in $list) {
	$msg = "Gathering information for: " + $item ; $msg
	$count +=1
	$item = $item.Replace(" ","")

	$reply = $ping.send($item)

	if ($reply.status –eq "Success") {
		$wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item | Where {$_.name -match "Symantec Backup" -or $_name -match "CommVault"}
		
		if ($wmiProduct) {
			#-----------------------------------
			#Backup Software Info
			#-----------------------------------
			
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
			
			if ($BESR -eq "Yes" -and !$SymProtectorAuto) {
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
					$testpath = $False
				}
				else { $bESR_Location = "unknown"	}
			}
			elseif ($BESR -eq "Yes" -and $SymProtectorAuto) {
				$SymProtectorAuto.Connect($item)
				foreach ($job in $SymProtectorAuto.ImageJobs) {
					$job.NextExpectedBackup
					$job.Volumes
					$job.Enabled
					$job.LastBackup
					$job.Task
			}
			else { $bESR_Location = "none" }
			
			#-----------------------------------
			#Write Data
			#-----------------------------------
			
			$row = "" | Select Server,Status,BESR,BackupLocation,LastBackup,BackupStatus
			$row.Server = $item.ToUpper()
			$row.Status = "Active"
			$row.BESR = $bESR
			$row.BackupLocation = $bESR_Location
			$row.LastBackup = $commVault
			$row.BackupStatus = $commVault
			$myObj += $row
			write-host $item "- Successful" -NoNewline
		}
		else {
			$row = "" | Select Server,Status,BESR,BackupLocation,LastBackup,BackupStatus
			$row.Server = $item
			$row.Status = "No Access"
			$myObj += $row
			write-host $item "- No Access" -NoNewline
		}
	}
	else {
		$row = "" | Select Server,Status,BESR,BackupLocation,LastBackup,BackupStatus
		$row.Server = $item
		$row.Status = "Timed Out"
		$myObj += $row
		write-host $item "- Timed Out" -NoNewline
	}
	if (($count % 15) -eq 0 -or $count -eq $list.Count -and $count -ne 0) { Write-Host " " $count "of" $list.Count " servers checked" }
	$reply = $null
}

if ($console) { $myObj | Format-List}
else { $myObj | Export-Csv $csv -NoTypeInformation }
Write-Host "Finished:" (Get-Date -Format "HH:mm:ss")