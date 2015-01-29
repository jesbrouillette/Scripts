function ADSearch ($userName,$class,$ADSI) { # function retuns the full CN of the user or group
	$adsiRoot = [ADSI]"LDAP://$ADSI"
	$search = new-object System.DirectoryServices.DirectorySearcher 
	$search.SearchRoot = $adsiRoot
	$search.Filter = "(&(objectCategory=$class)(sAMAccountName=$userName))"
	$users = $search.findall()

	return $users[0].path

} # end function
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
} # end GetDomain function

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
} # end SetADSI function

# ----------------------------#
# Start Script Execution Here #
# ----------------------------#

if ($debug) { $ErrorActionPreference = "Stop" }
else { $ErrorActionPreference = "SilentlyContinue" }

$list = Import-Csv "usercopies.csv"
$log = "Replicate-Membership_" + (Get-Date -format "MM-dd-yy_HH.mm.ss") + ".log"
$msg = "Started: " + (get-date).ToString() + " by " + $env:USERDOMAIN + "\" + $env:USERNAME + "
" ; $msg | Out-File $log -Encoding ASCII -Append

Write-Host $list.Count "members to copy"

$count = 0
$fail = 0
$success = 0
foreach ($line in $list) {
	$count += 1

	$newDom = $line.NewDom
	$newUser = $line.New
	$oldDom = $line.OldDom
	$oldUser = $line.Old
	
	$newADSI = SetADSI $newDom
	$newClass = "user"
	$newCN = ADSearch $newUser $newClass $newADSI
	if (!$newCN) { $msg = $newDom + "\" + $newUser + " was not found." ; $msg | Out-File $log -Encoding ASCII -Append }
	else {
		$oldADSI = SetADSI $oldDom
		$oldClass = "user"
		$oldCN = ADSearch $oldUser $oldClass $oldADSI
		if (!$oldCN) { $msg = $oldDom + "\" + $oldUser + " was not found." ; $msg | Out-File $log -Encoding ASCII -Append }
		else {
			$newAD = [ADSI]("$newCN")
			$oldAD = [ADSI]("$oldCN")
			$newSAM = $newAD.sAMAccountName
			$oldSAM = $goldAD.sAMAccountName
			
			if ($line.Include -and $line.Exclude) { $oldMemb = $oldAD.memberOf | where {$_ -match $line.Include -and $_ -match $line.Exclude} }
			elseif ($line.Include) { $oldMemb = $oldAD.memberOf | where {$_ -match $line.Include} }
			elseif ($line.Exclude) { $oldMemb = $oldAD.memberOf | where {$_ -notmatch $line.Include} }
			else { $oldMemb = $oldAD.memberOf }
		
			if (!$oldMemb -and $line.Include) { $msg = $oldDom + "\" + $oldUser + " is not a member of any groups matching " + $line.Include ; $msg | Out-File $log -Encoding ASCII -Append }
			elseif (!$oldMemb -and !$line.Include) { $msg = $oldDom + "\" + $oldUser + " is not a member of any groups" ; $msg | Out-File $log -Encoding ASCII -Append }
			else {
				foreach ($group in $oldMemb) {
					[Void]$Error.Clear()
					$groupAD = [ADSI]("LDAP://$group")
					$groupAD.add("$newCN")
					$groupAD.setinfo()
					if ($error) {
						if ($Error[0].Exception.Message -match "The object already exists.") { $msg = "ERROR:  " + $newDom + "\" + $newSAM + " was not added to " + $groupAD.sAMAccountName + "  :  The object already exists" }
						else { $msg = "ERROR:  " + $newDom + "\" + $newSAM + " was not added to " + $groupAD.sAMAccountName + "  :  " + $Error[0].Exception.Message }
						$msg | Out-File $log -Encoding ASCII -Append 
						$fail += 1
						[Void]$Error.Clear()
					} else {
						$msg = "added " + $newDom + "\" + $newSAM + " to " + $groupAD.sAMAccountName
						$msg | Out-File $log -Encoding ASCII -Append
						$success += 1
						[Void]$Error.Clear()
					}
				}
			}
		}
	}
	if (($count % 15) -eq 0 -or $count -eq $list.Count -and $count -ne 0) { $msg = " " + $count + " of " + $list.Count + " changes processed" ; $msg }
}

$msg = "
Completed: " + (get-date).ToString() + "
" ; $msg | Out-File $log -Encoding ASCII -Append