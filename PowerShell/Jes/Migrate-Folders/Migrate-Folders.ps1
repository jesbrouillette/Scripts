
param (
	[string]$mapping,
	[string]$logpath = "C:\AtJobs\Migration",
	[switch]$afterhours,
	[switch]$help
)

# Function to create a new .zip file.
function New-Zip {
	param (
		[string]$zipfilename
	)
	# Creates a .zip file with content identifying it as a compressed file within Windows.
	set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
	(dir $zipfilename).IsReadOnly = $false
}

#  Function to add data to a .zip file.
function Add-Zip {
	param (
		[string]$file,
		[string]$zipfilename
	)
	Start-Sleep -Seconds 1

	if (!(test-path $zipfilename)) {
		New-Zip $zipfilename
	}
	
	$shellApplication = new-object -com shell.application
	$zipPackage = $shellApplication.NameSpace($zipfilename)

	$zipPackage.CopyHere($file,4)
	Start-Sleep -Seconds 1
}

if ($help) {
@"
	.SYNOPSIS 
		Migrates data utilizing RoboCopy with input from a csv file.
	
	.DESCRIPTION
		Migrate-Folders.ps1 migrates data utilizing RoboCopy with input from a csv file.
		
		It is set with a standard list of RoboCopy options with the ability to specify the jobs to only run during off-hours times.
		
		RoboCopy will run with the following options:
			/E :: copy subdirectories, including Empty ones.
			/ZB :: use restartable mode; if access denied use Backup mode.
			/COPY:DAT :: copy flags for Data, Attributes, and Timestamp and not copying NTFS security.
		/PURGE :: delete dest files/dirs that no longer exist in source.
		/RH:1800-0600 :: Run Hours - times when new copies may be started.  This is only used when -afterhours is specified.
		/PF :: check run hours on a Per File (not per pass) basis.
		/XD $excludes :: eXclude Directories matching given names/paths.  Includes all Source folders in the csv.
		/R:3 :: 3 Retries on failed copies.
		/W:3 :: Wait 3 seconds between retries.
		/V :: produce Verbose output, showing skipped files.
		/FP :: include Full Pathname of files in the output.
		/NP :: No Progress - don't display percentage copied.  This allows the log files to be reduced in size when large files are copied, or a slow link is used.
		/LOG+:$thislog :: output status to LOG file (append to existing log).  The file name is determined per line to provide easier parsing of the logs.
		/TEE :: output to console window, as well as the log file, for manual monitoring of the job progress.
		
	.PARAMETER mapping
		The CSV file needed with the exact migration paths.
	
	.PARAMETER logpath
		The folder path for the log file to be stored.  It will default to C:\AtJobs\Migration if not specified.
	
	.PARAMETER afterhours
		A switch that causes RoboCopy to only function between 6:00 PM and 6:00 AM local server time.
	
	.INPUTS
		Migrate-Folders.ps1 accepts named properties from the pipe.
	
	.OUTPUTS
		Migrate-Folders.ps1 outputs a single .zip file with multiple RoboCopy log files files as specified in -logpath.
	
	.EXAMPLE
		PoSh:\> .\Migrate-Folders.ps1 -mapping mapping.csv
		Folders will be migrated according the the mapping.csv file and a log created in C:\AtJobs\Migration during all hours.
	
	.EXAMPLE
		PoSh:\> .\Migrate-Folders.ps1 -mapping mapping.csv -logpath D:\Migrations -afterhours
		Folders will be migrated according the the mapping.csv file and a log created in D:\Migrations only between 6:00 PM and 6:00 AM.
	
	.EXAMPLE
	
		C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe -command "& {C:\AtJobs\Migration\Migrate-Folders.ps1 -mapping C:\AtJobs\Migration\mapping.csv -afterhours}"
		An example of the required command for utilizing a Scheduled Task.
	
	.NOTES
		Name:       Migrate-Folders.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  07/05/2011 09:15 CST
		Purpose:	Automated data migrations
"@
	exit
}

$map = Import-Csv $mapping
$ziplog = "{0}\MigrationLogs-{1}.zip" -f $logpath,(Get-Date -Format dd_MM_yy)
$logs = @()
$date = Get-Date -Format dd_MM_yy-HH_mm
$exclude = $map | Select -ExpandProperty Exclude

foreach ($path in $map) {
	$excludes = $exclude
	$path.Exclude.Split(";") | % { $exclude += "`"$_`"" }
	
	if ($afterhours) {
		$thislog = "{0}\{1}_{2}_{3}_AfterHours-{4}.log" -f $logpath,$path.Future.Split("\")[2],$path.Department,$path.Future.Split("\")[4],$date
		$logs += $thislog
		robocopy $path.Current $path.Future /E /ZB /COPY:DAT /PURGE /RH:1800-0600 /XD $excludes /PF /R:3 /W:3 /V /FP /NP /LOG+:$thislog /TEE
	}
	else {
		$thislog = "{0}\{1}_{2}_{3}-{4}.log" -f $logpath,$path.Future.Split("\")[2],$path.Department,$path.Future.Split("\")[4],$date
		$logs += $thislog
		robocopy "$($path.Current)" "$($path.Future)" /E /ZB /COPY:DAT /PURGE /XD $excludes /PF /R:3 /W:3 /V /FP /NP /LOG+:$thislog /TEE
	}
}

foreach ($log in $logs) {
	Add-Zip $log $ziplog
	ri $log -Force
}