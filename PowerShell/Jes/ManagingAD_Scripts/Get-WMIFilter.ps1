# Get-WMIFilter.ps1

Function Get-WMIFilter {
    Param([string]$domain="mycompany.local")
    
    $gpm=New-Object -com "GPMGMT.GPM"
    $gpmconstants=$gpm.GetConstants
    $gpmDomain=$gpm.Getdomain($domain,"",$gpmconstants.UseAnyDC)
    $gpmSearch=$gpm.CreateSearchCriteria()
    
    $gpmDomain.SearchWMIFilters($gpmSearch) | foreach {
        $_ | Add-Member -MemberType NoteProperty -Name "WMIFilter" `
        -value $_.GetQueryList() -passthru
    }
}

#sample usage
# Get-WMIFilter
# Get-WMIFilter | Format-List
# Get-WMIFilter | where {$_.name -match "Vista Desktops"} | Select WMIFilter
