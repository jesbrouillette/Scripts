# Get-GPOObjects.ps1

$gpm=New-Object -com "GPMGMT.GPM"

$gpmconstants=$gpm.GetConstants()

$gpmDomain=$gpm.GetDomain("mycompany.local","",$gpmconstants.UseAnyDC)

$gpmSearch=$gpm.CreateSearchCriteria()

$colGPOs=$gpmDomain.SearchGPOs($gpmSearch)

$msg="There are {0} group policy objects in the domain." -f $colGPOs.Count
Write-Host $msg

$colGPOs | sort CreationTime -Descending | select DisplayName,CreationTime,ModificationTime
