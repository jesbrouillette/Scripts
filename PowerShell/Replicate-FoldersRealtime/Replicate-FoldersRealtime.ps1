param (
	[string]$googledrive,	#Google Drive storage folder
	[string]$dropbox		#Drop Box storage folder
)

function CopyData {
	param (
		[string]$source,		#File copy source
		[string]$destination,	#File copy destination
	)
	gci $source -Recurse | ? {
		$_.LastWriteTime -gt (Get-Date).AddSeconds("-5")
	} | % {
		$file = $_
		$newfolder = $file.DirectoryName -replace $source $destination
		if (Test-Path $newpath) { New-Item $newpath -ItemType Directory }
		Copy-Item $file $newpath
	}
}

function RegisterWMIEvents {
	param (
		[string]$gDrive,
		[string]$dropB
	)
	
	$queryPath = $source -replace "\\","\\\\"
	
	$query = @"
SELECT * FROM __InstanceCreationEvent WITHIN 10 WHERE
targetInstance ISA 'Cim_DirectoryContainsFile' AND
targetInstance.GroupComponent = 'Win32_Directory.Name="{0}"'
"@ -f $queryPath
	
	# Google --> DropBox :: New file copy
	Register-WMIEvent -query $query -sourceidentifier "DriveBox_Sync" -action {
		$event = Get-PSEvent -sourceIdentifier "DriveBox_Sync"
		
		if ($event.Count) { $fileEvent = $event.SourceEventArgs.NewEvent.TargetInstance.PartComponent }
		
		$fileDrive = $fileEvent.Drive
		$filePath = $fileEvent.Path
		$fileName = $fileEvent.Name
		$fileExt = $fileEvent.Extension
		
		$fullPath = "{0}{1}{2}.{3}" -f $fileDrive,$filePath,$fileName,$fileExt
		$parentPath = Split-Path $fullPath.PATH
		
		$destinationFolder = $destination
		CopyData -source $source -destination $destination
	}

	# Google --> DropBox :: File change copy
	Register-WMIEvent -query "select * from __instancecreationevent within 30 where targetinstance isa 'cim_directorycontainsfile' and targetinstance.groupcomponent=`"win32_directory.name='c:\\temp'`"" -sourceidentifier "New File" -action {eventcreate /id 1000 /t information /l application /d "A new file was created."}

	# DropBox --> Google :: New file copy
	Register-WMIEvent -query "select * from __instancecreationevent within 30 where targetinstance isa 'cim_directorycontainsfile' and targetinstance.groupcomponent=`"win32_directory.name='c:\\temp'`"" -sourceidentifier "New File" -action {eventcreate /id 1000 /t information /l application /d "A new file was created."}

	# DropBox --> Google :: File change copy
	Register-WMIEvent -query "select * from __instancecreationevent within 30 where targetinstance isa 'cim_directorycontainsfile' and targetinstance.groupcomponent=`"win32_directory.name='c:\\temp'`"" -sourceidentifier "New File" -action {eventcreate /id 1000 /t information /l application /d "A new file was created."}

}

function UnregisterWMIEvents {

}

$drive
$path
$filename
$extension
