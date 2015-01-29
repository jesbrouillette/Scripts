#Get-GPOAdminTemplate.ps1
#This function requires the GPExpert Scripting Toolkit from SDMSoftware
#this is designed to return settings from Administrative Templates

Function Get-GPOAdminTemplate {
    Param([string]$computer=$env:computername,
     [string]$node="Computer",
     [string]$path=$(Throw "You must specify a path to the GPO under administrative templates")
     )
    
    $errorActionPreference="SilentlyContinue"
    
    switch ($node) {
        "computer" {$nodepath="Computer Configuration"}
        "user" {$nodepath="User Configuration"}
        default {
            Write-Warning "Valid -node choices are Computer or User"
            return
        }
    }
     
    $containerpath=$nodepath+"/Administrative Templates/"+$path
    $gpo = Get-SDMgpobject -gpoName "gpo://$computer/Local/"
    
    if (!(dir $gpo.fspath)) {
        Write-Warning "Failed to connect to gpo://$computer/Local/ or no local policies defined"
        return
    }
    
    $container = $gpo.GetObject($containerpath)
    
    if (!$container) {
        Write-Warning "Failed to find $containerpath"
        return
    }
    
    $container.settings | where {$_.name -notmatch "Properties"} | foreach {
        $setting=$container.Settings.ItemByName($_.Name)
        switch ($setting.Get("State")) {
            -1 {$state="Not Configured" }
             0 {$state="Disabled"}
             1 {$state="Enabled"}
         default { $state="Unknown" }
        }
        $obj=New-Object PSObject
        $obj | Add-Member -MemberType "NoteProperty" -Name "Computer" -Value $computer
        $obj | Add-Member -MemberType "NoteProperty" -Name "GPO" -Value $container.name
        $obj | Add-Member -MemberType "NoteProperty" -Name "GPOPath" -Value $containerpath
        $obj | Add-Member -MemberType "NoteProperty" -Name "Setting" -Value $_.Name
        $obj | Add-Member -MemberType "NoteProperty" -Name "State" -Value $state
        
        write $obj
    }
}

#sample usage
# Get-GPOAdminTemplate -node "User" -path "Windows Components/Windows Media Player"
# get-gpoadmintemplate -path "System/Scripts" | Select Setting,State
