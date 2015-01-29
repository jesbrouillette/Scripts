<#
	.SYNOPSIS 
		Sends BESR notifications
	
	.DESCRIPTION
		Send-BESRNotification.ps1 creates .csv files with Symantec Backup Executive System Recovery job status information.
		
		It reads in two CSV files and one TXT file containing information for computers to query and groups to notify.
	
	.PARAMETER file
		CSV file containing the server name and a single group or user to send notification to.  If no group/user is specified the report will go to the default values specified.
		
		The file shall be formatted as follows:
		
			Server,EmailNotify
			server1,user@mydomain.com
			server2,group@mydomain.com
			server3,
	
	.PARAMETER global
		TXT file containing a list of email addresses to send the full report to.  One email address is allowed per line.
	
	.PARAMETER out
		String containing the path and filename to which the full report will be saved.  This is emailed to all addresses listed in the global file.

	.INPUTS
		Create-ClassNotes.ps1 accepts named properties from the pipe.
	
	.OUTPUTS
		Create-ClassNotes.ps1 outputs a single file as specified in -out and generates emails as specified in the -global file and in the EmailNotify column of the -file CSV.
	
	.NOTES
		Name:       Send-BESRNotification.ps1
		Author:     Jes Brouillette
		Last Edit:  01/17/2010 20:15 CST
		Purpose:	Notify specified groups or users on Backup Exec System Recovery latest backup status
#>
param (
	[parameter(	Mandatory=$False,Position=0,ValueFromPipelineByPropertyName=$true)]
	[string]$file = "D:\AtJobs\CSC_SendBESRNotification\servers.csv",

	[parameter(	Mandatory=$False,Position=1,ValueFromPipelineByPropertyName=$true)]
	[string]$out = "\\adelkg054m\CSC\Reports\BESR\BESR_DR.csv",

	[parameter(	Mandatory=$False,Position=2,ValueFromPipelineByPropertyName=$true)]
	[string]$global = "D:\AtJobs\CSC_SendBESRNotification\global.txt"
)

Function email {
	param (
		[string]$attachment,
		[string]$to
	)
	
	# creates the attachment object with the file specified in $attachment
	$attach = New-Object Net.Mail.Attachment($attachment)
	
	# creates the mail message
	$msg = new-object Net.Mail.MailMessage

	# sets the properties of the mail message
	$msg.To.add($to)
	$msg.Attachments.Add($attach)
	$msg.From = "J_BROUILLETTE@CRGL-THIRDPARTY.COM"
	$msg.Subject = "DR BESR Report"
	$msg.Body = @"
BESR DR Report attached (BESR_DR.csv)

Please see the attached report on BESR jobs for DR servers and review the file for the following information:

The following settings need checked if the NeedsValidated column is TRUE:
BackupPath - Valid location and formatted as \\IP\Share\ServerName.
LastBackup - No older than 1 days
"@

	# sends the email
	$smtp.Send($msg)
	
	# releases the lock on the attachment file.  this is required as the file gets over-written several times.
	$attach.Dispose()
}

# xml object used for reading the .pqj file containing BESR information.
$xml = New-Object XML

# psobject with servers and custom email information
$list = Import-Csv $file

# removes all duplicate email addresses for quicker script execution later, and to consolidate email sendings to one per address.
$emails = $list | Select -Expand EmailNotify | Sort -Unique

# create the smpt client connection to the relay server.  done ouside of the SendEmail function to speed up script execution.
$smtp = new-object Net.Mail.SmtpClient("mailrelayapp.na.corp.cargill.com")

