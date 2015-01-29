$strArgs = [string]$args

if ($strArgs.ToLower() -match "/h" -or $strArgs.ToLower() -match "\?") { #Displays help
	$strHelp = "Get-GroupMembers.ps1:`n`n1.)  Retrieves users in the given group`n2.)  Exports them to members.csv`n`nUsage:`n.\Get-GroupMembsr.ps1 (/h|/?)`n`nSwitches:)`n  /h - displays this message`n  /? - same as /h`n`nCSV File Format:`ndomain,group`n[domain],[group]`n`n  Where:`n    [domain] = the domain in which the group resides (AP,CORP,EU,LA,MEAT,NA)`n    [group] = the sAMAccountName for the group"
	$objMsgBox = new-object -comobject wscript.shell
	$objMsgBox.Popup($strHelp,0,"Shutdown-Computer.ps1")
	exit
}
else {
	$strInput = $args[0]
}

function set-adsi ($strADSI) {# sets the correct ADSI container for each domain
	if ($strADSI.ToLower() -eq "ap"){
		return "dc=ap,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strADSI.ToLower() -eq "eu"){
		return "dc=eu,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strADSI.ToLower() -eq "la"){
		return "dc=la,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strADSI.ToLower() -eq "meat"){
		return "dc=meat,dc=cargill,dc=com"
	}
	elseif ($strADSI.ToLower() -eq "na"){
		return "dc=na,dc=corp,dc=cargill,dc=com"
	}
	else {
		return "dc=corp,dc=cargill,dc=com"
	}
} # end set-adsi function

function get-dn ($strSAMNameF,$strClassTypeF,$strADSIF) { # function retuns the full CN of the user or group
	$strRoot = [ADSI]"LDAP://$strADSIF"
	$objSearcher = new-object System.DirectoryServices.DirectorySearcher 
	$objSearcher.SearchRoot = $strRoot
	$objSearcher.Filter = "(&(objectCategory=$strClassTypeF)(sAMAccountName=$strSAMNameF))"
	$objUsers = $objSearcher.findall()

	if ($objUsers.count -gt 1) {
		$intCount = 0
		foreach($objUser in $objUsers) {
			write-output $intCount ": " $objUser.path
			$intCount = $intCount + 1
		}
		$strSelection = Read-Host "Please select item: "
		return $objUsers[$strSelection].path
	}
	else {
		return $objUsers[0].path
	}
} # end get-dn function

function Export-Members ($groups) {
	foreach ($member in $groups.member)
	{
		$member | Out-file -encoding default export.csv -append
	}
}

# Setup the Datatable Structure
$objTable = New-Object system.Data.DataTable “Share Setup”
$col1 = New-Object system.Data.DataColumn Domain,([string])
$col2 = New-Object system.Data.DataColumn Group,([string])

$objTable.columns.add($col1)
$objTable.columns.add($col2)
# End Datatable Setup

$objGroups = Get-Content $strInput

foreach ($strGroup in $objGroups) {
	$row = $objTable.NewRow()
	$row.Domain = Split-Path $strGroup -parent
	$row.Group = Split-Path $strGroup -leaf
	$objTable.Rows.Add($row)
}

Remove-Variable objGroups

foreach ($objRow in $objTable) {
	$strGroupADSI = set-adsi $objRow.Domain # set the full ADSI path for the group
	$strGroup = [string]$objRow.Group # sAMAccount group name to search for
	$strClassType = "Group"
	$strGroupPath = get-dn $strGroup $strClassType $strGroupADSI # find the group
	$group = [ADSI]("$strGroupPath")
	[string]$file = $objRow.Group + ".csv"
	$expFile = New-Item -Name $file -ItemType "file" -Value $group.Name
	foreach ($objMember in $group.member) {
		$member = [ADSI]("LDAP://$objMember")
		$name = $member.Name
		$sAM = $member.sAMAccountName
		Write-Output "$name - $sAM" |Out-File $expFile -Append
	}
}

$a = new-object -comobject wscript.shell
$b = $a.popup("Members have been exported",0,"Get-GroupMembers.ps1")