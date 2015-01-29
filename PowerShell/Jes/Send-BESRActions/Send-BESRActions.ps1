$in = "\\adelkg054m\CSC\Reports\BESR\CSC BESR Backup Info.csv"
$out = "BESR_Actions.csv"
$to = "J_BROUILLETTE@CRGL-THIRDPARTY.COM","CHRIS_MINCKS@CRGL-THIRDPARTY.COM","KEVIN_ROBINSON@CRGL-THIRDPARTY.COM"

import-csv $in | Select `
	@{Name="Server";Expression={$_."Computer Name"}},
	@{Name="BackupPath";Expression={$_.BackupPath}},
	@{Name="ValidPath";Expression={Test-Path $_.BackupPath}},
	@{Name="LastBackup";Expression={
		if ($_.FullBackup -and $_.IncrementalBackup) {
			if ($_.FullBackup -gt $_.IncrementalBackup) {$_.FullBackup}
			else {$_.IncrementalBackup}
		}
		elseif ($_.FullBackup) {$_.FullBackup}
		elseif ($_.IncrementalBackup) {$_.IncrementalBackup}
		else {"1/1/2000 12:00:00 AM"}
	}},
	@{Name="NextBackup";Expression={
		if ($_.NextBackupTime) {$_.NextBackupTime}
		else {"1/1/2000 12:00:00 AM"}
	}} `
| Select Server,BackupPath,ValidPath,LastBackup,NextBackup,`
	@{Name="NeedsAction";Expression={
		if (!$_.ValidPath -or `
			($_.BackupPath -notmatch "^\\\\\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\\[A-Z0-9_]+\\[A-Z0-9_]+$") -or `
			((New-Timespan $(get-date $_.LastBackup) $(get-date)).Days -gt 3)
		) {$true}
		else {$false}
	}} `
| Sort NeedsAction -descending | Export-CSV $out -noTypeInfo -force

Exit

$smtp = new-object Net.Mail.SmtpClient("mailrelayapp.na.corp.cargill.com")
$msg = new-object Net.Mail.MailMessage
$attach = New-Object Net.Mail.Attachment($out)
	
$to | % { $msg.To.Add($_) }
$msg.From = "J_BROUILLETTE@CRGL-THIRDPARTY.COM"
$msg.Subject = "BESR Age Report"
$msg.Body = @"
BESR Action Report attached (BESR_Actions.csv)

Please see \\adelkg054m\CSC\Reports\BESR for more.
"@

$msg.Attachments.Add($attach)

$smtp.Send($msg)

$attach.Dispose()