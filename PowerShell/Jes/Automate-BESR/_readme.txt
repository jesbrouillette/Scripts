================================================================================
Instructions for running the BESR automated backups for DCN Activities.

This process consists of three files:
Spawn-BESR.ps1 		- PowerShell script
Automate-BESR.ps1	- PowerShell script
list.csv		- CSV file with information on creating the backups

Requirements:
1.) Scripting must be enabled on PowerShell:
 - To Check run "Get-ExecutionPolicy".  If this returns anything other than 
   "RemoteSigned" run "Set-ExecutionPolicy RemoteSigned" and say "Yes"

2.) BESR 7.1 or newer must be on the computer/server the scripts are executed
    from

3.) list.csv format:
	server,drives,backuplocation,movegroup,notify
	%SERVERNAME%,%DRIVE_TO_BACKUP%,%BACKUP_TO%,%MOVEGROUP%,%EMAIL%
 - The Notify column can contain multiple email address to send notification to.
   These must be seperated by comma's and the entire column surrounded by quotes.
	Example:
	"email1@domain.com,email1@domain.com"

Usage:
.\Spawn-BESR.ps1 list.csv

This will create multiple windows (one for each line in list.csv) and monitor
them in the origional window.  Every 15 seconds the origional window will
refresh showing the latest status of the other windows.  A log file in CSV
format is also generated with the unique time stamp from when the script was
launched using the format "Automate-BESR_MONTH_DAY_YEAR_HOUR.MINUTE.SECOND.csv"
(eg Automate-BESR_11-16-09_12.30.32.csv).  Each spawned process will write to
this log file for all activities.  Once all jobs are completed the main window
will show Completed as True and CompletedTime will be populated for each
instance.