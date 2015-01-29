#Get-LocalUserReport.ps1

Function Get-LocalUserReport {
    Param([string]$computer=$env:computername)
    
    New-Variable ADS_UF_ACCOUNTDISABLE 0x0002 -Option Constant
    New-Variable ADS_UF_PASSWD_CANT_CHANGE 0x0040 -Option Constant
    New-Variable ADS_UF_DONT_EXPIRE_PASSWD 0x10000 -Option Constant
    
    [ADSI]$server="WinNT://$computer"
    
    $users=$server.psbase.children | where {$_.psbase.schemaclassname -eq "user"}
    
    $users | ForEach-Object {
        #password age in days
        [int]$pwdAge="{0:N0}" -f (($_.PasswordAge).value/86400)
        
        if ($_.psbase.properties.item("passwordexpired") -eq 0) {
            $pwdExpired=$False
        }
        else {
            $pwdExpired=$True
        }
    
        if ($_.psbase.properties.item("userflags").value -band $ADS_UF_ACCOUNTDISABLE) {
            $disabled=$True
         }
         else {
            $disabled=$False
         }
    
        if ($_.psbase.properties.item("userflags").value -band $ADS_UF_DONT_EXPIRE_PASSWD) {
            $pwdNeverExpires=$True
         }
         else {
            $pwdNeverExpires=$False
         }
         
         if ($_.psbase.properties.item("userflags").value -band $ADS_UF_PASSWD_CANT_CHANGE) {
            $pwdChangeAllowed=$False
         }
         else {
            $pwdChangeAllowed=$True
         }
    
        # Create a custom object
        $obj=New-Object psobject
        
        $obj | Add-Member -MemberType "NoteProperty" -Name "Computer" -Value $computer.ToUpper()
        $obj | Add-Member -MemberType "NoteProperty" -Name "Name" -Value $_.name.value
        $obj | Add-Member -MemberType "NoteProperty" -Name "FullName" -Value $_.fullname.value
        $obj | Add-Member -MemberType "NoteProperty" -Name "Description" -Value $_.Description.value
        $obj | Add-Member -MemberType "NoteProperty" -Name "AccountExpires" -Value $_.AccountExpirationDate.value
        $obj | Add-Member -MemberType "NoteProperty" -Name "Disabled" -Value $disabled
        $obj | Add-Member -MemberType "NoteProperty" -Name "PasswordAge" -Value $pwdage    
        $obj | Add-Member -MemberType "NoteProperty" -Name "PasswordExpired" -Value $pwdExpired
        $obj | Add-Member -MemberType "NoteProperty" -Name "PasswordNeverExpires" -Value $pwdNeverExpires
        $obj | Add-Member -MemberType "NoteProperty" -Name "PasswordChangeAllowed" -Value $pwdChangeAllowed
        
        write $obj
     } 
     
}

#sample usage
#Get-LocalUserReport

