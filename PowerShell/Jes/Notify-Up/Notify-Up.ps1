################################################################################
#                                                                              #
# Purpose of this script:  Notification of a computer coming back online       #
#                                                                              #
# Execution:                                                                   #
#     Utilize PING to gather network availabilty of a machine                  #
#                                                                              #
# Usage:                                                                       #
#     .\notifyup.ps1 %MACHINENAME%                                             #
#                                                                              #
# Example:                                                                     #
#     .\notifyup.ps1 admpls112m                                                #
#                                                                              #
################################################################################

$strSrvr = $args[0]
$cred = Get-Credential

$replyTmpFile = $Env:TEMP + "\replystatus.txt"
$test = Test-Path $replyTmpFile
if ($test -eq "True") {Remove-Item -Path $replyTmpFile  -Force}

$test = Test-Path "C:\Program Files\Windows NT\Accessories\wordpad.exe"
if ($test -eq "True") {$openReplyPad = "C:\Program Files\Windows NT\Accessories\wordpad.exe"}
else {$openReplyPad = notepad.exe}

$startTime = get-date -format g

$ping = new-object System.Net.NetworkInformation.Ping

$Reply = "DestinationHostUnreachable"
$strReplyStatus = "Pinging " + $strSrvr + "`n `n Started: " + $startTime + "`n"
$repeat = 0

do {
	$Reply = $ping.send($strSrvr)
	$now = Get-Date -Format "h:mm:ss tt"
	$strReplyStatus = $strReplyStatus + "`n Response: " + $Reply.Status + " " + $now
	$repeat = $repeat + 1
	if ($Reply.Status -eq "Success") {}
	else {
		$dnsFlush = cmd /c ipconfig /flushdns >c:\windows\temp\flush.txt
		$dnsFlush
		Start-Sleep –s 10
		}
	}
Until ($Reply.Status -eq "Success")

$address = $Reply.Address
$endTime = get-date -format g
$srtSrvrUp = $strSrvr.ToUpper()
$strReplyStatus = $strReplyStatus + "`n `n Finished: " + $endTime + "`n `n Ping attempts: " + $repeat

Do 
{
	$objService = Get-WmiObject -ComputerName $strSrvr -Credential $cred -class win32_service -filter "name='TermService'"
	Start-Sleep –s 5
}
until ($objService.State -eq "Running")


$MsgBox = new-object -comobject wscript.shell
$summary = $MsgBox.popup($srtSrvrUp + " IS ONLINE AND READY FOR LOGINS`n`nIP: " + $address + "`nStarted: " + $startTime + "`nOnline At: " + $endTime + "`nTerminal Services: " + $objService.State + "`n`nWould you like to connect to the server? `n`nClick 'NO' to see the results, or 'Cancel' to close",0,"NotifyUp",3)

if ($summary -eq 6) {
	$strRDP = "mstsc.exe /v:" + $strSrvr
	Invoke-Expression -Command $strRDP
}

if ($summary -eq 7) {
	
	if ($strReplyStatus.Length -gt 750) {
		Out-File -FilePath $replyTmpFile -InputObject $strReplyStatus -Encoding ASCII
		$openReply = """" + $openReplyPad + """" + " " + $replyTmpFile
		Invoke-Expression -Command $openReply
	}
	else {
		$response = $MsgBox.popup($strReplyStatus,0,"Ping Response History")
	}
}