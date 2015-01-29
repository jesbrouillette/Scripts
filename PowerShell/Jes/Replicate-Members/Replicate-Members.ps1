function SetADSI ($domain) {# sets the correct ADSI container for each domain
	if ($domain.ToLower() -eq "ap"){
		return "dc=ap,dc=corp,dc=cargill,dc=com"
	}
	elseif ($domain.ToLower() -eq "corp"){
		return "dc=corp,dc=cargill,dc=com"
	}
	elseif ($domain.ToLower() -eq "eu"){
		return "dc=eu,dc=corp,dc=cargill,dc=com"
	}
	elseif ($domain.ToLower() -eq "la"){
		return "dc=la,dc=corp,dc=cargill,dc=com"
	}
	elseif ($domain.ToLower() -eq "meat"){
		return "dc=meat,dc=cargill,dc=com"
	}
	elseif ($domain.ToLower() -eq "na"){
		return "dc=na,dc=corp,dc=cargill,dc=com"
	}
}

function GetDomain ($adsiPath) { # sets the correct domain for the given adsi path
	if ($adsiPath -match "dc=ap") {
		return "ap"
	}
	elseif ($adsiPath -match "dc=eu") {
		return "eu"
	}
	elseif ($adsiPath -match "dc=la") {
		return "la"
	}
	elseif ($adsiPath -match "dc=na") {
		return "na"
	}
	elseif ($adsiPath -match "dc=meat") {
		return "meat"
	}
	else {
		return "corp"
	}
}

function GetCN ($sAMName,$class,$ADSI) { # function retuns the full CN of the user or group
	$adsiRoot = [ADSI]"LDAP://$ADSI"
	$search = new-object System.DirectoryServices.DirectorySearcher 
	$search.SearchRoot = $adsiRoot
	$search.Filter = "(&(objectCategory=$class)(sAMAccountName=$sAMName))"
	$users = $search.findone()
	return $users.path

}

$ErrorActionPreference = "Continue"
$Error.Clear()

$log = "Replicate-Members.log"
$groups = Import-Csv groups.csv
$groups
$msg = "
Replicate-Members.ps1 started " + (Get-Date).ToString() + "
" ; $msg ; $msg | Out-File -Append $log

$count = 0
Write-Host ($groups.Count + 1) "group(s) to replicate memberships"

foreach ($group in $groups) {
	$count += 1
	$oldRoot = SetADSI $group.OldDomain
	$newRoot = SetADSI $group.NewDomain
	
	if ($oldRoot -eq "no ADSI path found") {
		$msg = $group.OldGroup + " was not found in " + $group.oldDomain ; $msg | Out-File -Append $log
	}
	elseif ($newRoot -eq "no ADSI path found") {
		$msg = $group.NewGroup + " was not found in " + $group.NewDomain ; $msg | Out-File -Append $log
	}
	else {
		$oldGroupCN = GetCN $group.OldGroup "group" $oldRoot
		$newGroupCN = GetCN $group.NewGroup "group" $newRoot
		if (!$oldGroupCN) { $msg = "`"" + $group.OldDomain + "\" + $group.OldGroup + "`" was not found" ; $msg | Out-File -Append $log }
		elseif (!$newGroupCN) { $msg = "`"" + $group.NewDomain + "\" + $group.NewGroup + "`" was not found" ; $msg | Out-File -Append $log }
		else {
			$oldGroupAD = [ADSI]("$oldGroupCN")
			$newGroupAD = [ADSI]("$newGroupCN")
			$newGroupDomain = GetDomain $newGroupAD.distinguishedName

			$msg = "Copying members from " + $group.oldDomain + "\" + [string]$oldGroupAD.Name + " to " + $group.newDomain + "\" + [string]$newGroupAD.Name; $msg ; $msg | Out-File -Append $log 

			#$oldGroupAD
			foreach ($member in $oldGroupAD.Member) {
				$memberAD = [ADSI]("LDAP://$member")
				$addMember = $newGroupAD.Add("LDAP://$member")
				if ($Error[0].Exception.Message -like "*already exists*") {
					$memberDomain = GetDomain $memberAD.distinguishedName
					$msg = "Error:  Could not add " + $memberDomain.ToUpper() + "\" + [string]$memberAD.Name + " to " + $newGroupDomain + "\" + $newGroupAD.Name + ":  User already exists" ; $msg | Out-File -Append $log
					[Void]$Error.Clear()
				} elseif ($Error) {
					$memberDomain = GetDomain $memberAD.distinguishedName
					$msg = "Error:  Could not add " + $memberDomain.ToUpper() + "\" + [string]$memberAD.Name + " to " + $newGroupDomain + "\" + $newGroupAD.Name + ":  " + $Error[0].Exception.Message ; $msg | Out-File -Append $log
					[Void]$Error.Clear()
				} else { $msg = "Added " + $memberDomain.ToUpper() + "\" + [string]$memberAD.Name + " to " + $newGroupDomain + "\" + $newGroupAD.Name ; $msg | Out-File -Append $log }
			}
		}
	}
	if (($count % 15) -eq 0 -or $count -eq $groups.Count -and $count -ne 0) {
		$msg = " " + $count + " of " + $groups.Count + " changes processed" ; $msg
	}
}
$msg = "
Replicate-Members.ps1 finished " + (Get-Date).ToString() + "
" ; $msg ; $msg | Out-File -Append $log
