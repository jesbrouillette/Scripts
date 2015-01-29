# Get-RSOP.ps1

Function Get-RSOP {
    Param([string]$OUPath,
          [string]$ReportPath="C:\RSOP.html",
          [switch] $xml
          )
    
    #This function assumes you are querying within the same domain
       
    $ad=New-Object System.DirectoryServices.DirectoryEntry
    #$domainDN will be a string like DC=Mycompany,DC=Local
    
    $domainDN=$ad.distinguishedname
    
    #create the distinguished name for a SOM to be used in planning
    if ($OUPath) {
        $SOM="$OUPath,$domainDN"
    }
    else {
        $SOM=$domainDN
    }
    
    $gpm=New-Object -COM "GPMGMT.GPM"
    $gpmconstants=$gpm.getconstants()
    
    #Default report type is HTML but if you specify -xml you will 
    #get an XML report
    
    if ($xml) {
        $Report=$gpmconstants.ReportXML
    }
    else {
        $Report=$gpmconstants.ReportHTML
    }
    
    $rsop=$gpm.GetRSOP($gpmconstants.RSOPModePlanning,$null,0)
    
    #use the %LOGONSERVER% but strip out the leading \\
    $rsop.PlanningDomainController=($env:logonserver).substring(2)
    $rsop.PlanningUserSOM=$domainDN
    $rsop.PlanningComputerSOM=$SOM
    
    Write-Host "Creating RSOP for $SOM" -ForegroundColor Cyan
    
    $rsop.CreateQueryResults()
    $rsop.GenerateReportToFile($Report,$ReportPath)

}

#Sample Usage
# Get-RSOP
# Get-RSOP "OU=Sales,OU=Employees"
# Get-RSOP "OU=Company Desktops" "c:\desktops.xml" -xml

#Notes:

    # GPMGMT Constants
    # permGPOApply                          : 65536
    # permGPORead                           : 65792
    # permGPOEdit                           : 65793
    # permGPOEditSecurityAndDelete          : 65794
    # permGPOCustom                         : 65795
    # permWMIFilterEdit                     : 131072
    # permWMIFilterFullControl              : 131073
    # permWMIFilterCustom                   : 131074
    # permSOMLink                           : 1835008
    # permSOMLogging                        : 1573120
    # permSOMPlanning                       : 1573376
    # permSOMGPOCreate                      : 1049600
    # permSOMWMICreate                      : 1049344
    # permSOMWMIFullControl                 : 1049345
    # SearchPropertyGPOPermissions          : 0
    # SearchPropertyGPOEffectivePermissions : 1
    # SearchPropertyGPODisplayName          : 2
    # SearchPropertyGPOWMIFilter            : 3
    # SearchPropertyGPOID                   : 4
    # SearchPropertyGPOComputerExtensions   : 5
    # SearchPropertyGPOUserExtensions       : 6
    # SearchPropertySOMLinks                : 7
    # SearchPropertyGPODomain               : 8
    # SearchPropertyBackupMostRecent        : 9
    # SearchOpEquals                        : 0
    # SearchOpContains                      : 1
    # SearchOpNotContains                   : 2
    # SearchOpNotEquals                     : 3
    # UsePDC                                : 0
    # UseAnyDC                              : 1
    # DoNotUseW2KDC                         : 2
    # somSite                               : 0
    # somDomain                             : 1
    # somOU                                 : 2
    # DoNotValidateDC                       : 1
    # ReportHTML                            : 1
    # ReportXML                             : 0
    # RSOPModeUnknown                       : 0
    # RSOPModePlanning                      : 1
    # RSOPModeLogging                       : 2
    # EntryTypeUser                         : 0
    # EntryTypeComputer                     : 1
    # EntryTypeLocalGroup                   : 2
    # EntryTypeGlobalGroup                  : 3
    # EntryTypeUniversalGroup               : 4
    # EntryTypeUNCPath                      : 5
    # EntryTypeUnknown                      : 6
    # DestinationOptionSameAsSource         : 0
    # DestinationOptionNone                 : 1
    # DestinationOptionByRelativeName       : 2
    # DestinationOptionSet                  : 3
    # MigrationTableOnly                    : 1
    # ProcessSecurity                       : 2
    # RsopLoggingNoComputer                 : 65536
    # RsopLoggingNoUser                     : 131072
    # RsopPlanningAssumeSlowLink            : 1
    # RsopPlanningAssumeUserWQLFilterTrue   : 8
    # RsopPlanningAssumeCompWQLFilterTrue   : 16

# RSOP object properties
    # Mode                           
    # Namespace                      
    # LoggingComputer                
    # LoggingUser                    
    # LoggingFlags                   
    # PlanningFlags                  
    # PlanningDomainController       
    # PlanningSiteName               
    # PlanningUser                   
    # PlanningUserSOM                
    # PlanningUserWMIFilters         
    # PlanningUserSecurityGroups     
    # PlanningComputer               
    # PlanningComputerSOM            
    # PlanningComputerWMIFilters     
    # PlanningComputerSecurityGroups 
