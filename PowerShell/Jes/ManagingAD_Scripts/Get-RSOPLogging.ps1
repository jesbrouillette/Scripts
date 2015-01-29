#Get-RSOPLogging.ps1

Function Get-RSOPLogging {
    Param([string]$username="$env:userdomain\administrator",
          [string]$computername="$env:userdomain\$env:computername",
          [string]$filepath="c:\",
          [switch]$xml
          )
    #set preference to Continue to enable debug messages      
    $debugPreference="SilentlyContinue"
    
    Write-Debug "`$username is $username"
    Write-Debug "`$computername is $computername"
    Write-Debug "`$filepath is $filepath"
    
    #validate $filepath
    if (!(Test-Path $filepath)) {
        Write-Warning "Failed to find $filepath"
        Return
    }
    
    #parse out the domain name 
    $user = ($username.split("\"))[1]
    $domain = ($username.split("\"))[0]
    $machine =($computername.split("\"))[1]
    
    Write-Debug "`$user is $user"
    Write-Debug "`$domain is $domain"
    Write-Debug "`$machine is machine"  
    
    #validate user and computer were passed as domain\name
    
    if (!$username.contains("\")) {
        Write-Warning "You need to specify the user name in the format domain\username"
        Return
    }
    
    if (!$computername.contains("\")) {
        Write-Warning "You need to specify the computer name in the format domain\username"
        Return
    }
    
    Write-Debug "Creating GPMGMT.GPM"   
    
    $gpm=New-Object -COM "GPMGMT.GPM"
    $gpmconstants=$gpm.getconstants()
    
    #Default report type is HTML but if you specify -xml you will 
    #get an XML report    
    if ($xml) {
        Write-Debug "XML switch detected"
        $Report=$gpmconstants.ReportXML
        $file=Join-Path $filepath "$user-$machine.xml"
    }
    else {
        $Report=$gpmconstants.ReportHTML        
        $file=Join-Path $filepath "$user-$machine.html"
    }
    
    Write-Debug "`$File set to $file"
    $rsop=$gpm.GetRSOP($gpmconstants.RSOPModeLogging,$null,0)
    $rsop.LoggingComputer=$computername
    
    Write-Debug "Enumerating Users"
    $users=$rsop.LoggingEnumerateusers()       
    $users | Out-String | Write-Debug
    
    Write-Debug "Checking to see if $username has logged on to $computername"
    $found=$users | where {$_.TrusteeName -match $user -AND $_.TrusteeDomain -match $domain}
      
    if (!$found) {
        Write-Warning "Failed to find $username on $computername"
        Return
    }
    
    Write-Debug "$username found on $computername"
    
    Write-Debug "Generating Query results"
    $rsop.CreateQueryResults()
    
    Write-Debug "Generating Report to File"
    $report=$rsop.GenerateReportToFile($Report,$file)
 
    if ($Report.Result) {
        Write-Host "Report complete. See" $report.result -ForegroundColor Cyan
    }
    else {
        Write-Warning "There was an error creating $file."
    }

}
