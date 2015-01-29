# Windows PowerShell script
# Filename: TartanDR_v1.ps1
#
# Date Created: 03-15-2010
# Last Modified: 04-19-2010
# Author: Bart_Sierens@Cargill.com (Cargill GIHS/MWTS)
# Function: Launch Tartan DR services on Windows servers#
# 
# Usage: Start Powershell console from msusnorw054, type %path%\scriptname.ps1 eg. C:\Source\Library\mwts\scripts\TartanDR_v1.ps1
# check execution policy via cmdlet "get-executionpolicy" if needed change to remote signed by running "set-executionpolicy remotesigned"
# Administrator privileges are required to run this script against remote servers
# additional info can be found on sharepoint:
# http://teaming.cargill.com/sites/NorwichProject/Shared Documents/Failover Solution/Application startup and validation scripts/TartanDR_WindowsScriptOVERVIEW.doc


# Declaring variables
$log = "C:\Source\Library\TartanDrLogs"
if(!(test-path $log -pathtype container)){new-item $log -type directory}
$Share = $log
$shareName = "TartanDrLogs$"
$MdmPrereq = $log + "\SapGateway.txt"
$MdmReady = $log + "\Mdm.txt"
$TptPrereq = $log + "\TptDbUp.txt"
$Verify = "ok"
$NwGateway = "10.48.133.1"
$log = $log + "\Powershell.log"

# list physical windows DR servers + virtual guests that will be migrated from EG to Norwich via SRM
#$WinP_DRservers = ("server1", "server2", "server3", "server4", "server5", "server6", "server7")
#$WinV_DRservers = ("server8", "server9", "server10", "server11", "server12", "server13")
#$WinP_DRservers = ("admptn032m", "admptn033m", "beizeg010m")
$WinP_DRservers = ("beizeg008m", "beizeg009m", "beizeg010m")
$WinV_DRservers = ("nleuds506m", "gbcobo16m", "gbcobo017m")

$BobjDS_servers = ("gbcobo16m","nleuds506m") #msusegpr007/msusegpr008
$BobjDS_services = ("Spooler") #BOE120Tomcat

$mdm_servers = ("gbcobo16m","nleuds506m") #msusnwdr030/msusnwdr040
$mdm_cmdLine = "C:\Source\Library\MWTS\tools\poolsnap.cmd" #command to be provided by Deb

$BoeXI_servers = ("gbcobo16m","nleuds506m") #msusegst025/msusegst026
$BoeXI_services = ("Spooler", "HealthService") #BOE120Tomcat/BOE120SIAMSUEGST025/#BOE120SIAMSUEGST026

$TptCR_server = "nleuds506m" #"admptn038m" #DEV:admptn038m DR:msusnwdr024
$TptCR_service = "Spooler" #"TPTCreditRisk"
$TptCR_CmdLine1 = "echo TptCR start scheduled task Z_RUN_KETTLE_1" #"Schtasks /run /TN Z_RUN_KETTLE_1" 
$TptCSL_Controller = "gbcobo16m" #"admptn033m"
$TptCSL_servers = ("gbcobo16m") #admptn032m #msusnwdr020/021/022
$TptCSL_CmdLine0 = "Echo TptCSL_CmdLine0" #"D:\usr\sap\DT1\SYS\exe\uc\NTAMD64\startsap.exe name=DT1 nr=51 SAPDIAHOST=admptn033m"
$TptCSL_cmdLIne1 = "Echo TptCSL_CmdLine1" #"D:\usr\sap\DT1\SYS\exe\uc\NTAMD64\startsap.exe name=DT1 nr=52 SAPDIAHOST=admptn033m" 
$TptCSL_cmdLIne2 = "C:\Source\Library\MWTS\test.cmd" #"call D:\CommoditySL\XL_7_1_2\build\service\xl_service_start.cmd" 
$TptUrl = "http://admptn033m:55200/index.html"

# Functions to start service or commandline
function StartSvc([string]$service)
{
	$Svc = Get-WmiObject -Computer $s win32_service -filter "name='$service'"
	$Result = $Svc.StartService()
	switch ($Result.returnvalue)
	   { 
        	0 {"$s $service started successfully." >> $log} 
	        2 {"$s $service Access Denied." >> $log} 
        	3 {"$s $service Insufficient Privilege." >> $log} 
	        5 {"$s $service is already stopped." >> $log}
		8 {"$s $service Unknown failure." >> $log} 
        	9 {"$s $service Path Not Found." >> $log} 
		10 {"$s $service was already started." >> $log} 
	        21 {"$s $service Invalid Parameter." >> $log} 
        	default {"$s $service Could not be started, service is disabled or does not exist." >> $log}
	    } 	
}

function StartCmd([string]$Cmdline)
{
	$result = ([WmiClass]"\\$s\ROOT\CIMV2:Win32_Process").create("cmd /c $cmdline")
	switch ($result.returnvalue) 
	    { 
        	0 {"$s Successful Completion."} 
	        2 {"$s Access Denied."} 
        	3 {"$s Insufficient Privilege."} 
	        8 {"$s Unknown failure."} 
        	9 {"$s Path Not Found."} 
	        21 {"$s Invalid Parameter."} 
        	default {"$s command line experienced an error, please validate manual."}
	    }	

	if ($result.returnvalue -eq 0)
	   {

		write-host "$Cmdline ran successfully on $s"

	   }
}


Write-Host "`nScript started at: $(Get-Date -format g) - to stop press CTRL+C`n"
“Script started at: $(Get-Date -format g)`n” > $log

# validation pre-requisitives 

if ((gwmi Win32_Share | Where { $_.Path -eq $Share}).Path -eq $Share ) {Write-Host "Share: $ShareName is ok."}
	else {Write-Host "Share to store logfiles does not exist! `nPlease validate if $Share is shared as $ShareName" -foregroundcolor red}

