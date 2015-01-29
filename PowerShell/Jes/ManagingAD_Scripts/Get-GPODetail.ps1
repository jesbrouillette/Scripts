#Get-GPODetail.ps1

Function Get-GPODetail {
    Param([PSObject]$gpo)

    BEGIN {
    }
    
    PROCESS {
        if ($_) {
            $gpo=$_
        } 
        
        if (!($wmi=($gpo.GetWMIFilter()).name)) {
            $wmi=$null
        }
        
        $gpo | Add-Member -Name "WMIFilter" -MemberType NoteProperty -Value $wmi
        $gpo | Add-Member -Name "ACLConsistent" -MemberType NoteProperty -Value $gpo.IsACLConsistent()
        $gpo | Add-Member -Name "ComputerEnabled" -MemberType NoteProperty -Value $gpo.IsComputerEnabled()
        $gpo | Add-Member -Name "UserEnabled" -MemberType NoteProperty -Value $gpo.IsUserEnabled()

        write $gpo
        
    } #end PROCESS script block
    
    END {
    }

}

#sample usage
#  Get-SDMgpo * | Get-GPODetail | select DisplayName,WMIFilter,ACLConsistent,*Enabled
#  Get-GPODetail (Get-SDMgpo "Desktop Firewall Settings") 
#  get-sdmgpo * | get-gpodetail | Where {!$_.UserEnabled} | Select Displayname,*Time
#  get-sdmgpo * | get-gpodetail | Where {!$_.ACLConsistent} | Select Displayname,*Time
#  get-sdmgpo * | get-gpodetail | Where {$_.WMIFilter} | Select Displayname,*Time,WMIFilter
