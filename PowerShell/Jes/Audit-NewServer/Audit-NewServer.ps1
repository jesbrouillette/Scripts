$ErrorActionPreference = "SilentlyContinue"

# Gather info for future use
$objIPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
$os = gwmi -Query "SELECT * FROM Win32_OperatingSystem"
$services = get-service
$drives = gwmi -Query "SELECT DeviceID FROM win32_logicaldisk WHERE DriveType = '3'" | Select -expand DeviceID
$nics = gwmi -query "SELECT * FROM win32_networkadapterconfiguration WHERE IPEnabled = 'True'"
$gpos = Get-WmiObject -Namespace root\rsop\computer -Class rsop_gpo | Select -expand Name

$suffix = "na.corp.cargill.com","eu.corp.cargill.com","la.corp.cargill.com","ap.corp.cargill.com","admin.cargill.com","cgo.cargill.com","food.cargill.com","cargill.com","grain.cargill.com","meat.cargill.com"
$dnswins = "10.47.133.22","10.47.133.23"
$ntfsperms = "BUILTIN\Administrators","NT AUTHORITY\SYSTEM"
$altirisserv = "admpls151m.na.corp.cargill.com"
$aprvadmins = "$env:COMPUTERNAME\rotartsinimda","CORP\AD ESNS Server Admins","CORP\AD CSC Backup Contractors","CORP\AD CSC Server Admins","CORP\AD MWTS Server Admins"

if ($os.Name -match "2003.*x64") { $version = "2003" ; $bit = "x64" }
elseif ($os.Name -match "2003") { $version = "2003" ; $bit = "x86" }
elseif ($os.Name -match "2008" -and $os.OSArchitecture -match "64") { $version = "2008" ; $bit = "x64" }
elseif ($os.Name -match "2008") { $version = "2008" ; $bit = "x86" }

# Check-VM
#
# Check if the hardware is Virtual or Physical

if ((gwmi win32_computersystem).Manufacturer -match "VMWare") { $vmware = $true }
else { $vmware = $false }

# Check for the VMTools installation
if ($vmware) {
	if ($services | ? { $_.Name -match "VMTools" }) {
		$vmtools = $true
		if (Test-Path "C:\Program Files\VMware\VMware Tools\VMwareToolboxCmd.exe") {
			Start-Process "C:\Program Files\VMware\VMware Tools\VMwareToolboxCmd.exe" -ArgumentList "timesync status" -NoNewWindow -RedirectStandardOutput timesync.txt -Wait
			$vmtimesync = gc timesync.txt
			ri timesync.txt -Force
		}
		if ((Get-ItemProperty "C:\Program Files\VMware\vMware Tools\VMwareService.exe" | Select -expand VersionInfo | Select -expand FileVersion) -match "4.0.0 build-261974") {
			$vmtlsupg = $true
		}
		else { $vmtlsupg = $false }
	}
	else { $vmtools = $false }
}
else {
	$vmtools = "N/A"
	$vmtlsupg = "N/A"
	$vmtimesync = "N/A"
}

# Exchange specifics
$aspnet = Test-Path "C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727"

if ($services | ? { $_ -match "SMTPSVC" }) { $smtp = $true }
else { $smtp = $false }

if ($services | ? { $_ -match "NntpSvc" }) { $nntp = $true }
else { $nntp = $false }

# Exchange TrendMicro server group policy
if ($gpos | ? { $_ -match "ADEXCH Servers TrendMicro Server Policy Apply" }) { $tmpolicy = $true }
else { $tmpolicy = $false }

# Checks for the existance of the Altiris Agent
if ($services | ? { $_.Name -match "AeXNSClient" }) { $altiris = $true }
else { $altiris = $false }

