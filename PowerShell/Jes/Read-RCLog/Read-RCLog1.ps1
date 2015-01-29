Write-Host "
Started:" (get-date).ToString() "by" $env:USERDOMAIN"\"$env:USERNAME"

Gathering contents from" $args[0] "
"

$list = Get-Content $args[0]
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

if ($bTotal -ne 0) { $bTotal = ($bTotal / 1mb).ToString("###,###,###.##") + " m" }
else { $bTotal = "0" }
if ($bCopied -ne 0) { $bCopied =($bCopied/1mb).ToString("###,###,###.##") + " m" }
else { $bCopied = "0" }
if ($bSkipped -ne 0) { $bSkipped = ($bSkipped/1mb).ToString("###,###,###.##") + " m" }
else { $bSkipped = "0" }
if ($bMismatch -ne 0) { $bMismatch = ($bMismatch/1mb).ToString("###,###,###.##") + " m" }
else { $bMismatch = "0" }
if ($bFailed -ne 0) { $bFailed = ($bFailed/1mb).ToString("###,###,###.##") + " m" }
else { $bFailed = "0" }
if ($bExtras -ne 0) { $bExtras = ($bExtras/1mb).ToString("###,###,###.##") + " m" }
else { $bExtras = "0" }

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

$totals | Format-Table

Write-Host "Completed:" (get-date).ToString() "
"