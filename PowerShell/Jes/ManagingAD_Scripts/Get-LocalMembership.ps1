#Get-LocalMembership.ps1

Function Get-LocalMembership {
    Param([string]$group=$(Throw "You must enter a group name."),
          [string]$computer=$env:computername
          )

    [ADSI]$LocalGroup="WinNT://$computer/$group,group"

    $LocalGroup.psbase.invoke("Members") | ForEach-Object {
    
    #get ADS Path of member
    $ADSPath=$_.GetType().InvokeMember("ADSPath", 'GetProperty', `
    $null, $_, $null)
    
    #get the member class, ie user or group
    $class=$_.GetType().InvokeMember("Class", 'GetProperty', `
    $null, $_, $null)
    
    #Get the name property
    $name=$_.GetType().InvokeMember("Name", 'GetProperty', `
    $null, $_, $null)
    
    #Domain members will have an ADSPath like 
    #WinNT://MYDomain/Domain Users.  Local accounts will have
    #be like WinNT://MYDomain/Computername/Administrator

    $domain=$ADSPath.Split("/")[2]

    #if computer name is found between two /, then assume
    #the ADSPath reflects a local object
    if ($ADSPath -match "/$env:computername/") {
        $local=$True
        }
    else {
        $local=$False
       }

    #create a custom object
    $obj = New-Object PSObject
    
    #define custom object properties
    $obj | Add-Member -MemberType NoteProperty -Name "Computer" -Value $computer.toUpper()
    $obj | Add-Member -MemberType NoteProperty -Name "ADSPath" -Value $ADSPath
    $obj | Add-Member -MemberType NoteProperty -Name "Domain" -Value $domain 
    $obj | Add-Member -MemberType NoteProperty -Name "IsLocal" -Value $local 
    $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $name 
    $obj | Add-Member -MemberType NoteProperty -Name "Class" -Value $class 
         
    #write the result to the pipeline
    write $obj
    }  
}

#sample usage:
#  Get-LocalMembership -group "Administrators"
#  Get-LocalMembership -computer localhost -group "Administrators"
