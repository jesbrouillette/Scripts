param (
	[string]$server,
	[string]$drives,
	[string]$backuplocation,
	[string]$logfile,
	[string]$movegroup,
	[array]$notify
)

Write-Host "Server:" $server
Write-Host "Drives:" $drives
Write-Host "Backup Location:" $backuplocation
Write-Host "Log file:" $logfile
Write-Host "Move Group:" $movegroup
Write-Host "Notify:" $notify

$ErrorActionPreference = "Continue"

$star = @"
*:\
"@

$sLog = $logfile

function WriteLogs ($sServer,$sStatus,$oError) {
	$sNow = (Get-Date).ToString()

	if ($oError) {
		$ErrMsg = $oError.Exception.Message
		$msg = "$sServer,$sStatus,$ErrMsg,$sNow"
		$msg | Out-File $logfile -Append -Encoding ASCII
	}
	else {
		$msg = "$sServer,$sStatus,$sNow"
		$msg | Out-File $logfile -Append -Encoding ASCII
	}
	$error.Clear()
}

$sServerName = $server
$aDriveLetters = $drives
$sBackupLocation = $backuplocation

# Create Automation object on remote BESR agent
$oProtectorAuto = New-Object -ComObject Symantec.ProtectorAuto
$oProtectorAuto.Connect($sServerName)

