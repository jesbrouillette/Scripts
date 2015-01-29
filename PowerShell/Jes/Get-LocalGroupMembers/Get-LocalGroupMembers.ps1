param (
	[string]$server,  #computer to query
	[string]$group,   #specifiy the group to query
	[string]$list,    #list to query
	[switch]$basic, #
	[switch]$console, #output to console
	[switch]$csv      #output to csv
)
################################################################################
#                                  ##########                                  #
#                                                                              #
# Retrieve members of the local admin group for a remote computer              #
#                                                                              #
# Created By: Jes Brouillette                                                  #
# Creation Date: Sep 22, 2009                                                  #
#                                                                              #
# Usage: .\Get-Admins.ps1 [-server, -list, -console, -csv]                     #
#                                                                              #
# Switches:                                                                    #
#  -server [string] : Single computer to query (default)                       #
#  -list [string] : file containing a list of computers to query               #
#  -console : output to console (default)                                      #
#  -csv  : output to csv                                                       #
#                                                                              #
#                                  ##########                                  #
################################################################################

Function GetDomainUser ($sam){
	$searcher = New-Object system.DirectoryServices.DirectorySearcher
	$searcher.PageSize = 100
	$searcher.filter = "samaccountname = $sam"
	$user = $searcher.findone()
	
	return $user
}

$errorActionPreference = "SilentlyContinue"

if (!$server -and !$list) { Write-Host "You must specify either a server using `"-server `%servername`%`" or a list using `"-list `%filename`%`"" ; exit }
if (!$group) { $group = Read-Host "What group would you like to search for?" }

if ($server) { $list = $server }
else { [Object]$list = Get-Content $list }

New-Variable ADS_UF_ACCOUNTDISABLE 0x0002 -Option Constant

$myObj = @()
$export = "Get-LocalGroupMembers_" + (Get-Date -format "MM-dd-yy.HH.mm.ss") + ".csv"

Write-Host "Checking" $list.Count "servers for members in the Local" $group "group"
$count = 0

foreach ($item in $list) {	
	trap {
		Write-Warning ("Unable to return group membership for {0} on {1}." -f $group,$server.ToUpper())
	}
	$count += 1
	
	$LocalGroup = [ADSI]"WinNT://$item/$group,group"

	foreach ($member in $LocalGroup.psbase.invoke("Members")) {
		$ADSPath = $member.GetType().InvokeMember("ADSPath", 'GetProperty',$null, $member, $null)
		$class = $member.GetType().InvokeMember("Class", 'GetProperty',$null, $member, $null)
		$name = $member.GetType().InvokeMember("Name", 'GetProperty',$null, $member, $null)
		
		if ($ADSPath -match $item) {
			$local = $True
			$domain = $item.ToUpper()
			$description = $member.GetType().InvokeMember("Description", 'GetProperty',$null, $member, $null)
			$displayname = $member.GetType().InvokeMember("FullName", 'GetProperty',$null, $member, $null)
			$account = $ADSPath
			$flag = $member.GetType().InvokeMember("userflags", 'GetProperty',$null, $member, $null)
			if ($flag -band $ADS_UF_ACCOUNTDISABLE) { $disabled = $True }
			else { $disabled = $False }
		} else {
			$local = $False
			$ADSPath -match "(?<domain>//\w+)" | Out-Null
			
			$domain = $matches.domain.Replace("//","")
			$domainuser = GetDomainUser $name
			if ($domainuser) {
				$description = $domainuser.properties.item("description")[0]
				$displayname = $domainuser.properties.item("displayname")[0]
				$account = $domainuser.properties.item("distinguishedname")[0]
				if ($domainuser.properties.item("useraccountcontrol")[0] -band $ADS_UF_ACCOUNTDISABLE ) { $disabled = $True }
				else { $disabled = $False }
			} else {
				$description = "N/A"
				$displayname = "N/A"
				$disabled = $null
				$account = $ADSPath
			}
		} 
		
		$account = ($account.Replace("WinNT`:`/`/","")).Replace("`/","`\")
		if ($account.ToLower() -match $item.ToLower()) { $account = $item.ToUpper() + "\" + $name }
		
		$row = "" | Select Computer,Account,Name,DisplayName,Description,Disabled,Domain,IsLocal,Class
		$row.Computer = $item.toUpper()
		$row.Account = $account
		$row.Name = $name
		$row.DisplayName = $displayname 
		$row.Description = $description
		$row.Disabled = $disabled
		$row.Domain = $domain
		$row.IsLocal = $local
		$row.Class = $class
		$myObj += $row
	}
	if (($count % 15) -eq 0 -or $count -eq $list.Count -and $count -ne 0) {
		Write-Host " " $count "of" $list.Count " servers checked"
	}

}

if ($csv) { $myObj | Export-Csv $export -NoTypeInformation }
elseif ($basic) { $myObj | select Computer,Name,Domain | format-table }
else { $myObj | format-table}