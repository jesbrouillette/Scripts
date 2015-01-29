#Get-PasswordSettings.ps1

Function Get-PasswordSettings {

    Function Get-Name {
        Param([string]$DN=$(Throw "You must enter a distinguished name"))
        
        $searcher=New-Object DirectoryServices.DirectorySearcher
        $searcher.filter="distinguishedname=$DN"
        $principal=$searcher.findOne()
        $name=$principal.properties.item('name')
        
        if ($name) {
            write $name
            }
        else {
            write "not found"
            }       
    }

$days=-864000000000
$mins=-600000000

$searcher=New-Object DirectoryServices.DirectorySearcher
$searcher.filter="objectclass=msDS-PasswordSettings"

$results=$searcher.findall() 
 foreach ($pso in $results) {

    $obj=New-Object PSObject
    
    $obj | Add-Member -MemberType NoteProperty -Name "Name"  -Value $pso.properties.item('name')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "DN"  -Value $pso.properties.item('distinguishedName')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "Created"  -Value $pso.properties.item('whencreated')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "Modified"  -Value $pso.properties.item('whenchanged')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "Precedence"  -Value $pso.properties.item('msds-passwordsettingsprecedence')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "MinAge"  -Value ($pso.properties.item('msds-minimumpasswordage')[0]/$days)
    $obj | Add-Member -MemberType NoteProperty -Name "MaxAge"  -Value ($pso.properties.item('msds-maximumpasswordage')[0]/$days)
    $obj | Add-Member -MemberType NoteProperty -Name "MinLength" -Value $pso.properties.item('msds-minimumpasswordlength')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "LockoutTime" -Value ($pso.properties.item('msds-lockoutduration')[0]/$mins)
    $obj | Add-Member -MemberType NoteProperty -Name "LockoutThreshold" -Value $pso.properties.item('msds-lockoutthreshold')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "LockoutObservation" -Value ($pso.properties.item('msds-lockoutobservationwindow')[0]/$mins)
    $obj | Add-Member -MemberType NoteProperty -Name "History"  -Value $pso.properties.item('msds-passwordhistorylength')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "Complexity" -Value $pso.properties.item('msds-passwordcomplexityenabled')[0]
    $obj | Add-Member -MemberType NoteProperty -Name "ReversibleEncryption"  -Value $pso.properties.item('msds-passwordreversibleencryptionenabled')[0]
    
    if ($pso.properties.item('msds-psoappliesto').count -gt 0) {
    $members=@()
      for ($i=0;$i -lt $pso.properties.item("msds-psoappliesto").count;$i++) { 
        $members += Get-Name ($pso.properties.item("msds-psoappliesto")[$i])
         }
        }   
    else {
        $members="None"
    }
    
    $obj | Add-Member -MemberType NoteProperty -Name "AppliesTo" -Value $members
    
    write $obj
 }
}

#sample usage
# Get-PasswordSettings
# Get-PasswordSettings | sort precedence | Format-Table Name,MinAge,MaxAge,MinLength
# Get-PasswordSettings | sort WhenCreated | select DN,Name,Created,Modified,AppliesTo
