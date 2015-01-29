$erroractionpreference = "SilentlyContinue"
$Start = Get-Date
Write-Host "Started:" $Start.ToString()
$farm = new-Object -com "MetaframeCOM.MetaframeFarm"
$farm.Initialize(1)
$OutFile = "CTXFarm-Props.csv"
$Reported = 0
$Apps = 0

$AppsTable = New-Object system.Data.DataTable "AppsTable" # Setup the Datatable Structure
$col1 = New-Object system.Data.DataColumn Application,([string])
$col2 = New-Object system.Data.DataColumn Groups,([string])
$col3 = New-Object system.Data.DataColumn Users,([string])
$col4 = New-Object system.Data.DataColumn Servers,([string])

$AppsTable.columns.add($col1)
$AppsTable.columns.add($col2)
$AppsTable.columns.add($col3)
$AppsTable.columns.add($col4)

$Applications = $farm.Applications
Foreach($App in $Applications) {
	$Apps += 1
}
Foreach($App in $Applications) {
	if ($farm.FarmName -match "cps_farm") {
		$App.LoadData($True)
	}

	$Reported += 1
	
	$AppName = $App.BrowserName

	$Groups = $App.Groups
	Foreach($Group in $Groups) {
		$GroupNames = $GroupNames + $Group.AAName + "\" + $Group.GroupName + ";"
	}
	
	$Users = $App.Users
	foreach($User in $Users) {
		$UserNames = $UserNames + $User.AAName + "\" + $User.UserName + ";"
	}
	
	$Servers = $App.Servers
	Foreach($Server in $Servers) {
		$ServerNames = $Server.ServerName

		$row = $AppsTable.NewRow()
		$row.Application = $AppName
		$row.Groups = $GroupNames
		$row.Users = $UserNames
		$row.Servers = $ServerNames
		$AppsTable.Rows.Add($row)
	}
	
	if (($Reported % 15) -eq 0 -or $Reported -eq $Apps -and $Reported -ne 0) {
		Write-Host " " $Reported "of" $Apps "Apps reported"
	}
	$GroupNames = ""
	$UserNames = ""
	$ServerNames = ""
}

$AppsTable | Export-Csv $OutFile -NoTypeInformation
$End = Get-Date
Write-Host "Finished:" $End.ToString()
Write-Host "Runtime:" ($End - $Start)