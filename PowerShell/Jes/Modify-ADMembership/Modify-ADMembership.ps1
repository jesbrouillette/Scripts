function GetDN ($subject,$class,$ADSI) { # function retuns the full CN of the user or group
	$adsiRoot = [ADSI]"LDAP://$ADSI"
	$search = new-object System.DirectoryServices.DirectorySearcher 
	$search.SearchRoot = $adsiRoot
	$search.Filter = "(&(objectCategory=$class)(sAMAccountName=$subject))"
	$found = $search.findall()

	return $found[0].path

} # end function

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

$ErrorActionPreference = "SilentlyContinue"

$list = Import-Csv "mods.csv"
$log = "Modify-ADMembership_" + (Get-Date -format "MM-dd-yy.HH.mm.ss") + ".log"
$msg = "Started: " + (get-date).ToString() + " by " + $env:USERDOMAIN + "\" + $env:USERNAME + "
" ; $msg | Out-File $log -Encoding ASCII -Append
$data = @()

Write-Host $list.Count "membership changes to make"

$count = 0
foreach ($line in $list) {
	$count += 1
	
	$row = "" | Select Subject,Target,Modify,Status,Message

	$SubjectDom = [string]$line.SubjectDom
	$TargetDom = [string]$line.TargetDom
	$subject = [string]$line.Subject
	$class = [string]$line.SubjectClass
	$TargetName = [string]$line.Target
	
	$TargetADSI = SetADSI $TargetDom
	$TargetClass = "group"
	$TargetCN = GetDN $line.Target $TargetClass $TargetADSI
	
	$SubjectADSI = SetADSI $SubjectDom
	$SubjectCN = GetDN $subject $class $SubjectADSI
	
	if (!$SubjectCN) {
		$msg = "ERROR:  " + $SubjectDom + "\" + $subject + " was not added to " + $TargetDom + "\" + $TargetName + "  :  Subject not found" ; $msg | Out-File $log -Encoding ASCII -Append
		$row.Subject = $SubjectDom + "\" + $subject
		$row.Target = $TargetDom + "\" + $TargetName
		$row.Modify = $line.Modify
		$row.Status = "ERROR"
		$row.Message = "Subject not found"
	}
	elseif (!$TargetCN) {
		$msg = "ERROR:  " + $SubjectDom + "\" + $subject + " was not added to " + $TargetDom + "\" + $TargetName + "  :  Target not found" ; $msg | Out-File $log -Encoding ASCII -Append
		$row.Subject = $SubjectDom + "\" + $subject
		$row.Target = $TargetDom + "\" + $TargetName
		$row.Modify = $line.Modify
		$row.Status = "ERROR"
		$row.Message = "Target not found"
	}
	else {
		$SubjectAD = [ADSI]("$SubjectCN")
		$TargetAD = [ADSI]("$TargetCN")
		$SubjectSAM = $SubjectAD.sAMAccountName
		$TargetSAM =$TargetAD.sAMAccountName
		$SubjectDN = $SubjectAD.distinguishedName
	
		$checkMemb = ($TargetAD.member | where {$_ -eq $SubjectDN})
		
		if ($line.Modify -match "add") {
			if ($checkMemb.Length -ge 1) {
				$msg = $SubjectDom + "\" + $SubjectSAM + " is already a member of " + $TargetSAM ; $msg | Out-File $log -Encoding ASCII -Append
				$row.Subject = $SubjectDom + "\" + $subject
				$row.Target = $TargetDom + "\" + $TargetName
				$row.Modify = $line.Modify
				$row.Status = "Success"
			}
			else {
				[Void]$Error.Clear()
				$TargetAD.add("LDAP://" + $SubjectDN)
				$TargetAD.setinfo()
				if ($error) {
					$msg = "ERROR:  " + $SubjectDom + "\" + $SubjectSAM + " was not added to " + $TargetSAM + " : " + $error[0].Exception.Message ; $msg | Out-File $log -Encoding ASCII -Append
					$row.Subject = $SubjectDom + "\" + $subject
					$row.Target = $TargetDom + "\" + $TargetName
					$row.Modify = $line.Modify
					$row.Status = "ERROR"
					$row.Message = $error[0].Exception.Message
					[Void]$Error.Clear()
				}
				else {
					$msg = "added " + $SubjectDom + "\" + $SubjectSAM + " to " + $TargetSAM ; $msg | Out-File $log -Encoding ASCII -Append
					$row.Subject = $SubjectDom + "\" + $subject
					$row.Target = $TargetDom + "\" + $TargetName
					$row.Modify = $line.Modify
					$row.Status = "Success"
				}
			}
		}
		elseif ($line.Modify -match "remove") {
			if (!$checkMemb) {
				$msg = $SubjectDom + "\" + $SubjectSAM + " is not a member of " + $TargetSAM ; $msg | Out-File $log -Encoding ASCII -Append
				$row.Subject = $SubjectDom + "\" + $subject
				$row.Target = $TargetDom + "\" + $TargetName
				$row.Modify = $line.Modify
				$row.Status = "Error"
				$row.Message = "Not a memeber of the requested Target"
			}
			else {
				[Void]$Error.Clear()
				$TargetAD.remove("LDAP://" + $SubjectDN)
				$TargetAD.setinfo()
				if ($Error) {
					$msg = "ERROR:  " + $SubjectDom + "\" + $SubjectSAM + " was not removed from " + $TargetSAM + " : " + $error[0].Exception.Message ; $msg | Out-File $log -Encoding ASCII -Append
					$row.Subject = $SubjectDom + "\" + $subject
					$row.Target = $TargetDom + "\" + $TargetName
					$row.Modify = $line.Modify
					$row.Status = "ERROR"
					$row.Message = $error[0].Exception.Message
					[Void]$Error.Clear()
				}
				else {
					$msg = "removed " + $SubjectDom + "\" + $SubjectSAM + " from " + $TargetSAM ; $msg | Out-File $log -Encoding ASCII -Append ; [Void]$error.Clear()
					$row.Subject = $SubjectDom + "\" + $subject
					$row.Target = $TargetDom + "\" + $TargetName
					$row.Modify = $line.Modify
					$row.Status = "Success"
				}
			}
		}
		else {
			$msg = "no modify option was set for " + $SubjectDom + "\" + $SubjectSAM + " with " + $TargetSAM ; $msg | Out-File $log -Encoding ASCII -Append
		}
	}
	if (($count % 15) -eq 0 -or $count -eq $list.Count -and $count -ne 0) {
		$msg = " " + $count + " of " + $list.Count + " changes processed" ; $msg
		$row.Subject = $SubjectDom + "\" + $subject
		$row.Target = $TargetDom + "\" + $TargetName
		$row.Modify = $line.Modify
		$row.Status = "ERROR"
		$row.Message = "No Modify option selected"
	}
}

$msg = "
Completed: " + (get-date).ToString() + "
" ; $msg | Out-File $log -Encoding ASCII -Append