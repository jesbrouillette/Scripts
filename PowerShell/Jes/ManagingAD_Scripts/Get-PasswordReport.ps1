#Get-PasswordReport.ps1

Function Get-PasswordReport {
# This function writes a custom object for each non-disabled
# user account in your Active Directory domain to the pipeline

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

$Searcher = New-Object DirectoryServices.DirectorySearcher

# find all non-disabled user objects
$searcher.filter="(&(objectCategory=person)(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2))"

$searcher.findall() | ForEach-Object {

    $obj=New-Object PSObject
    
    $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $_.properties.item("name")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "DN" -Value $_.properties.item("distinguishedname")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $_.properties.item("description")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "AccountCreated" -Value $_.properties.item("whencreated")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "AccountModified" -Value $_.properties.item("WhenChanged")[0]
    $obj | Add-Member -MemberType NoteProperty -Name "LastChanged" -Value (Get-PwdLastSetDate $_.properties.item("pwdlastset")[0])
    $obj | Add-Member -MemberType NoteProperty -Name "PasswordAge" -Value (Get-PwdAge $_.properties.item("pwdlastset")[0])
    
    write $obj
 }

}



