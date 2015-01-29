Function New-Zip {
	Param ($zipFile)
	if (-not $ZipFile.EndsWith('.zip')) {$ZipFile += '.zip'} 
	set-content $ZipFile ("PK" + [char]5 + [char]6 + ([string][char]0) * 18)
} # A 22 character header marks a file as a ZIP file. The the code below adds files to it. 

[System.Int32]$yesToAll = 16
$ZipFile = "C:\temp\2.zip"

if (-not $ZipFile.EndsWith('.zip')) {
	$ZipFile += '.zip'
} 
if (-not (test-path $Zipfile)) {
	new-zip $ZipFile
} 

Get-ChildItem "c:\temp\2" | foreach {
	$_.fullname
}
#exit

Get-ChildItem "c:\temp\2" | foreach {
	$_.path
	$ZipObj = (new-object -com shell.application).NameSpace(((resolve-path $ZipFile).path))
	if($_ -is [String]) {
		$zipObj.CopyHere((resolve-path $_).path,$yesToAll)
	}
	elseif (($file -is [System.IO.FileInfo]) -or ($_ -is [System.IO.DirectoryInfo]) ) {
		$zipObj.CopyHere($_.fullname,$yesToAll)
	}
	$files = $null
}