if ($oProtectorAuto -and !$Error) {
	WriteLogs $sServerName "Connection using Symantec.ProtectorAuto"

	$oBackupLocations = @()
	[array]$aVolumes = ""
	
	foreach ($oVolume In $oProtectorAuto.Volumes($false)) {
		if ($oVolume.MountPoint -ne $star) {
			foreach ($sDriveLetter in $aDriveLetters) {
				$sVolume = (($sDriveLetter.ToString()).TrimEnd("\")).TrimEnd(":") + ":"
				$sMountPoint = ($oVolume.MountPoint).TrimEnd("\")
				if ($sVolume -match $sMountPoint) {
					$oRow = "" | Select Drive,VolumeID,BackupLocation
					$oRow.Drive = $sDriveLetter
					$oRow.BackupLocation = New-Object -ComObject Symantec.VProRecovery.NetworkLocation
					if (!$Error) {
					$sFileSpec = $sServerName + "_DCN-" + $movegroup + "_" + $sDriveLetter
						$oRow.BackupLocation.Path = $sBackupLocation
						$oRow.BackupLocation.FileSpec = $sFileSpec
						if (!$Error) {
							WriteLogs $sServerName ("Backup location for " + $sVolume + " set to " + $sBackupLocation + "\" + $sFileSpec + ".v2i")
							$oRow.VolumeID = $oVolume.ID
							$oBackupLocations += $oRow
							$aVolumes += $sVolume
						}
						else { WriteLogs $sServerName "Set backup location" $error[0] }
					}
					else { WriteLogs $sServerName "Create BESR backup location object" $error[0] }
				}
			}
		}
	}

	if ($oBackupLocations[0].Drive) {
		if ($aVolumes.Count -gt 1) { WriteLogs $sServerName ("Drives " + [string]::join("",($aVolumes)) + " configured") }
		else { WriteLogs ("Drive " + $aVolumes[0] + " configured") }
		
#		Pre Imaging script - If required
#		$oPREIMAGE = New-Object -ComObject Symantec.VProRecovery.CommandFile")
#		$oPREIMAGE.Timeout = 720
#		$oPREIMAGE.Name = "PREIMAGE"
#		$oPREIMAGE.Folder = "D:\Scripted-Tasks\BESR\"
#		$oPREIMAGE.Filename = "PreImage.bat"
#		$oPREIMAGE.Validate()
		
#		Post Snapshot script - If required
#		$oPOSTSNAP = New-Object -ComObject Symantec.VProRecovery.CommandFile")
#		$oPOSTSNAP.Timeout = 720
#		$oPOSTSNAP.Name = "POSTSNAP"
#		$oPOSTSNAP.Folder = ""D:\Scripted-Tasks\BESR\"
#		$oPOSTSNAP.Filename = "Postsnap.bat"
#		$oPOSTSNAP.Validate()
		
#		Post Imaging script - If required
#		$oPOSTIMAGE = New-Object -ComObject Symantec.VProRecovery.CommandFile")
#		$oPOSTIMAGE.Timeout = 720
#		$oPOSTIMAGE.Name = "POSTIMAGE"
#		$oPOSTIMAGE.Folder = "D:\Scripted-Tasks\BESR\"
#		$oPOSTIMAGE.Filename = "PostImage.bat"
#		$oPOSTIMAGE.Validate()
		
		# Create the image task
		$sDescription = "Full backups for DCN activities on drive(s) " + [string]::Join(",",$aDriveLetters) + " for DCN moves"
		$sStartDate = Get-Date (Get-Date).ToUniversalTime() -format "M/d/yyyy H:mm:ss"
		$oTask = New-Object -ComObject Symantec.Scheduler.Task
		$oTask.Description = $sDescription
		$oTask.StartDateTime = $sStartDate
		$oTask.RepeatInterval = $oTask.Constants.IntervalNone
		$oTask.Validate()
		
		# Create the image job
		$oImageJob = New-Object -ComObject Symantec.VProRecovery.ImageJob
		if ($oImageJob) {
			WriteLogs $sServerName "ImageJob instance created successfully"
			$oImageJob.IncrementalSupport = $False
			$oImageJob.DisplayName = $sDescription
			$oImageJob.Description = $sDescription
			$oImageJob.Compression = $oImageJob.Constants.ImageCompressionNone
			$oImageJob.Reason = $oImageJob.Constants.ImageReasonManual
			$oImageJob.Type = $oImageJob.Constants.ImageTypeFull
			$oImageJob.Task = $oTask
			$oImageJob.Volumes = $aVolumes
			$oImageJob.Quota = 0
			$oImageJob.RunOnce = $True
			foreach ($oBackupLocation in $oBackupLocations) {
				$oImageJob.Location($oBackupLocation.VolumeID) = $oBackupLocation.BackupLocation
			}
			
#			Additional imaging job options - If required
#			$oImageJob.Compression = oImageJob.Constants.ImageCompressionLow
#			$oImageJob.Compression = oImageJob.Constants.ImageCompressionMedium
#			$oImageJob.Compression = oImageJob.Constants.ImageCompressionHigh
#			$oImageJob.CommandFile("PREIMAGE") = $oPREIMAGE
#			$oImageJob.CommandFile("POSTSNAP") = $oPOSTSNAP
#			$oImageJob.CommandFile("POSTIMAGE") = $oPOSTIMAGE
			
			if (!$Error[0]) {
				WriteLogs $sServerName "ImageJob settings creation"
				
				# Add the image job to jobs list
				$oProtectorAuto.AddImageJob($oImageJob)
				
				if (!$Error[0]) {
					WriteLogs $sServerName "ImageJob added"
		
					# Execute the image job
					[Void]$oProtectorAuto.DoImageJob($oImageJob.ID, $oImageJob.Constants.ImageTypeFull)
					
					if (!$Error[0]) { WriteLogs $sServerName "DoImageJob launched" }
					else { WriteLogs $sServerName "DoImageJob failed" $error[0] }
				}
				else { WriteLogs $sServerName "ImageJob add" $error[0] }
			}
			else { WriteLogs $sServerName "ImageJob settings creation" $error[0] }
		}
		else { WriteLogs $sServerName "ImageJob instance creation using Symantec.VProRecovery.ImageJob" $error[0] }
	}
	else { WriteLogs $sServerName "No valid backup drives in list" "No Valid backup drives in list" }
}
else { WriteLogs $sServerName "Connection using Symantec.ProtectorAuto" $error[0] }

$smtpServer = "mailrelayapp.na.corp.cargill.com"
$subject = "Automated Besr Backup for DCN Moves"
$body = "Backups completed on " + $server + " for drive(s) " + $drives + " to " + $backuplocation + ".  Please validate."
$priority = "High"

$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$msg = new-object System.Net.Mail.MailMessage 

foreach ($address in $notify) { $address ; $msg.To.Add($address) }

$msg.From = $notify[0]
$msg.Subject = $subject
$msg.Body = $body
$msg.Priority = $priority

$smtp.Send($msg)