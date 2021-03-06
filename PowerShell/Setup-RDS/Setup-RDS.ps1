$License_Server = $RDS_LICENSE_SERVER

# Install RDS Services
$RDS_Feature = Get-WindowsFeature –Name RDS-RD-Server
Import-module ServerManager –verbose
if ($RDS_Features.InstallState -eq "Available") {
	Write-Host "RDS-RD-Server is not installed.  Installing with all necessary subcomponents."
	Add-WindowsFeature –Name RDS-RD-Server –IncludeAllSubFeature
	
	Write-Host "RDS-RD-Server install completed.  Rebooting."
	rs_shutdown -r -i -v
}

Write-Host "Importing the RemoteDesktopServices module."
Import-Module RemoteDesktopServices

# new-item -path RDS:\RDSConfiguration\LicensingSettings\SpecifiedLicenseServers –name $License_Server