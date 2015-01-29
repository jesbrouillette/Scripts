param (
	[string]$csv = "list.csv"
)

function GetUser ($Domain,$User) {
	if ($domain.ToLower() -eq "ap"){ $dc = "dc=ap,dc=corp,dc=cargill,dc=com" }
	elseif ($domain.ToLower() -eq "eu"){ $dc = "dc=eu,dc=corp,dc=cargill,dc=com" }
	elseif ($domain.ToLower() -eq "la"){ $dc = "dc=la,dc=corp,dc=cargill,dc=com" }
	elseif ($domain.ToLower() -eq "meat"){ $dc = "dc=meat,dc=cargill,dc=com"}
	elseif ($domain.ToLower() -eq "na"){ $dc = "dc=na,dc=corp,dc=cargill,dc=com" }
	elseif ($domain.ToLower() -eq "corp"){ $dc = "dc=corp,dc=cargill,dc=com" }
	else { $dc = "no ADSI path found" }
	if ($dc -ne "no ADSI path found") {
		$AD = [ADSI]("LDAP://$DC")
		$search = new-object System.DirectoryServices.DirectorySearcher
		$search.SearchRoot = $AD
		$search.Filter = "(&(objectCategory=user)(sAMAccountName=$user))"
		$adUser = $search.findall()
		if ($adUser.length -gt 1) { $adUser = $adUser[0] }
		return $adUser
	}
	else { write-host $Domain"\"$User " was not found" ; return $false }
}
function CopyDataBITS ($source,$destination,$name){
	$sourceProperty = Get-ItemProperty $source
	if ($sourceProperty.Attributes -eq "Directory") { 
		$content = gci $source
		foreach ($item in $content) {
			$sourceParent = $item.DirectoryName.Split("\")
			$destinationNew = $destination + "\" + $sourceParent[$sourceParent.Length - 1]
			$testPath = Test-Path $destinationNew
			if (!$testPath) { $create = New-Item -Path $destination -Name ($sourceParent[$sourceParent.Length - 1]) -ItemType Directory }
			return CopyDataBITS $item.FullName $destinationNew $name
		}
	}
	else {
		$start = Get-Date
		$error.Clear()
		$transfer = New-FileTransfer -ServerFileName $source -ClientFileNamePrefix $destination -DisplayName $name -Asynchronous
		if (!$transfer) {	
			$Error[0].Exception.Message
			Set-Variable -Scope Script -Name bits -Value $false
			$errMsg = "BITS failed to run. Attempting to start the data copy using another method"
			Write-Host $errMsg
			
			$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
			$row.User = $item.User
			$row.Source = [string]$source
			$row.Destination = $destination
			$row.Method = "BITS"
			$row.Error = "0x00000001"
			$row.Note = $errMsg
			Set-Variable -Scope Script -Name report -Value ($report + $row)
			
			if ($richcopy) { return CopyDataRICHCOPY $source $destination }
			elseif ($robocopy) { return CopyDataROBOCOPY $source $destination }
			else { return CopyDataXCOPY $source $destination }
			
		} 
		$error.Clear()
		exit
		do {
			$job = Get-FileTransfer $name
			if ($job.BytesTransferred -gt 0) { $completion = [Math]::Round(($job.BytesTransferred / $job.BytesTotal * 100),2).ToString() + "%" }
			else { $completion = "0%"} 
		} until ($job.JobState -eq "Transferred")
		$end = Get-Date
		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.Source = $source
		$row.Destination = $destination
		$row.Method = "BITS"
		$row.Total = ([Math]::Round(($job.BytesTotal),2)).ToString() + " Bytes"
		$row.Copied = ([Math]::Round(($job.BytesTransferred),2)).ToString() + " Bytes"
		$row.Failed = ([Math]::Round(($job.BytesTotal - $job.BytesTransferred),2)).ToString() + " Bytes"
		$complete = Complete-FileTransfer $job
		Set-Variable -Scope Script -Name report -Value ($report + $row)
		return $true
	}
}

function CopyDataRICHCOPY ($source,$destination) {
	$files = 0
	$bytes = 0
	[Void](gci $source -Recurse | ? { $_.Mode -notmatch "d" } | % { $files += 1 ; $bytes += $_.Length })
	$log = [string]$pwd + "\RichCopy_" + $item.User.ToUpper() + "_" + (Get-Date -format "MM-dd-yy.HH.mm") + ".log"
	$expression = "richcopy.exe `"" + $source + "`" `"" + $destination + "`" /TSU /CLW /O /CNF /CT /CA /PRP /EDT /EDO /TS 4 /TD 4 /R 3 /QA /QP " + $log + " /UE /US /UD /UFC /UCS /UET"
	$invoke = Invoke-Expression -Command $expression
	if (!(Test-Path $log)) {
		$errMsg = "RichCopy failed to run. Attempting to start the data copy using another method"
		Write-Host $errMsg
		
		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.User = $item.User
		$row.Source = [string]$source
		$row.Destination = $destination
		$row.Method = "RichCopy"
		$row.Error = "0x00000001"
		$row.Note = $errMsg
		Set-Variable -Scope Script -Name report -Value ($report + $row)

		if ($robocopy) { return CopyDataROBOCOPY $source $destination }
		else { return CopyDataXCOPY $source $destination }
	}
	else {
		$bytes = 0
		$files = 0
		[Void]( gci $source -recurse | ? { $_.Mode -notmatch "d" } | % { $bytes += $_.Length ; $files += 1 } )
		$temp = "richtemp.csv"
		$list = Get-Content $log
		$new = @()
		foreach ($line in $list) {
			if ($prev) {
				if ($line -match " : ") {
					$line = $line.Replace(" : ",",`"")
					$line = $line.TrimEnd(",")
					$line += "`""
				}
				if ($line[0] -eq ",") {
					$prev += $line
					$new += $prev
				}
				elseif ($prev[0] -ne ",") {
					$new += $prev
				}
				$prev = $line
			}
			else { $prev = $line }
		}
		$new += $list[$list.Count-1]
		rv prev
		"TimeStamp,Error,Message,Details" | Out-File $temp -Encoding ASCII
		$new | Out-File $temp -Encoding ASCII -Append
		$list = Import-Csv $temp
		[Void]( Remove-Item -Path $temp -Force )
		foreach ($line in $list) {
			if (($line.Message -notmatch "Source path") -and ($line.Message -notmatch "Destination path") -and ($line.Message -notmatch "Copy start") -and ($line.Message -notmatch "Copy complete") -and ($line.Message -notmatch "Error is occurred during the copy process.")) {
				$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
				$row.User = $item.User
				$row.Source = [string]$source
				$row.Destination = $destination
				$row.Method = "RichCopy"
				if ($line.Error -eq "0") {
					if ($line.Message -eq "Copied file count") {
						$row.Type = "File"
						$row.Total = $files
						$row.Copied = ([string]$line.Details).TrimEnd(" files")
					}
					elseif ($line.Message -eq "Copied file size") {
						$row.Type = "Bytes"
						$row.Total = $bytes
						$row.Copied = ([string]$line.Details).TrimEnd(" bytes")
					}
					elseif ($line.Message -eq "Elapsed time") {
						$row.Type = "Elapsed Time"
						$row.Copied = $line.Details
					}
					else { $row.Note = $line.Message }
				}
				else {
					$errFill = ""
					(1..(8 - $line.Error.Length)) | % { $errFill += "0" }
					$row.Error = "0x" + $errFill + $line.Error
					$row.Note = $line.Details
					rv errFill
				}
				Set-Variable -Scope Script -Name report -Value ($report + $row)
			}
		}
		Remove-Item $log -Force
		return $true
	}
}

function CopyDataROBOCOPY ($source,$destination) {
	$log = "RoboCopy_" + $item.User.ToUpper() + "_" + (Get-Date -format "MM-dd-yy.HH.mm") + ".log"
	$expression = "robocopy.exe `"" + $source + "`" `"" + $destination + "`" /E /Z /R:3 /W:5 /COPY:DAT /V"
	$invoke = Invoke-Expression -Command $expression
	Set-Variable -Name invokeKeep -Value $invoke -Scope Script
	if ($invoke) {
		$data = @()
		foreach ($line in $invoke) {
			if ($line -match "error") {
				$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
				$row.User = $item.User
				$row.Source = [string]$source
				$row.Destination = $destination
				$row.Method = "RoboCopy"
				$row.Error = $line.Substring(26)
				$invokeError = $true
			}
			else {
				$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
				if ($line -match "Files :" -and $line -notlike "*.*") {
					$info = $line
					do { $info = [REGEX]::Replace($info,"   ","  ") } until ($info -notmatch "   ")
					$info = $info.Replace("  Files :","Files")
				}
				if ($line -match "Bytes :") {
					$info = $line
					do { $info = [REGEX]::Replace($info,"   ","  ") } until ($info -notmatch "   ")
					$info = $info.Replace("  Bytes :","Bytes")
				}
		
				if ($info) {
					$info = [REGEX]::Split($info,"  ")
					$total = $info[1]
					$copied = $info[2]
					$skipped = $info[3]
					$failed = $info[5]
					if ($total -match "k") { $total = $total.Replace(" k","") ; $total = [decimal]$total*1024 }
					elseif ($total -match "m") { $total = $total.Replace(" m","") ; $total = [decimal]$total*1048576 }
					elseif ($total -match "g") { $total = $total.Replace(" g","") ; $total = [decimal]$total*1073741824 }
					if ($copied -match "k") { $copied = $copied.Replace(" k","") ; $copied = [decimal]$copied*1024 }
					elseif ($copied -match "m") { $copied = $copied.Replace(" m","") ; $copied = [decimal]$copied*1048576 }
					elseif ($copied -match "g") { $copied = $copied.Replace(" g","") ; $copied = [decimal]$copied*1073741824 }
					if ($skipped -match "k") { $skipped = $skipped.Replace(" k","") ; $skipped = [decimal]$skipped*1024 }
					elseif ($skipped -match "m") { $skipped = $skipped.Replace(" m","") ; $skipped = [decimal]$skipped*1048576 }
					elseif ($skipped -match "g") { $skipped = $skipped.Replace(" g","") ; $skipped = [decimal]$skipped*1073741824 }
					if ($failed -match "k") { $failed = $failed.Replace(" k","") ; $failed = [decimal]$failed*1024 }
					elseif ($failed -match "m") { $failed = $failed.Replace(" m","") ; $failed = [decimal]$failed*1048576 }
					elseif ($failed -match "g") { $failed = $failed.Replace(" g","") ; $failed = [decimal]$failed*1073741824 }
					$row.Type = $info[0]
					$row.Total = $total
					$row.Copied = $copied
					$row.Skipped = $skipped
					$row.Failed = $failed
					$data += $row
				}
			}
		}
		
		$ftotal = 0
		$fcopied = 0
		$fskipped = 0
		$ffailed = 0
		$btotal = 0
		$bcopied = 0
		$bskipped = 0
		$bfailed = 0
		
		foreach ($line in $data) {
			if ($line.Type -eq "Files") {
				$ftotal += $line.Total
				$fcopied += $line.Copied
				$fskipped += $line.Skipped
				$ffailed += $line.Failed
			}
			if ($line.Type -eq "Bytes") {
				$btotal += $line.Total
				$bcopied += $line.Copied
				$bskipped += $line.Skipped
				$bfailed += $line.Failed
			}
		}
		
		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.User = $item.User
		$row.Source = [string]$source
		$row.Destination = $destination
		$row.Method = "RoboCopy"
		$row.Type = "Files"
		$row.Total = ("{0:N0}" -f $ftotal)
		$row.Copied = ("{0:N0}" -f $fcopied)
		$row.Skipped = ("{0:N0}" -f $fskipped)
		$row.Failed = ("{0:N0}" -f $ffailed)
		Set-Variable -Scope Script -Name report -Value ($report + $row)

		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.User = $item.User
		$row.Source = [string]$source
		$row.Destination = $destination
		$row.Method = "RoboCopy"
		$row.Type = "Bytes"
		$row.Total = ("{0:N0}" -f $btotal)
		$row.Copied = ("{0:N0}" -f $bcopied)
		$row.Skipped = ("{0:N0}" -f $bskipped)
		$row.Failed = ("{0:N0}" -f $bfailed)
		Set-Variable -Scope Script -Name report -Value ($report + $row)
	}
	else {
		$errMsg = "RoboCopy failed to run. Attempting to start the data copy using another method"
		Write-Host $errMsg
		
		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.User = $item.User
		$row.Source = [string]$source
		$row.Destination = $destination
		$row.Method = "RoboCopy"
		$row.Error = "0x00000001"
		$row.Note = $errMsg
		Set-Variable -Scope Script -Name report -Value ($report + $row)
		
		return CopyDataXCOPY $source $destination
	}
	return $true
}

function CopyDataXCOPY ($source,$destination) {
	$files = 0
	$bytes = 0
	[Void](gci $source -Recurse | ? { $_.Mode -notmatch "d" } | % { $files += 1 ; $bytes += $_.Length })

	if (Test-Path $destination) {
		$prefiles = 0
		$prebytes = 0
		[Void](gci $destination -Recurse | ? { $_.Mode -notmatch "d" } | % { $prefiles += 1 ; $prebytes += $_.Length })
	}
	
	$expression = "xcopy.exe `"" + $source + "`" `"" + $destination + "`" /E /C /I /F /G /H /R /K /Y /Z"
	$invoke = Invoke-Expression -Command $expression

	if (Test-Path $destination) {
		$postfiles = 0
		$postbytes = 0
		[Void](gci $destination -Recurse | ? { $_.Mode -notmatch "d" } | % { $postfiles += 1 ; $postbytes += $_.Length })
	
		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.User = $item.User
		$row.Source = [string]$source
		$row.Destination = $destination
		$row.Method = "xcopy"
		$row.Type = "Files"
		$row.Total = $files
		$row.Copied = ($postfiles - $prefiles)
		Set-Variable -Scope Script -Name report -Value ($report + $row)
	
		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.User = $item.User
		$row.Source = [string]$source
		$row.Destination = $destination
		$row.Method = "xcopy"
		$row.Type = "Bytes"
		$row.Total = $bytes
		$row.Copied = ($postbytes - $prebytes)
		Set-Variable -Scope Script -Name report -Value ($report + $row)
		return $true
	}
	else {
		$errMsg = "XCopy failed to run. Users home folder move haulted."
		Write-Host $errMsg
		
		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.User = $item.User
		$row.Source = [string]$source
		$row.Destination = $destination
		$row.Error = "0x00000001"
		$row.Note = $errMsg
		Set-Variable -Scope Script -Name report -Value ($report + $row)
		
		return $false
	}
}

function CopyDataPoSh ($source,$destination) {
	$source_folders = GCI $source
	foreach ($$source_folder in $source_folders) {
		$invoke = Copy-Item -Path $source_folder -Destination $destination -Recurse
	}
}

# ERRORS
# ----------------------------------------
# 0x00000001 - Data did not copy
# 0x00000002 - Home drive not set
# 0x00000003 - The system cannot find the path specified
# 0x00000005 - The user was not found in Active Directory
# 0x00000032 - The process cannot access the file because it is being used by another process

$report = @()
$list = Import-Csv $csv
$out = "Move-ADHome_" + (Get-Date -format "MM-dd-yy.HH.mm") + ".csv"

if (Test-Path "C:\Program Files\Microsoft Rich Tools\RichCopy 4.0\") {	
	foreach ($path in ($env:Path).Split(";")) {
		$test = "C:\Program Files\Microsoft Rich Tools\RichCopy 4.0\"
		if ($path -match "RichCopy") { $match = $true }
	}
	if (!$match) { $env:Path += ";C:\Program Files\Microsoft Rich Tools\RichCopy 4.0\" }
}
$localpath = ($env:Path).Split(";")

foreach ($folder in $localpath) {
	$folder = $folder.TrimEnd("\")
	$filetest = $folder + "\richcopy.exe"
	if (Test-Path $filetest) { $richcopy = $true }
}

foreach ($folder in $localpath) {
	$folder = $folder.TrimEnd("\")
	$filetest = $folder + "\robocopy.exe"
	if (Test-Path $filetest) { $robocopy = $true }
}

foreach ($folder in $localpath) {
	$folder = $folder.TrimEnd("\")
	$filetest = $folder + "\xcopy.exe"
	if (Test-Path $filetest) { $xcopy = $true }
}

$version = (Get-Host).Version

if ($version.Major -gt 1) { # in order for BITS to be utilized the user running this must be an administrator on the local server and PowerShell 2.0 installed.
	$file = "\\127.0.0.1\c$\temp\test.txt"
	$folder = "\\127.0.0.1\c$\temp\"
	if (Test-Path $file) { Remove-Item -Path $file -Force }
	if (!(Test-Path $folder)) { $createFolder = New-Item -Path $folder -ItemType directory }
	$createFile = New-Item -Path $file -ItemType file
	if ($createFile) { Import-Module FileTransfer
		$bitsTest = New-FileTransfer -ServerFileName $testFile -ClientFileNamePrefix "\\localhost\c$\temp\1\" -DisplayName "TEST"
		if ($bitsTest) { $bits = $true }
		Remove-Item -Path $file -Force
	}
}

foreach ($item in $list) {
	$user = GetUser $item.Domain $item.User
	if (!$user) {
		$errMsg = $item.User + " was not found in the " + $item.Domain + " domain."
		Write-Host $errMsg
		$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
		$row.User = $item.User
		$row.Source = [string]$source
		$row.Destination = $destination
		$row.Error = "0x00000005"
		$row.Note = $errMsg
		$report += $row
		break
	}
	else {
		[string]$userPath = $user.Path
		$user = [adsi]("$userPath")
		[Void]$error.Clear()
		
		if (!$item.Home) { $homeDir = $user.homeDirectory }
		else { $homeDir = $item.Home }
		$newHome = $item.NewHome
		if ($bits) { $copy = CopyDataBITS $homeDir $newHome $item.User}
		elseif ($richcopy) { $copy = CopyDataRICHCOPY $homeDir $newHome  }
		elseif ($robocopy) { $copy = CopyDataROBOCOPY $homeDir $newHome  }
		elseif ($xcopy) { $copy = CopyDataXCOPY $homeDir $newHome }
		else { $copy = CopyDataPoSh $homeDir $newHome }
		if ($copy) {
			if ([System.Convert]::ToBoolean($item.Change) {
				[Void]$Error.Clear()
				$user.homeDirectory = $newHome
				#$set = $user.SetInfo()
				if ($error) {
					$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
					$row.User = $item.User
					$row.Source = [string]$homeDir
					$row.Destination = $newHome
					$row.Error = "0x00000002"
					$report += $row
					[Void]$Error.Clear()
				}
				else {
					$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
					$row.User = $item.User
					$row.Source = [string]$homeDir
					$row.Destination = $newHome
					$row.Note = "Previous Home Directory: " + $user.homeDirectory
					$report += $row
				}
			}
			else {
				$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
				$row.User = $item.User
				$row.Source = [string]$homeDir
				$row.Destination = $newHome
				$row.Note = "Home Drive in Active Directory was not set to change"
				$report += $row
			}
		}
		else {
			$row = "" | Select User,Source,Destination,Method,Type,Total,Copied,Skipped,Failed,Error,Note
			$row.User = $item.User
			$row.Source = [string]$homeDir
			$row.Destination = $newHome
			$row.Error = "0x00000001"
			$report += $row
		}
	}
}

$report | Export-Csv $out -NoTypeInformation