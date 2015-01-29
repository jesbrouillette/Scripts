#
# Data to capture:
# Full Name, SAMName, BU, Platform, Email, Phone Number, HomeDir
#

function Set-ADSIRoot ($strDomainF) {# sets the correct ADSI container for each domain
	if ($strDomainF.ToLower() -eq "ap"){
		return "dc=ap,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "eu"){
		return "dc=eu,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "la"){
		return "dc=la,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "meat"){
		return "dc=meat,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "na"){
		return "dc=na,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "corp"){
		return "dc=corp,dc=cargill,dc=com"
	}
	else {
		return "no ADSI path found"
	}
} # end Set-ADSIRoot function

function Get-Domain ($ADSIRootPathF) { # sets the correct domain for the given adsi path
	if ($ADSIRootPathF -match "dc=ap") {
		return "ap"
	}
	elseif ($ADSIRootPathF -match "dc=eu") {
		return "eu"
	}
	elseif ($ADSIRootPathF -match "dc=la") {
		return "la"
	}
	elseif ($ADSIRootPathF -match "dc=na") {
		return "na"
	}
	elseif ($ADSIRootPathF -match "dc=meat") {
		return "meat"
	}
	else {
		return "corp"
	}
} # end Get-Domain function

$Users = Import-Csv -Path users.csv
$ScriptDir = Split-Path ((Get-Variable MyInvocation -Scope 1).Value).MyCommand.Path
$OutFile = $ScriptDir + "\HomeDirs.csv"
$LogFile = $ScriptDir + "\HomeDir.log"

$Table = New-Object system.Data.DataTable "Full DataTable" # Setup the Datatable Structure
$col1 = New-Object system.Data.DataColumn FullName,([string])
$col2 = New-Object system.Data.DataColumn SAMName,([string])
$col3 = New-Object system.Data.DataColumn BU,([string])
$col4 = New-Object system.Data.DataColumn Platform,([string])
$col5 = New-Object system.Data.DataColumn Email,([string])
$col6 = New-Object system.Data.DataColumn Phone,([string])
$col7 = New-Object system.Data.DataColumn HomeDir,([string])

$Table.columns.add($col1)
$Table.columns.add($col2)
$Table.columns.add($col3)
$Table.columns.add($col4)
$Table.columns.add($col5)
$Table.columns.add($col6)
$Table.columns.add($col7)

foreach ($User in $Users) {
	$Domain = [string]$User.domain -replace "`t","" -replace " ",""
	$ADSIRoot = Set-ADSIRoot $User.Domain
	
	if ($ADSIRoot -eq "no ADSI path found") {
		$Log = "The domain is incorrect for " + $User.user
		$Log | Out-File $LogFile -Append
	}
	else {
		$Root = [ADSI]("LDAP://$ADSIRoot")
		$Search = new-object System.DirectoryServices.DirectorySearcher
		$Search.SearchRoot = $Root
		$Search.Filter = "(&(objectCategory=`"user`")(sAMAccountName=$User.User))"
		$FoundUsers = $Search.findall()
		if ($FoundUsers.length -gt 1) {
			$FoundUser = $FoundUsers[0]
		}
		else {
			$FoundUser = $FoundUsers
		}
		
		if ($FoundUser.Path -eq $null) {
			$Log = "`"" + $User.domain + "\" + $User.User + "`" was not found"
			$Log | Out-File $LogFile -Append
		}
		else {
			$UserSettings = [ADSI]("$FoundUser.Path")
			$Logon  = (([string]$UserSettings.userPrincipalName).split("@"))[0]
			$Domain = $User.Domain
			
			$TableRow = $Table.NewRow()
			$TableRow.FullName = $UserSettings.FullName
			$TableRow.SAMName = $UserSettings.SAMAccountName
			$TableRow.BU = $UserSettings.Title
			$TableRow.Platform = $UserSettings.Description
			$TableRow.Email = $UserSettings.Email
			$TableRow.Phone = $UserSettings.PhoneNumber
			$TableRow.HomeDir = $UserSettings.HomeDir
			$Table.Rows.Add($TableRow)
		}
	}
}

$Table | Export-Csv -Path $OutFile -noTypeInformation