if ($altiris) {
	if (Test-Path "HKLM:\SOFTWARE\Altiris\Altiris Agent\servers") {
		if ((Get-ItemProperty "HKLM:\SOFTWARE\Altiris\Altiris Agent\servers" | Select -expand "(default)") -eq $altirisserv) { $altirisns = $true }
		else { $altirisns = $false }
	}
	elseif (Test-Path "HKLM:\SOFTWARE\Wow6432Node\Altiris\Altiris Agent\servers") {
		if ((Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Altiris\Altiris Agent\servers" | Select -expand "(default)") -eq $altirisserv) { $altirisns = $true }
		else { $altirisns = $false }
	}
	else { $altirisns = $false }
}
else { $altirisns = $false }

# Check-LocalUsers
$admins = ([ADSI]("WinNT://$env:COMPUTERNAME/Administrators,group")).Members() | % {  
    $AdsPath = $_.GetType().InvokeMember("Adspath", 'GetProperty', $null, $_, $null)  
    $a = $AdsPath.split('/')  
    $a[-2] + "\" + $a[-1]
}

# Check SEP Client
if ($services | ? { $_.Name -match "Symantec AntiVirus" }) { $sepclient = $true }
else { $sepclient = $false }

if ($sepclient) {
	if ((Get-ItemProperty "HKLM:\SOFTWARE\Symantec\Symantec Endpoint Protection\SMC\SYLINK\SyLink" | Select -expand PreferredGroup) -eq "My Company\NA\non-itsb\csc\uselkg\server") { $sepgroup = $true }
	else { $sepgroup = $false }
}

# Check disk permissions
if ($drives | ? { $_ -ne "C:" }) {
	$diskperm = $drives | ? { $_ -ne "C:" } | % {
		$drive = $_
		Get-Acl $drive
	} | select -expand access | Select -expand IdentityReference | Select -expand Value | Sort -Unique
	if ((Compare-Object $ntfsperms $diskperm).count) { $ntfscheck = $false }
	else { $ntfscheck = $true }
}
else { $ntfscheck = "N/A" }

# DNS Suffix
$dnssuffix = $nics | Select -expand DNSDomainSuffixSearchOrder | Sort -Unique
if ($dnssuffix) {
	$dnssufcheck = if ((Compare-Object $suffix $dnssuffix).count) { $false } else { $true }
}
else { $dnssufcheck = $false }

# DNS Check
$dns = $nics | ? { $_.DNSServerSearchOrder -ne $null } | Select -expand DNSServerSearchOrder | Sort -Unique
$dnscheck = if ((Compare-object $dns $dnswins).count) { $false } else { $true }

# WINS Check
$wins = @(($nics | Select -expand WINSPrimaryServer | Sort -Unique),($nics | Select -expand WINSSecondaryServer | Sort -Unique))
$winscheck = if ((Compare-object $wins $dnswins).count) { $false } else { $true }

# DHCP Settings

$DHCP = { 
	$nics | % {
		if ($_.DHCPEnabled) { $enabled = $true }
	}
	if (!$enabled) { $enabled = $false }
	$enabled
}

# Network bindings order
$ntwkey = "HKLM:\SYSTEM\CurrentControlSet\Control\Network\{4D36E972-E325-11CE-BFC1-08002BE10318}"
$bindings = get-itemproperty "HKLM:\System\CurrentControlSet\Services\Tcpip\Linkage" | Select -expand Bind | ? { $_ -match "\{" } | % {$_.Replace("\Device\","")} | % {
	get-itemproperty "$ntwkey\$($_)\Connection" | Select -expand Name
}

# Network Speed/Duplex settings

$links = get-wmiobject -query "SELECT * FROM MSNdis_LinkSpeed WHERE Active='True'" -namespace "root\WMI"

$key = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"

$baseKeys = gci $key | Select -expand PSChildName | % { "$_" }

$speedduplex = $nics | % {
	$nic = $_
	$baseKeys | % {
		$subkey = $_
		$row = "" | Select Description,Speed,Duplex
		get-itemproperty "$key\$subkey" | ? { $_.NetCfgInstanceId -match $nic.SettingId } | % {
			$componentID = $_.ComponentID
			$row.Description = get-itemproperty "$ntwkey\$($_.NetCfgInstanceId)\Connection" | Select -expand Name
			if ($componentID -match "ven_14e4") {
				$SD = $_.RequestedMediaType
				$enum = get-itemproperty "$key\$subkey\Ndi\Params\RequestedMediaType\Enum"
				$sdValue = $enum."$SD"
			} elseif ($componentID -match "ven_1022") {
				$SD = $_.EXTPHY
				$enum = get-itemproperty "$key\$subkey\Ndi\Params\EXTPHY\Enum"
				$sdValue = $enum."$SD"
			} elseif ($componentID -match "ven_8086") {
				$SD = $_.SpeedDuplex
				if (Test-Path "$key\$subkey\Ndi\savedParams\SpeedDuplex\Enum") { $enum = get-itemproperty "$key\$subkey\Ndi\savedParams\SpeedDuplex\Enum" }
				if (Test-Path "$key\$subkey\Ndi\Params\SpeedDuplex\Enum") { $enum = get-itemproperty "$key\$subkey\Ndi\Params\SpeedDuplex\Enum" }
				$sdValue = $enum."$SD"
			} elseif ($componentID -match "b06bdrv") {
				if ($_."`*SpeedDuplex") { $SD = $_."`*SpeedDuplex" }
				else { $SD = $_.req_medium }
				if (Test-Path "$key\$subkey\Ndi\Params\req_medium\Enum") { $enum = get-itemproperty "$key\$subkey\Ndi\Params\req_medium\Enum" }
				if (Test-Path "$key\$subkey\BRCMndi\params\req_medium\Enum") { $enum = get-itemproperty "$key\$subkey\BRCMndi\params\req_medium\Enum" }
				if (Test-Path "$key\$subkey\BRCMndi\params\`*SpeedDuplex\Enum") { $enum = get-itemproperty "$key\$subkey\BRCMndi\params\`*SpeedDuplex\Enum" }
				$sdValue = $enum."$SD"
			} elseif ($nic.Description -match "VMWare") {
				$SD = $_.EXTPHY
				$enum = get-itemproperty "$key\$subkey\Ndi\Params\EXTPHY\Enum"
				$sdValue = $enum."$SD"
			} elseif ($nic.Description -match "vmxnet3") {
				$SD = $_."`*SpeedDuplex"
				$enum = get-itemproperty "$key\$subkey\Ndi\Params\`*SpeedDuplex\Enum"
				$sdValue = $enum."$SD"
			} else { $sdValue = "unknown" }
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
				} elseif ($sdValue -match "Auto Negotiation" -or $sdValue -match "Auto Detect") {
					$speed = "Auto"
					$duplex = "Auto"
				} else {
					$speed = $sdValue
					$duplex = $sdValue
				}
			}
			$row.Speed = $speed
			$row.Duplex = $duplex
			$row
		}
	}
}

# BESR Check
if ($services | ? { $_.Name -match "Backup Exec System Recovery" }) { $besr = $true }
else { $besr = $false }

if ($besr) {
	if (Test-Path "C:\ProgramData\Symantec\Backup Exec System Recovery\Schedule\") { $besrenabled = $True }
	elseif (Test-Path "C:\Documents and Settings\All Users.WINDOWS\Application Data\Symantec\Backup Exec System Recovery\Schedule") { $besrenabled = $True }
	elseif (Test-Path "C:\Documents and Settings\All Users\Application Data\symantec\Backup Exec System Recovery\Schedule") { $besrenabled = $True }
	else { $besrenabled = $false }
}
else { $besrenabled = "N/A" }

# ESNS permissions
if ($admins -contains "CORP\AD ESNS Server Admins") { $esnsadmin = $true }
else { $esnsadmin = $false }

# CSC Backup permissions
if ($admins -contains "CORP\AD CSC Backup Contractors") { $cscbkpadmin = $true }
else { $cscbkpadmin = $false }

# CSC Wintel permissions
if ($admins -contains "CORP\AD CSC Server Admins") { $cscsrvadmin = $true }
else { $cscsrvadmin = $false }

# MWTS permissions
if ($admins -contains "CORP\AD MWTS Server Admins") { $mwtsadmin = $true }
else { $mwtsadmin = $false }

# Non-approved Admins
$noaprvadmins = Compare-Object $aprvadmins $admins | ? { $_.SideIndicator -ne "<=" -and $_.InputObject -notmatch "Domain Admins" } | Select -expand InputObject

# Exchange permissions
if ($admins -contains "na\AD Exchange Admins") { $exchadmin = $true }
else { $exchadmin = $false }

# Set-PageFile
#
# Sets the Page File size based on Cargill standards as of 1/10/11
#
# All terminal servers get 2x the amount of physical ram allocated for the PageFile
# Non-terminal servers with less than 8G of physical ram get 1.5x the amount of physical ram allocated for the PageFile
# Non-terminal servers with more than 8G of physical ram get 1G more than the amount of physical ram allocated for the PageFile
#
# Check for TS

if ($os.Name -match "2003") {
	switch ((gwmi win32_TerminalServiceSetting).TerminalServerMode) {
		0 { $citrix = $true }
		1 { $citrix = $false }
	}
}
else { $citrix = $false }

$pagefile = gwmi Win32_PageFileSetting | Select -expand InitialSize

$ram = gwmi Win32_OperatingSystem | select TotalVisibleMemorySize
$ram = ($ram.TotalVisibleMemorySize/1kb).tostring()

# All terminal servers get 2x the amount of physical ram allocated for the PageFile
if ($citrix) { $pfsize = $ram * 2 }

else {
	# Non-terminal servers with less than 8G of physical ram get 1.5x the amount of physical ram allocated for the PageFile
	if ($ram -lt 8388608) { $pfsize = $ram * 1.5 }
	# Non-terminal servers with more than 8G of physical ram get 1G more than the amount of physical ram allocated for the PageFile
	else { $pfsize = $ram + 1048576 }
}

if ($pfsize = $ram) { $pfset = $true }
else { $pfset = $false }

# ESMS Services Check
if ($services | ? { $_.Name -match "HealthService"}) { $esmsservice = $true }
else { $esmsservice = $false }

# Device KB Check
$url = "http://sharepoint.hosting.cargill.com/Device%20KB/$($env:COMPUTERNAME.ToUpper()).aspx"
            
$webclient = New-Object Net.WebClient

$webclient.Credentials = [System.Net.CredentialCache]::DefaultCredentials
if($webclient.Proxy -ne $null) {
	$webclient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
}
$kbresponse = $webclient.DownloadString($url)

if ($kbresponse) { $devicekb = $true }
else { $devicekb = $false }

# ProSetup Profile
$prosetup = Get-ItemProperty "HKLM:\SOFTWARE\Cargill\Prosetup\Applied"
$psterm = $prosetup.TerminalServices -eq 1
$psbuilder = gc C:\Source\Prosetup\Prosetup.log | ? { $_ -match "corp\\admin_[A-Z0-9]{0,8}" } | % { $Matches[0] }

if ($prosetup.ProfileName -ne "" ) { $pstemplate = $prosetup.ProfileName }
else { $pstemplate = "N/A" }

# Tartan
$timezone = gwmi win32_timezone | select -expand StandardName

if ($services | ? { $_.Name -match "ctmag"}) { $ctrlmagent = $true }
else { $ctrlmagent = $false }

"" | Select `
	@{Name="Server";Expression={"{0}.{1}" -f $objIPProperties.HostName, $objIPProperties.DomainName}},`
	@{Name="All_Altiris";Expression={$altiris}},`
	@{Name="All_AltirisNS";Expression={$altirisns}},`
	@{Name="All_SpeedDuplex";Expression={$speedduplex}},`
	@{Name="All_SEPClient";Expression={$sepclient}},`
	@{Name="All_SEPGroup";Expression={$sepgroup}},`
	@{Name="All_DiskPermissions";Expression={$ntfscheck}},`
	@{Name="All_DNSSuffixCheck";Expression={$dnssufcheck}},`
	@{Name="All_DNSCheck";Expression={$dnscheck}},`
	@{Name="All_WINSCheck";Expression={$winscheck}},`
	@{Name="All_Bindings";Expression={$bindings}},`
	@{Name="All_BESR";Expression={$besr}},`
	@{Name="All_BESREnabled";Expression={$besrenabled}},`
	@{Name="All_MWTSAdmin";Expression={$mwtsadmin}},`
	@{Name="All_CSCServerAdmin";Expression={$cscsrvadmin}},`
	@{Name="All_CSCBackupAdmin";Expression={$cscbkpadmin}},`
	@{Name="All_ESNSAdmin";Expression={$esnsadmin}},`
	@{Name="All_NonApprovedAdmins";Expression={$noaprvadmins}},`
	@{Name="All_PageFileSet";Expression={$pfset}},`
	@{Name="All_ESMSService";Expression={$esmsservice}},`
	@{Name="All_DeviceKB";Expression={$devicekb}},`
	@{Name="ProSetup_Template";Expression={$pstemplate}},`
	@{Name="ProSetup_TermSrvCheck";Expression={$psterm}},`
	@{Name="ProSetup_Builder";Expression={$psbuilder}},`
	@{Name="VMWare_VMWare";Expression={$vmware}},`
	@{Name="VMWare_VMTools";Expression={$vmtools}},`
	@{Name="VMWare_VMToolsUpgraded";Expression={$vmtlsupg}},`
	@{Name="VMWare_VMTimeSync";Expression={$vmtimesync}},`
	@{Name="Exchange_Admin";Expression={$exchadmin}},`
	@{Name="Exchange_ASP";Expression={$aspnet}},`
	@{Name="Exchange_SMTP";Expression={$smtp}},`
	@{Name="Exchange_NNTP";Expression={$nntp}},`
	@{Name="Exchange_TrendMicro";Expression={$tmpolicy}},`
	@{Name="Tartan_TimeZone";Expression={$timezone}},`
	@{Name="Tartan_CtrlMAgent";Expression={$ctrlmagent}}`
| Out-File C:\Source\Library\CSC\Audit_NewServer\Results.txt -Force