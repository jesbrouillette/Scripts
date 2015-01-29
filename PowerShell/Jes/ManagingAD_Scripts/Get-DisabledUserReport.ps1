#Get-DisabledUserReport.ps1

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

$Searcher = New-Object DirectoryServices.DirectorySearcher

$searcher.filter="(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))"

$searcher.findall() | Format-Table `
@{label="DN";expression={$_.properties.distinguishedname}},`
@{label="Last Modified";expression={$_.properties.whenchanged}},`
@{label="PWDLastSet";expression={Get-PwdLastSetDate $_.properties.item("pwdlastset")[0]}} -autosize

