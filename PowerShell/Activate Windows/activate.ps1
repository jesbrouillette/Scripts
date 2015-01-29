cls
#--------------------------------
#FUNCTIONS
#--------------------------------




#------------------------------------------------
#script header
#script name:  Windows Activate Trial Version
#------------------------------------------------

#------------------------------------------------
#Vars
#------------------------------------------------
$licenseStatus=@{0="Unlicensed"; 1="Licensed"; 2="OOBGrace"; 3="OOTGrace"; 4="NonGenuineGrace"; 5="Notification"; 6="ExtendedGrace"}
#$key = $env:WINDOWS_LICENSE_KEY

#------------------------------------------------

#------------------------------------------------
#MAIN
#------------------------------------------------
Write-Host "Getting Windows License Status"
$wmiSLP = get-wmiObject -query  "SELECT * FROM SoftwareLicensingProduct WHERE PartialProductKey <> null AND ApplicationId='55c92734-d682-4d71-983e-d6ec3f16059f' AND LicenseIsAddon=False"

$osLicInfo = $wmiSLP | select Name, Description, LicenseStatus ,`
             @{Label="Grace period (days)"; Expression={ $_.graceperiodremaining / 1440}}, `
             @{Label= "License Status Description"; Expression={switch (foreach {$_.LicenseStatus}) `
              { 0 {"Unlicensed"} `
                1 {"Licensed"} `
                2 {"Out-Of-Box Grace Period"} `
                3 {"Out-Of-Tolerance Grace Period"} `
                4 {"Non-Genuine Grace Period"} `
              } } }
			  
Write-Host "Current OS License Status"
write-host "---------------------------------"
Write-Output $osLicInfo
Write-Host "---------------------------------"
Write-Host ""

#------------------------------------------------
#Activate if needed
#------------------------------------------------
if($osLicInfo.LicenseStatus -eq 4)
{
  Write-Host "Windows is Not Activated - Activating"  
  try
  {
      $wmiSLP.activate()
	  
	  #get license service
      $licService = gwmi -query "select * from SoftwareLicensingService"
	  $licService.RefreshLicenseStatus()   
	
	  Write-Host "Windows Activated"
	  Write-Host "Getting Updated Windows License Status"
      $wmiSLPUpd = get-wmiObject -query  "SELECT * FROM SoftwareLicensingProduct WHERE PartialProductKey <> null AND ApplicationId='55c92734-d682-4d71-983e-d6ec3f16059f' AND LicenseIsAddon=False"
	
	  $osLicInfoUpd = $wmiSLPUpd | select Name, Description, LicenseStatus ,`
             @{Label="Grace period (days)"; Expression={ $_.graceperiodremaining / 1440}}, `
             @{Label= "License Status Description"; Expression={switch (foreach {$_.LicenseStatus}) `
              { 0 {"Unlicensed"} `
                1 {"Licensed"} `
                2 {"Out-Of-Box Grace Period"} `
                3 {"Out-Of-Tolerance Grace Period"} `
                4 {"Non-Genuine Grace Period"} `
              } } }
			  
     Write-Host "Updated OS License Status"
     write-host "---------------------------------"
     Write-Output $osLicInfoUpd
     Write-Host "---------------------------------"
     Write-Host ""
	
  }
  catch
  {
    Write-Host "ERROR Activating Windows - $_"
	exit 1  
  }
}
else
{
  Write-Host "Windows is Activated"

}
#------------------------------------------------

#------------------------------------------------
#if not activated
#if not licensed

#inputs
  #key
  #reboot
  
  
  
#activate


#reboot


#new status

#End
Write-Host "Finished Checking Windows License Status"