# create the data psobject with full report information
$data = $list | Sort Server | % {
	# create default values for queried information
	$Location = "unknown"
	$Drives = "unknown"
	$LastBackup = "unknown"
	$TestPath = $False

	# validate server connectivity
	if (Test-Connection $_.server -Count 1 -Quiet) {
		$server = $_.server
		
		# checks default location of the pqj file for server 2008.  records the folder location if validated.
		if (Test-Path "\\$server\C$\ProgramData") {
			$startFolder = "\\$server\C$\ProgramData\Symantec\Backup Exec System Recovery\Schedule\"
			$TestPath = $True
		}
		# checks default location of the pqj file for servers that have had a corrupted "All Users" folder.  records the folder location if validated.
		elseif (Test-Path "\\$server\C$\Documents and Settings\All Users.WINDOWS\Application Data\Symantec\Backup Exec System Recovery\Schedule") {
			$startFolder = "\\$server\C$\Documents and Settings\All Users.WINDOWS\Application Data\Symantec\Backup Exec System Recovery\Schedule\"
			$TestPath = $True
		}
		
		# checks default location of the pqj file for server 2003.  records the folder location if validated.
		elseif (Test-Path "\\$server\C$\Documents and Settings\All Users\Application Data\symantec\Backup Exec System Recovery\Schedule") {
			$startFolder = "\\$server\C$\Documents and Settings\All Users\Application Data\symantec\Backup Exec System Recovery\Schedule\"
			$TestPath = $True
		}
		
		# uses the validated folder location to parse through the pqj to gather BESR job information.
		if ($TestPath) {
		
			# filters the pqj files for the most recent job created.  as each job runs it updates the pqj file, meaning that the newest pqj is the most accurate and contains information for the latest backup.
			$config = Get-ChildItem $startFolder * | ? {$_.Name -like "*.pqj"} | Sort-Object LastWriteTime -descending | % {$_.FullName}
			
			# if multiple files are found, then the newest is selected, or loads the only file found.
			if ($config.Count) { $xml.Load($config[0]) }
			else { $xml.Load($config) }
            
			# backup location
			$Location = $xml.ImageJob.Location1.DisplayPath.Get_InnerText()
			
			# drives being backed up
			$Drives = $xml.imagejob | Get-Member | ? { $_.Name -match "volume" } | % { $_.Name } | % { $xml.imagejob.$_.Get_InnerText() }
			
			# most recent backup based on entries in the application event log created by BESR and containing the specified BESR job code of 6C8F1F7
			$LastBackup = [System.Management.ManagementDateTimeConverter]::ToDateTime(((gwmi -query "Select * from Win32_NTLogEvent WHERE LogFile='Application' AND SourceName='Backup Exec System Recovery' AND Message LIKE '%6C8F1F7%'" -computername $server | Sort TimeGenerated -Descending)[0].TimeGenerated))
		}
	}
	
	# as none of the information above is displayed, the default object must be passed through again
	$_

# create custom property outputs
# NeedsAction uses RegEx to determine the validity of specified character strings and the last backup date.
} | Select @{Name="Server";Expression={$_.server}},`
	@{Name="Drives";Expression={$Drives}},`
	@{Name="BackupPath";Expression={$Location}},`
	@{Name="LastBackup";Expression={$LastBackup}},`
	@{Name="ValidPath";Expression={Test-Path $Location}},`
	@{Name="NeedsAction";Expression={
		if (!(Test-Path $Location) -or `
			(($Location -notmatch "^\\\\\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\\[A-Z0-9_$]+\\[A-Z0-9_]+\\$")) -or `
			((New-Timespan $(get-date $LastBackup) $(get-date)).Days -gt 1)
		) {$true}
		else {$false}
	}},`
	@{Name="EmailNotify";Expression={$_.EmailNotify}}

# full report is exported to the file location specified in -out
$data | Export-CSV $out -noTypeInfo -Force

# the report is then emailed to each address in the -global param using the email function
gc $global | % { email $out $_ }

# filtered emails from on top are used to query the $data object
# each email address spawns a new csv in %TEMP% that is only used for the purpose of their email
# this processes then emails the custom file to the email address specified
$emails | % {
	$email = $_
	$tmpcsv = "$($env:TEMP)\BESR_DR.csv"
	$data | ? { $_.EmailNotify -match $email } | Select Server,Drives,BackupPath,LastBackup,ValidPath,NeedsAction | Export-Csv $tmpcsv -NoTypeInfo -Force
	email $tmpcsv $email
}

# remove the temporary csv file created for the custom email list
ri $tmpcsv -Force