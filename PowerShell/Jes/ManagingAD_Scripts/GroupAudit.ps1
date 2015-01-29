#GroupAudit.ps1

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

#the text list of computers
$source="c:\computers.txt"

#the name of the file to create
$report="c:\groupaudit.html"

#a counter
$i=0

Get-Content $source | ForEach-Object {
    $i++
    $perComplete=($i/(Get-Content $source).count)*100
    
    Write-Progress -Activity "Enumerating groups on $_" -Status "Connecting" -PercentComplete $perComplete
     [ADSI]$server="WinNT://$_"
    Write-Progress -Activity "Enumerating groups on $_" -Status "Getting groups" -PercentComplete $perComplete
    
    $groups=$server.psbase.children | where {$_.psbase.schemaclassname -eq "group"} | `
     select -ExpandProperty Name
     if ($groups) {
      $count=$groups.count}
     else {
      $count=0
     }
     
    Write-Progress -Activity ($server.name).toString().ToUpper() -Status "Found $count groups"
     
     $groups | ForEach-Object {
        $group=$_
        Write-Progress -Activity "Getting group members" -status $group -id 1
         Get-LocalMembership -group $_  -computer $server.name | `
         select @{Name="Server";Expression={$server.name}},@{Name="Group";`
        Expression={$group}},Domain,Name,IsLocal,Class
     }
     Write-Progress -Activity "Finished getting members" -Status "Done" -Completed -Id 1
} | ConvertTo-Html -title "Group Audit Report" | Out-File $report

Write-Progress -Activity "Finished enumeration" -Status "Done!" -Completed

Write-Host "Finished.  See $report for results." -ForegroundColor Cyan
