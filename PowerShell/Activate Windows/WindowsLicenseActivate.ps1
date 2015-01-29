#-----------------------------------
#FUNCTIONS
#-----------------------------------
$lstat = DATA {

ConvertFrom-StringData -StringData @'
0 = Unlicensed
1 = Licensed
2 = OOB Grace
3 = OOT Grace
4 = Non-Genuine Grace
5 = Notification
6 = Extended Grace
'@

}

function set-licensekey {

param (
[parameter(Mandatory=$true)][string][ValidatePattern("^\S{5}-\S{5}-\S{5}-\S{5}-\S{5}")]$Productkey,
[parameter(Mandatory=$false)][string]$computername="$env:COMPUTERNAME"
)

 $product = gwmi -Class SoftwareLicensingService -computername $computername

 try
 {
   $product.InstallProductKey($ProductKey)
   write-host "Refresing License Service"
   $product.RefreshLicenseStatus()
  }
  catch
  {
     Write-Host "Error Setting License Key - $_"
	 exit 1
  }
}

#-----------------------------------
#-----------------------------------
#VARIABLES
#-----------------------------------
$env:WINDOWS_LICENSE

#-----------------------------------

#-----------------------------------
#MAIN
#-----------------------------------
Write-Host "Starting Windows Licensing and Activation Script"

#region Windows License
#get current license info

Write-Host "Getting Current Windows License Information"

$winLicense = gwmi SoftwareLicensingProduct |? {$_.PartialProductKey} | select Name, ApplicationId, @{N="LicenseStatus"; E={$lstat["$($_.LicenseStatus)"]} }

Write-Host "Windows License Name`: $($winLicense.Name)"
Write-Host "Windows License Status`: $($winLicense.LicenseStatus)"

if($winLicense.LicenseStatus -eq "Licensed")
{
  write-host "Windows is Licensed"
}
else
{
  Write-Host "Windows is NOT Licensed"
  Write-Host "Setting License Key"
  
  try
  {
    set-licensekey -Productkey $env:WINDOWS_LICENSE
    $licUpdated = $true
  }
  catch
  {
    Write-Host "ERROR Setting License Key - $($_.message)"
	exit 1
  }	
}
#endregion

#region Windows Activation
#get current license info

Write-Host "Getting Current Windows Activation Information"

$winProduct = get-wmiObject -query  "SELECT * FROM SoftwareLicensingProduct WHERE PartialProductKey <> null
                                                                   AND ApplicationId='55c92734-d682-4d71-983e-d6ec3f16059f'
                                                                   AND LicenseIsAddon=False"

Write-Host "Windows License Status`: $($winProduct.LicenseStatus)"
Write-Host "Windows Product Description`: $($winProduct.Description)"

if($winProduct.LicenseStatus -eq 1)
{
  Write-Host "Windows is Activated"
}
else
{
  Write-Host "Windows is NOT Activated"
  Write-Host "Attempting to Activate"
  
  try
  {
    $winProduct.activate()
	$licUpdated = $true
  }
  catch
  {
    Write-Host "ERROR Activating Windows - $($_.message)"
	exit 1
  }
}

#endregion


Write-Host "Finished Windows Licensing and Acitivation Script"

#-----------------------------------