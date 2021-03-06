#Powershell script by Jarrett Long
#This script echo's the winstation client ip for current session, parses it by class c subnet and connects a printer at .244
#Modified by Steve Morris on 06/05/2012 to include conditional check for Print Server Name based on Quartiles of Octet 3 in Store IP Address

$TSClientIP			= Get-TSCurrentSession | Select -Expand ClientIPAddress | Select -Expand IPAddressToString
$TSClientIPArray	= $TSClientIP.Split(".")

$AWSZone	= Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone -UseBasicParsing | Select -Expand Content

Switch ($AWSZone) {
	"us-east-1b"	{ $First	= "8" }
	"us-east-1d"	{ $First	= "20" }
	default			{ Write-Host "No valid AWS Availability zone found.  Must be in us-east-1b or us-east-1d." ; Exit }
}

Switch -regex ($TSClientIPArray[2]) {
	"[0-127]"	{ $Last	= "6" }
	"[128-254]"	{ $Last	= "7" }
}

#New Print Server names for each Quartile of Octet 3 (Class C) to spread
#out store printer distribution.
$PrintArrayIP	= "10.62.1.{0}{1}" -f $First,$Last
$PrinterIP		= "{0}.{1}.{2}.244" -f $TSClientIPArray[0],$TSClientIPArray[1],$TSClientIPArray[2]

$CompSys	= Get-WmiObject -Query "SELECT Name,Domain FROM Win32_ComputerSystem" -ComputerName $PrintArrayIP

$PrintServerName	= $CompSys.Name
$PrintServerDomain	= $CompSys.Domain
$PrintServerFQDN	= "{0}.{1}" -f $PrintServerName,$PrintServerDomain

$PrinterFQDN	= "\\{0}\{1}" -f $PrintServerFQDN,$PrinterIP

$WSNet	= New-Object -com WScript.Network
$WSNet.AddWindowsPrinterConnection($PrinterFQDN)