# check if system is up and running on all DR servers + check ip address of virtual servers
write-host "Starting validation"
foreach ($s in $WinP_DRservers)
{	
	$Process = gwmi win32_process -comp $s | select-Object processName | where-object {$_.ProcessName -eq "system"}
	If ($Process.processname -eq "system") {write-host "$s is up and running"}
		else {write-host "$s is not available, please verify!"}		
}

foreach ($s in $WinV_DRservers)
{
	$gateway = gwmi -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -Comp $s | Select-Object -Property defaultIPGateway
	if ($gateway.defaultIPgateway -eq $NwGateway) {write-host "Gateway for $s is ok: $gateway.defaultIPgateway"}
	else {	write-host "Gateway for $s seems not ok:" $gateway.defaultIPgateway -foregroundcolor red
		write-host "Check if SRM successfully failed over vmware guest from Elk Grove to Norwich datacenter!!!"}
}


# acknowledge it's ok to proceed further
do {[string]$Verify = Read-Host “Please confirm it's ok to proceed [Y,N]”} 
while ($Verify -ne “Y” -AND $Verify -ne "N")
if ($Verify -eq "N") {exit}
	

# Wait for Unix script to catch up
write-host "Waiting until Unix script has started SAP Gateways"
while (-not (test-path $MDMPrereq)) {Start-Sleep –s 5}
“Unix SAP gateways have been started at $(Get-Date -format g)” >> $log 


# application startup BOBJ DS
write-host "Proceeding with application startup"
foreach ($s in $BobjDS_servers)
  {
	foreach ($service in $BobjDS_services)	
		{
			StartSvc ("$service") 
		} 

  }

# application startup MDM
foreach ($s in $mdm_servers)
  {
	StartCmd ("$mdm_cmdLine")
  }
“MDM started at: $(Get-Date -format g)” > $MdmReady

# application startup BOE XI
write-host "Starting BOE XI, a Warning is expected when attempting to start a service that doesn't exist"
write-host "Service BOE120SIAMSUEGST025 should only exist on msusegst025 `nService BOE120SIAMSUEGST026 should only exist on msusegst026`n"

foreach ($s in $BOEXI_Servers)
  {
	foreach ($service in $BoeXI_services)	
		{
			StartSvc ("$service") 
		} 

  }

# application startup TtpCR
$s = $TptCR_server
StartSvc ("$TptCR_service")
StartCmd ("$TptCR_CmdLine1") 
#start test scheduled task

# application startup TtpCSL
write-host "Waiting until Unix script has verified that TPT transactional database is available"
while (-not (test-path $TptPrereq)) {Start-Sleep –s 5}
“Unix script confirmed that TPT transactional database is available at $(Get-Date -format g)`n” >> $log 
$s = $TptCSL_Controller #confirm where we can run D:\usr\sap\RT1\SYS\exe\uc\NTAMD64\startsap.exe  
write-host "Running StartSap.exe on $TptCSL_Controller"
StartCmd ("$TptCSL_cmdLIne0")
Start-Sleep –s 5
StartCmd ("$TptCSL_cmdLIne1")
write-host "Pauzing script for 5 minutes before starting CSL_XL services"
#Start-Sleep –s 300
#hold until website http://admptn033m:55200/ is available
$check = "wait"
$lines = "empty"
write-host "Checking if $TptUrl is available"
$check = "wait"
do { 
	Start-Sleep –s 5
	$wc = New-Object net.webclient
     	$page = $wc.DownloadString("$TptUrl")
     	$lines = $page.split("`n")
     	$lines = $lines | ?{$_ -match '<title>'}
	if (!($lines -match "<title>SAP*")) {$check = "wait"
		do {[string]$Verify = Read-Host “Website is not available yet, `nPress C to continue, press T to test availability again [C,T]”}
		while ($Verify -ne “C” -AND $Verify -ne "T")
		if ($Verify -eq "C") {$check = "Ignore"}
	    	} else {$check = "Proceed"}	
			
   }
while ($check -eq "wait")
If ($Check -eq "Proceed") { write-host "$TptUrl is available`n" 
			    "$TptUrl was available at $(Get-Date -format g)" >> $log}
		            else { write-host "$TptUrl is not available yet, proceeding anyway with next step`n" 
				   "$TptUrl was not available yet at $(Get-Date -format g), check was ignored" >> $log}  

write-host "Starting XL services on process servers"
foreach ($s in $TptCSL_servers)
  {
	StartCmd ("call $TptCSL_cmdLIne2")
  }


# Validation of Windows components
Write-host "Validating CSL, pauzing script for 15sec before checking service state"
Start-Sleep –s 15
foreach ($s in $TptCSL_servers)
  {
	write-host "Verifying Service state for CSL_XL* on $s"
	$output = gwmi win32_service -comp $s | select-Object Name, State | where-object {$_.Name -match "^CSL_XL.*"} | Sort Name
  	"Service state on $s" >> $log
	$output >> $log
	$output
	$TptCSL_log = "\\$s\d$\CommoditySL.7.1.2.05\XL_7_1_2\logs\cfserver1.log"
	#update path needed for prod
	write-host "`nLooking for errors in $TptCSL_log"
	if ((test-path $TptCSL_log) -eq $True) {select-string $TpTCSL_log -pattern "ERROR"}
  }


“`nScript finished at: $(Get-Date -format g)” >> $log
write-host "`nScript has finished"
write-host "Output of script is captured in" $log
