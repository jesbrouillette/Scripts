param (
	[string]$server, #single server to query
	[string]$list, #list of servers to query
	[switch]$console #output to console
)
#-------------------------------------------------------------------------------
# Purpose:  Query servers for their BESR storage location
# Created By:  Jes Brouillette
# Creation Date:  Oct 14, 2009
#---------------------------------------
# Usage:  .\Get-BESRStorage.ps1 (-list list.txt|-server servername|-console)
# Switches:  -list [file] - list of servers to query
#            -server      - single server to query
#            -conosole    - output to console instead of .csv
#   **   Using no switch will query the local server
#-------------------------------------------------------------------------------

$xml = New-Object xml
$csv = "Get-BESRStorage_" + (Get-Date -format "MM-dd-yy.HH.mm.ss") + ".csv"
$locations = @()

if ($list -ne "") { $servers = gc $list }
elseif ($server -ne $null) { $servers = $server }
else { $servers = "localhost" }

foreach ($server in $servers) {
	if ((test-path "\\$server\C$\ProgramData") -eq $true) {
			$startFolder = "\\$server\C$\ProgramData\Symantec\Backup Exec System Recovery\Schedule\"
	}
	elseif ((test-path "\\$server\C$\Documents and Settings\All Users.WINDOWS\Application Data\Symantec\Backup Exec System Recovery\Schedule") -eq $true) {
			$startFolder = "\\$server\C$\Documents and Settings\All Users.WINDOWS\Application Data\Symantec\Backup Exec System Recovery\Schedule\"
	}
	elseif ((Test-Path "\\$server\C$\Documents and Settings\All Users\Application Data\symantec\Backup Exec System Recovery\Schedule") -eq $true) {
		$startFolder = "\\$server\C$\Documents and Settings\All Users\Application Data\symantec\Backup Exec System Recovery\Schedule\"
	}
	else {
		$row = "" | Select Server,Path
		$row.Path = "unknown"
		$row.Server = $server
		$locations += $row
		break
	}
	$configs = gci $startFolder * | ? {$_.Name -like "*.pqj"} | % {$_.FullName}
	foreach ($config in $configs) {
		$row = "" | Select Server,Path
		$xml.Load($config)
		$row.Path = $xml.ImageJob.Location1.DisplayPath.InnerText
		$row.Server = $server
		$locations += $row
	}
}
	
if ($console) { $locations }

$locations | Export-Csv -Path $csv -NoTypeInformation