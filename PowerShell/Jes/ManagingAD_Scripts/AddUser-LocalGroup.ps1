#AddUser-LocalGroup.ps1

Function AddUser-LocalGroup {
    Param([string]$group=$(Throw "You must enter a group name"),
        [string]$user=$(Throw "You must enter a user name"),
        [string]$computer=$env:computername
        )
    
    [ADSI]$LocalGroup="WinNT://$computer/$group,group"
    $LocalGroup.Add("WinNT://$user,user")
    $LocalGroup.SetInfo()
    
}

#sample usage
# AddUser-LocalGroup -group "Power Users" -user "Jeff"

# this is how to add a domain member
# adduser-localgroup "local administrators" "company/rgbiv"

