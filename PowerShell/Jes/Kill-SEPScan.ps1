Param (
	[string]$list
)

Function ReadWriteReg {
	Param (
		[string]$perform,
		[string]$RegValue,
		[Object]$RootKey,
		[string]$RegData,
		[string]$RegType
	)

	if ($perform -match "read") {
		$RootKey.GetValue($RegValue)
	}
	elseif ($perform -match "write") {
		$RootKey.SetValue($RegValue, $RegData, [Microsoft.Win32.RegistryValueKind]::$RegType)
	}
}

GC $list | % {
	$error.clear()
	"Correcting $($_) for SEP Scanning" | Add-Content "c:\temp\kill-sepscan\log.txt"
	"Correcting $($_) for SEP Scanning"
	$service = Get-Service -Name "Symantec AntiVirus" -Computer $_
	if ($service) {
		#Disable Tamper Protection
		$RegValue = "Disabled"
		$RegData = 1
		$RegType = "DWORD"
		$RegKey = "SOFTWARE\Symantec\Symantec Endpoint Protection\AV\Storages\SymProtect\RealTimeScan"
		$RootKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LOCALMACHINE",$_).OpenSubKey("$RegKey", [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
		if (!$RootKey) {
			$RegKey = "SOFTWARE\Symantec\Symantec Endpoint Protection\AV\Storages\SymProtect\RealTimeScan"
			$RootKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LOCALMACHINE",$_).OpenSubKey("$RegKey", [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
		}
		$set = ReadWriteReg "Write" $RegValue $RootKey $RegData $RegType
		
		#Stop Service
		$Stop = $service.Stop()
		
		$RootKey.Flush()
		$RootKey.Close()

		#disable Scans
		$RegValue = "ENABLED"
		$RegData = 0
		$RegType = "DWORD"
		$RegKey = "SOFTWARE\Symantec\Symantec Endpoint Protection\AV\LocalScans"
		$RootKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LOCALMACHINE",$_).OpenSubKey("$RegKey", [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
		if (!$RootKey) {
			$RegKey = "Software\Symantec\Symantec Endpoint Protection\AV\Local Scans"
			$RootKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LOCALMACHINE",$_).OpenSubKey("$RegKey", [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)
		}
		if ($RootKey.GetSubKeyNames() -contains "ManualScan") {
			$rootkey.GetSubKeyNames() | ? {
				$_ -match "-"
			} | % {
				$rootkey.DeleteSubkeyTree($_)
			}
		}
		else {
			End
		}
		$RootKey.Flush()
		$RootKey.Close()
		$count = 0
		do {
			$service = Get-Service -Name "Symantec AntiVirus" -Computer $_
			Start-Sleep -seconds 2
			Write-Host "$($service.Status) $count"
			$count++
		}
		until ($service.Status -ne "StopPending" -or $count -ge 30)
		if ($count -ge 30) {
			"Could not start $($_)" | Add-Content "c:\temp\kill-sepscan\log.txt"
			"Could not start $($_)" 
		}
		$service.Start()
	}
	else {
		"Could not find the service on $($_)" | Add-Content "c:\temp\kill-sepscan\log.txt"
		"Could not find the service on $($_)"
	}
	if ($error) {
		"$($_): $Error[0].exception.message" | Add-Content "c:\temp\kill-sepscan\log.txt"
		"$($_): $Error[0].exception.message"
		$error.clear()
	}
}