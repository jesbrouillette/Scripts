#$erroractionpreference = "SilentlyContinue" 

$list = Get-Content $args[0] #list of server to search
$location = $args[1]
$replace = $args[2] #text to replace with
$searchfor = $args[3],$args[4] #settings to search for

$backup = ((Split-Path -Leaf $location).Split(".")[0]) + "-" + (get-date -format ddMMyy) + ".bak"
$logfile = "Replace-Text.log"

$count = 0
$reported = 0
$not_updated = 0

$newcontent = New-Object System.Collections.ArrayList
$log = New-Object System.Collections.ArrayList
$changed = New-Object System.Collections.ArrayList

$logging = $log.Add("#############################")
$logging = $log.Add("#                           #")
$logging = $log.Add("#  MF20.DSN update process  #")
$logging = $log.Add("#                           #")
$logging = $log.Add("#############################")
$logging = $log.Add(" ")
$logging = $log.Add("Started: " + (Get-Date))
$logging = $log.Add("By : " + ($env:Userdomain).ToUpper() + "\" + ($env:Username).ToLower())
$logging = $log.Add(" ")
$logging = $log.Add("===========================")
$logging = $log.Add(" ")

foreach ($server in $list) {
	$count += 1
}
Write-Host $Count "files to update"

foreach ($server in $list) {
	$reported += 1
	$openfile = "\\" + $server + "\" + $location -replace ":","$"
	$oldbackup = $server + "-" + ((Split-Path -Leaf $location).Split(".")[0]) + ".old"

	$backup_location = (Split-Path -Parent $openfile) + "\" + $backup
	$test = Test-Path "C:\Temp\CTX\MF20s\"
	if ($test -eq $False) {
		$mkdir = New-Item "C:\Temp\CTX\MF20s\" -ItemType directory
	}
	$oldbackup_location = "C:\Temp\CTX\MF20s\" + $oldbackup

	if ((Test-Path -Path $backup_location) -eq $true) {
		$Delete_Backup = Remove-Item $backup_location
	}

	$create_backup = Rename-Item -Path $openfile -NewName $backup

	if ((Test-Path -Path $oldbackup_location) -eq $false) {
		$create_oldbackup= Copy-Item -Path $backup_location -Destination $oldbackup_location
	}
	
	if ($error) {
		$logging = $log.Add("ERROR: File " + $oldbackup_location + " could not be created.  " + $error[0].Exception.Message)
		$clear_errors = $error.clear()
	}

	if ($error) {
		$logging = $log.Add("ERROR: File " + $openfile + " was not updated.  " + $error[0].Exception.Message)
		$clear_errors = $error.clear()
	}
	else {
		$dsn = Get-Content $backup_location
	
		foreach ($line in $dsn) {
			if ($line -match $searchfor[0]) {
				$old = $changed.Add("`tfrom: " + $line)
				$old = $changed.Add("`t  to: " + $searchfor[0] + $replace)
				$add = $newcontent.Add($searchfor[0] + $replace)
			}
			elseif ($line -match $searchfor[1]) {
				$old = $changed.Add("`tfrom: " + $line)
				$old = $changed.Add("`t  to: " + $searchfor[1] + $replace)
				$add = $newcontent.Add($searchfor[1] + $replace)
			}
			elseif ($line -match "Trusted_Connection=" -or $line -match "Network=" -or $line -match "UID=") {
			}
			else {
				$add = $newcontent.Add($line)
			}
		}
		$write_newfile = $newcontent | Out-File $openfile
		$clear_newcontent = $newcontent.Clear()
		
		if ($error) {
			$logging = $log.Add("ERROR: File for " + $server + " was not updated.  " + $error[0].Exception.Message)
			$clear_errors = $error.clear()
		}
		else {
			$logging = $log.Add($openfile + " updated")
			$logging = $log.Add($changed)
		}
	}

	if (($reported % 10) -eq 0 -or $reported -eq $count -and $reported -ne 0) {
		Write-Host " " $reported "of" $count "files updated"
	}
	$logging = $log.Add(" ")
	$logging = $log.Add("===========================")
	$logging = $log.Add(" ")
}

foreach ($log_entry in $log){
	if ($log_entry -match "ERROR") {
		$not_updated += 1
	}
}

$logging = $log.Add($not_updated.ToString() + " Files not updated")
$logging = $log.Add(($count - $not_updated).ToString() + " Files updated succesfully")
$logging = $log.Add(" ")
$logging = $log.Add("===========================")
$logging = $log.Add("Finished: " + (Get-Date))
$logging = $log.Add(" ")

$write_logfile = $log | Out-File $logfile -Append