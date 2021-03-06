$AccessGroups	= $ENV:SMB_ACCESS
$AD_User		= $ENV:AD_ADMIN_USERNAME
$AD_Password	= $ENV:AD_ADMIN_PASSWORD
$AD_NetBios		= $ENV:AD_NETBIOS_NAME

$Domain_User	= "{0}\{1}" -f $AD_NetBios,$AD_User

$AD_Secure_Password	= ConvertTo-SecureString $AD_Password -AsPlainText -Force
$AD_Credential		= New-Object System.Management.Automation.PSCredential $Domain_User,$AD_Secure_Password

foreach ($AccessGroup in $AccessGroups) {

	$Split			= $AccessGroup.Split(",")
	$ADObject		= $Split[0]
	$Domain			= $Split[1]
	$Path			= $Split[2]
	$Permissions	= $Split[3]	#Options: AppendData, ChangePermissions, CreateDirectories, CreateFiles, Delete, DeleteSubdirectoriesAndFiles, ExecuteFile, FullControl, ListDirectory, Modify, Read, ReadAndExecute, ReadAttributes, ReadData, ReadExtendedAttributes, ReadPermissions, Synchronize, TakeOwnership, Traverse, Write, WriteAttributes, WriteData, WriteExtendedAttributes,
	$AccessControl	= $Split[4]	#Options: Allow, Deny
	$Propagation	= $Split[5]	#Options: InheritOnly (the ACE is Propagationd to all child objects), NoPropagationInherit (the ACE is not Propagationd to child objects),None
	$Inheritance	= $Split[6]	#Options: ContainerInherit (the ACE is inherited by child containers, like subfolders), ObjectInherit (the ACE is inherited by child objects, like files),None

	$FileSystemRights	= [System.Security.AccessControl.FileSystemRights]"$Permissions"		#Options: AppendData, ChangePermissions, CreateDirectories, CreateFiles, Delete, DeleteSubdirectoriesAndFiles, ExecuteFile, FullControl, ListDirectory, Modify, Read, ReadAndExecute, ReadAttributes, ReadData, ReadExtendedAttributes, ReadPermissions, Synchronize, TakeOwnership, Traverse, Write, WriteAttributes, WriteData, WriteExtendedAttributes,
	$InheritanceFlags	= [System.Security.AccessControl.InheritanceFlags]"$Inheritance"		#Options: ContainerInherit (the ACE is inherited by child containers, like subfolders), ObjectInherit (the ACE is inherited by child objects, like files),None
	$PropagationFlags	= [System.Security.AccessControl.PropagationFlags]"$Propagation"		#Options: InheritOnly (the ACE is Propagationd to all child objects), NoPropagationInherit (the ACE is not Propagationd to child objects),None
	$AccessControlType	= [System.Security.AccessControl.AccessControlType]"$AccessControl"		#Options:Allow, Deny

	$IsInstalled = Get-WindowsFeature RSAT-ADDS-Tools | Select -ExpandProperty Installed
	if (!$IsInstalled) { Add-WindowsFeature RSAT-ADDS-Tools -IncludeAllSubFeature
	else { $IsInstalled = $null }
	
	Import-Module ActiveDirectory

	$UserSID	= Get-ADUser $ADObject -Server $Domain -Credential $AD_Credential | Select -expand SID
	$objACE		= New-Object System.Security.AccessControl.FileSystemAccessRule($UserSID, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)
	$objACL		= Get-ACL "$Path"
	
	$objACL.AddAccessRule($objACE)

	$SetACL = Set-ACL "$Path" $objACL -Passthru
	if ($SetACL) { Write-Host "SET_ACL:  Permissions set properly." }
	else { Write-Host "SET_ACL:  Permissions for $$ADObject was not set to $Path." }
}