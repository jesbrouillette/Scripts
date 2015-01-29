param (
	[string]$folder,  #file with a list of folders to process
	[string]$file,    #path to process
	[string]$owner,   #sets ownership to BUILTIN\Administrators where it is not already
	[switch]$recurse  #recurse
)
################################################################################
#                                  ##########                                  #
#                                                                              #
# Sets "Allow inheritable permissions to propigate to this object and all      #
#          child objects."                                                     #
#                                                                              #
# Created By:  Jes Brouillette                                                 #
# Creation Date:  9/30/09                                                      #
#                                                                              #
# Usage:  .\Set-Inheritance.ps1 [-folder %PATH%/-file %FILE%, -owner %OWNER%,  #
#                                -recurse]                                     #
#                                                                              #
# Switches:                                                                    #
#          -folder %PATH% - path to process                                    #
#          -file %FILE%   - file with a list of folders to process             #
#          -owner %OWNER% - sets ownership to the given Local User/Group or    #
#                           Domain User/Group in DOMAIN\name format            #
#          -recurse       - recureses the given folder structure               #
#                                                                              #
#                                  ##########                                  #
################################################################################

$erroractionpreference = "SilentlyContinue"
$log = "Set-Inheritance_" + (Get-Date -uformat "%d_%m_%Y") + ".log"

if ($folder) { $paths = $folder }
else { $paths = Get-Content $file }
if ($Error) { Write-Host "Unable to process request:" $error[0].Exception.Message ; exit }

$msg = "
" + (Get-Date).ToString() + " : Script execution begun by " + $env:USERDOMAIN + "\" + $env:USERNAME + "
"; $msg | Out-File $log -Append -Encoding ASCII

foreach ($path in $paths) {
	$path | Out-File $log -Append -Encoding ASCII

	if ($recurse) { $children = Get-ChildItem $path -Recurse | % {$_.FullName} }
	else { $children = Get-ChildItem $path | % {$_.FullName} }
	foreach ($child in $children) {
		$acl = Get-Acl $child
		if ($Error[0]) {
			$msg = "Could not retrieve ACL's for " + $child + " : " + $Error[0].Exception.Message ; $msg | Out-File $log -Append -Encoding ASCII
			$Error.Clear()
		} else {
			$split = $owner.Split("\")
			if (!$split[1]) {
				$split += $split[0]
				$split[0] = "BUILTIN"
				$owner = $split[0] + "\" + $split[1]
			}
			if ($owner -and $acl.Owner -ne $owner) {
				if ($owner -match "BUILTIN") { $objGroup = New-Object System.Security.Principal.NTAccount($split[1]) }
				else { $objGroup = New-Object System.Security.Principal.NTAccount($split[0],$split[1]) }
				$strSID = $objGroup.Translate([System.Security.Principal.SecurityIdentifier])
				$acl.SetOwner($strSID)
				$ownership = $true
			}
			$isProtected = $false
			$preserveInheritance = $true
			$acl.SetAccessRuleProtection($isProtected, $preserveInheritance)
			Set-Acl -Path $child -AclObject $acl
			if ($error[0]) {
				$msg = "Could not set ACL's for " + $child + " : " + $Error[0].Exception.Message ; $msg | Out-File $log -Append -Encoding ASCII
				$Error.Clear()
			} elseif ($ownership) {
				$msg = "Set ACL's & Ownership for " + $child ; $msg | Out-File $log -Append -Encoding ASCII
				Remove-Variable ownership
			} else {
				$msg = "Set ACL's for " + $child ; $msg | Out-File $log -Append -Encoding ASCII
			}
		}
	}
}