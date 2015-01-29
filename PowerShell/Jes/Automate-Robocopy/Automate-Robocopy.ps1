param (
	[string]$csv, #csv with source and destination
	[switch]$console, #same as /TEE in robocopy
	[switch]$whatif #same as /L in robocopy
)

$log = "C:\Temp\DataMigration\RoboCopy" + (Get-Date -format "MM-dd-yy.HH.mm.ss") + ".log"
$errorLog = "C:\Temp\DataMigration\RoboCopy" + (Get-Date -format "MM-dd-yy.HH.mm.ss") + ".err"

Write-Output "Started: " + (get-date).ToString() + " by " + $env:USERDOMAIN + "\" + $env:USERNAME + "
"| Out-File $log -Encoding ASCII -Append

if ($csv) { $list = Import-Csv $csv }
else { $list = Import-Csv "folders.csv" }

foreach ($item in $list) {
	foreach ($old in $list) {
		if ($old.old -ne $item.old) {
			$path = ($old.old).TrimEnd("\")
			$exclude = $exclude + " `"" + $Path + "`""
		}
	}
	$source = ($item.old).TrimEnd("\")
	$destination = ($item.new).TrimEnd("\")
	$expression = "robocopy.exe `"" + $source + "`" `"" + $destination + "`" /E /COPY:DAT /V /LOG+:$log"
	if ($console) { $expression = $expression + " /TEE" }
	if ($whatif) { $expression = $expression + " /L" }
	$expression = $expression + " /XD " + $exclude
	if ($console) { Write-Host $expression `n }
	Write-Output $expression `n | Out-File $log -Encoding ASCII -Append
	Invoke-Expression -Command $expression -ErrorVariable RoboErr
	if ($RoboErr) { $RoboError | Out-File $errorLog -Encoding ASCII }
	rv exclude
}

#begin report validation

Write-Output "
Copy Finished:" + (get-date).ToString() + "
------------------------------------------------------------------------------
Report Validation
" | Out-File $log -Encoding ASCII -Append

$list = Get-Content $log | ? {$_ -match "Dirs :" -or $_ -match "Files :" -or $_ -match "Bytes :"}
$data = @()
foreach ($line in $list) {
	$row = "" | Select Type,Total,Copied,Skipped,Mismatch,FAILED,Extras
	if ($line -match "Dirs :" -and $line -notmatch " Exc") {
		$info = $line
		do { $info = [REGEX]::Replace($info,"   ","  ") } until ($info -notmatch "   ")
		$info = $info.Replace("  Dirs :","Dirs")
	}
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
		$mismatch = $info[4]
		$failed = $info[5]
		$extras = $info[6]
		if ($total -match "k") { $total = $total.Replace(" k","") ; $total = [decimal]$total*1024 }
		elseif ($total -match "m") { $total = $total.Replace(" m","") ; $total = [decimal]$total*1048576 }
		elseif ($total -match "g") { $total = $total.Replace(" g","") ; $total = [decimal]$total*1073741824 }
		if ($copied -match "k") { $copied = $copied.Replace(" k","") ; $copied = [decimal]$copied*1024 }
		elseif ($copied -match "m") { $copied = $copied.Replace(" m","") ; $copied = [decimal]$copied*1048576 }
		elseif ($copied -match "g") { $copied = $copied.Replace(" g","") ; $copied = [decimal]$copied*1073741824 }
		if ($skipped -match "k") { $skipped = $skipped.Replace(" k","") ; $skipped = [decimal]$skipped*1024 }
		elseif ($skipped -match "m") { $skipped = $skipped.Replace(" m","") ; $skipped = [decimal]$skipped*1048576 }
		elseif ($skipped -match "g") { $skipped = $skipped.Replace(" g","") ; $skipped = [decimal]$skipped*1073741824 }
		if ($mismatch -match "k") { $mismatch = $mismatch.Replace(" k","") ; $mismatch = [decimal]$mismatch*1024 }
		elseif ($mismatch -match "m") { $mismatch = $mismatch.Replace(" m","") ; $mismatch = [decimal]$mismatch*1048576 }
		elseif ($mismatch -match "g") { $mismatch = $mismatch.Replace(" g","") ; $mismatch = [decimal]$mismatch*1073741824 }
		if ($failed -match "k") { $failed = $failed.Replace(" k","") ; $failed = [decimal]$failed*1024 }
		elseif ($failed -match "m") { $failed = $failed.Replace(" m","") ; $failed = [decimal]$failed*1048576 }
		elseif ($failed -match "g") { $failed = $failed.Replace(" g","") ; $failed = [decimal]$failed*1073741824 }
		if ($extras -match "k") { $extras = $extras.Replace(" k","") ; $extras = [decimal]$extras*1024 }
		elseif ($extras -match "m") { $extras = $extras.Replace(" m","") ; $extras = [decimal]$extras*1048576 }
		elseif ($extras -match "g") { $extras = $extras.Replace(" g","") ; $extras = [decimal]$extras*1073741824 }
		$row.Type = $info[0]
		$row.Total = $total
		$row.Copied = $copied
		$row.Skipped = $skipped
		$row.Mismatch = $mismatch
		$row.FAILED = $failed
		$row.Extras = $extras
		$data += $row
	}
}

$dTotal = 0
$dCopied = 0
$dSkipped = 0
$dMismatch = 0
$dFailed = 0
$dExtras = 0

$fTotal = 0
$fCopied = 0
$fSkipped = 0
$fMismatch = 0
$fFailed = 0
$fextras = 0

$bTotal = 0
$bCopied = 0
$bSkipped = 0
$bMismatch = 0
$bFailed = 0
$bExtras = 0

foreach ($line in $data) {
	if ($line.Type -eq "Dirs") {
		$dTotal += $line.Total
		$dCopied += $line.Copied
		$dSkipped += $line.Skipped
		$dMismatch += $line.Mismatch
		$dFailed += $line.FAILED
		$dExtras += $line.Extras
	}
	if ($line.Type -eq "Files") {
		$fTotal += $line.Total
		$fCopied += $line.Copied
		$fSkipped += $line.Skipped
		$fMismatch += $line.Mismatch
		$fFailed += $line.FAILED
		$fextras += $line.Extras
	}
	if ($line.Type -eq "Bytes") {
		$bTotal += $line.Total
		$bCopied += $line.Copied
		$bSkipped += $line.Skipped
		$bMismatch += $line.Mismatch
		$bFailed += $line.FAILED
		$bExtras += $line.Extras
	}
}

if ($bTotal -ge 1 -and $bTotal -le 10484711424) { $bTotal = ($bTotal/1mb).ToString("###,###,###.##") + " m" }
elseif ($bTotal -ge 1) { $bTotal = ($bTotal/1gb).ToString("###,###,###.##") + " g" }
elseif ($bTotal -eq 0) { $bTotal = "0" }
else { $bTotal = "unknown" }

if ($bCopied -ge 1 -and $bCopied -le 10484711424) { $bCopied =($bCopied/1mb).ToString("###,###,###.##") + " m" }
elseif ($bCopied -ge 1) { $bCopied =($bCopied/1gb).ToString("###,###,###.##") + " g" }
elseif ($bCopied -eq 0) { $bCopied = "0" }
else { $bCopied = "unknown" }

if ($bSkipped -ge 1 -and $bSkipped -le 10484711424) { $bSkipped = ($bSkipped/1mb).ToString("###,###,###.##") + " m" }
elseif ($bSkipped -ge 1) { $bSkipped = ($bSkipped/1gb).ToString("###,###,###.##") + " g" }
elseif ($bSkipped -eq 0) { $bSkipped = "0" }
else { $bSkipped = "unknown" }

if ($bMismatch -ge 1 -and $bMismatch -le 10484711424) { $bMismatch = ($bMismatch/1mb).ToString("###,###,###.##") + " m" }
elseif ($bMismatch -ge 1) { $bMismatch = ($bMismatch/1gb).ToString("###,###,###.##") + " g" }
elseif ($bMismatch -eq 0) { $bMismatch = "0" }
else { $bMismatch = "unknown" }

if ($bFailed -ge 1 -and $bFailed -le 10484711424) { $bFailed = ($bFailed/1mb).ToString("###,###,###.##") + " m" }
elseif($bFailed -ge 1) { $bFailed = ($bFailed/1gb).ToString("###,###,###.##") + " g" }
elseif ($bFailed -eq 0) { $bFailed = "0" }
else { $bFailed = "unknown" }

if ($bExtras -ne 0 -and $bExtras -lt 10484711424) { $bExtras = ($bExtras/1mb).ToString("###,###,###.##") + " m" }
elseif ($bExtras -ne 0) { $bExtras = ($bExtras/1gb).ToString("###,###,###.##") + " m" }
elseif ($bExtras -eq 0) { $bExtras = "0" }
else { $bExtras = "unknown" }

$totals =  @()

$row = "" | Select Type,Total,Copied,Skipped,Mismatch,FAILED,Extras
$row.Type = "Dirs"
$row.Total = $dTotal
$row.Copied = $dCopied
$row.Skipped = $dSkipped
$row.Mismatch = $dMismatch
$row.Failed = $dFailed
$row.Extras = $dExtras
$totals += $row

$row = "" | Select Type,Total,Copied,Skipped,Mismatch,FAILED,Extras
$row.Type = "Files"
$row.Total = $fTotal
$row.Copied = $fCopied
$row.Skipped = $fSkipped
$row.Mismatch = $fMismatch
$row.Failed = $fFailed
$row.Extras = $fExtras
$totals += $row

$row = "" | Select Type,Total,Copied,Skipped,Mismatch,FAILED,Extras
$row.Type = "Bytes"
$row.Total = $bTotal
$row.Copied = $bCopied
$row.Skipped = $bSkipped
$row.Mismatch = $bMismatch
$row.Failed = $bFailed
$row.Extras = $bExtras
$totals += $row

$totals | Format-Table | Out-File $log -Encoding ASCII -Append

rv list
rv data
rv totals
rv row

Write-Output "
Completed: " + (get-date).ToString() + "
"| Out-File $log -Encoding ASCII -Append