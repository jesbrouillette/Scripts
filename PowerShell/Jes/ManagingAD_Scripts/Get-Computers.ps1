#Get-Computers.ps1

Function Get-Computers {
# This function writes a custom object for each computer
# object in your Active Directory domain to the pipeline

    Function Get-PwdLastSetDate {
    
        Param([int64]$LastSet=0)
        if ($LastSet -eq 0) {
            write "Never Set or Re-Set"
        } else {
            [datetime]$utc="1/1/1601"
            $i=$LastSet/864000000000
            write ($utc.AddDays($i))
        }
    }
    
    Function Get-PwdAge {
    
        Param([int64]$LastSet=0)
        if ($LastSet -eq 0) {
            write "0"
        } else {
            [datetime]$ChangeDate=Get-PwdLastSetDate $LastSet
            [datetime]$RightNow=Get-Date
            
            write $RightNow.Subtract($ChangeDate).Days
        }
    }

    $searcher=New-Object DirectoryServices.DirectorySearcher
    $searcher.Filter="(&(objectCategory=Computer)(objectClass=Computer))"
    
    $searcher.findall() | ForEach-Object {

    $obj=New-Object PSObject
    
    $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $_.properties.item("name")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "DN" -Value $_.properties.item("distinguishedname")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "DNSName" -Value $_.properties.item("dnshostname")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "OS" -Value $_.properties.item("operatingsystem")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "ServicePack" -Value $_.properties.item("operatingsystemservicepack")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "OSVersion" -Value $_.properties.item("operatingsystemversion")[0] 
    $obj | Add-Member -MemberType NoteProperty -Name "AccountCreated" -Value $_.properties.item("whencreated")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "AccountModified" -Value $_.properties.item("WhenChanged")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "PasswordLastChanged" -Value (Get-PwdLastSetDate $_.properties.item("pwdlastset")[0])
    $obj | Add-Member -MemberType NoteProperty -Name "PasswordAge" -Value (Get-PwdAge $_.properties.item("pwdlastset")[0])
    
    write $obj
 }

}

#sample usage
#get-computers 
#get-computers | Sort PasswordAge | Select DN,DNSName,Password*

