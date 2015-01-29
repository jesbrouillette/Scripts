###############################################################################
# Gather all IP information for all active adapters on any workstation/server #
#                                                                             #
# Created By:      Jes Brouillette                                            #
# Creation Date:   10/22/08                                                   #
# Updated:         n/a                                                        #
# Usage:           .\GetMachineInfo.ps1 machinefilename domain\username       #
# Requirements:    Powershell V2 (CTP), Excel 2000 or higher                  #
#                                                                             #
# http://www.microsoft.com/downloads/details.aspx?familyid=7C8051C2-9BFC-4C81-859D-0864979FA403&displaylang=en#filelist #
###############################################################################

#$erroractionpreference = "SilentlyContinue"

$TextFileLocation = read-host "Input the file with the list of servers to check"
$Credentials = Read-Host "Input the username with admin access to the server"

#	verifies input
$strInFile = Get-Content $textFileLocation
$cred = get-credential $Credentials
foreach ($strServer in $strInFile)
{
	$objOSInfo = Get-WmiObject -class Win32_OperatingSystem -computer $strServer -Credential $cred
	$objBootTime = $objOSInfo.ConvertToDateTime($objOSInfo.Lastbootuptime)
	[TimeSpan]$objUpTime = New-TimeSpan $objBootTime $(get-date)
	write-host $strServer "has been up for:" $objUpTime.days "Days" $objUpTime.hours "Hours" $objUpTime.minutes "Minutes" $objUpTime.seconds "Seconds"
	Remove-Variable objUpTime
}
