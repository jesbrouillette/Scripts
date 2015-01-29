#Get-DomainAccountPolicy.ps1

Function Get-PWDProperties {
# returns a text list of password flag values

    Param([int]$flag=$(Throw "You must specify a property flag value."))
    
    # constant values for pwdProperties bitmask flag
    New-Variable DOMAIN_PASSWORD_COMPLEX 1 -option constant
    New-Variable DOMAIN_PASSWORD_NO_ANON_CHANGE 2 -option constant
    New-Variable DOMAIN_PASSWORD_NO_CLEAR_CHANGE 4 -option constant
    New-Variable DOMAIN_LOCKOUT_ADMINS 8 -option constant
    New-Variable DOMAIN_PASSWORD_STORE_CLEARTEXT 16 -option constant
    New-Variable DOMAIN_REFUSE_PASSWORD_CHANGE 32 -option constant
    
    New-Variable data
    if ($flag -band $DOMAIN_PASSWORD_COMPLEX) {
    #     write "Complex passwords required"
        $data=$data+"Complex passwords required"
        }
    
    if ($flag -band $DOMAIN_PASSWORD_NO_ANON_CHANGE) {
    #     write "Anonymous change not allowed"
        $data=$data+",`nAnonymous change not allowed"
        }
    
    if ($flag -band $DOMAIN_PASSWORD_NO_CLEAR_CHANGE) {
    #     write "No clear change allowed"
        $data=$data+",`nNo clear change allowed"
        }
    
    if ($flag -band $DOMAIN_LOCKOUT_ADMINS) {
    #     write "Admin lockout allowed"
        $data=$data+",`nAdmin lockout allowed"
        }
        
    if ($flag -band $DOMAIN_PASSWORD_STORE_CLEARTEXT) {
    #     write "Reversible encryption enabled"
        $data=$data+",`nReversible encryption enabled"
        }
    
    if ($flag -band $DOMAIN_REFUSE_PASSWORD_CHANGE) {
    #     write "Refuse domain password change"
        $data=$data+",`nRefuse domain password change"
        }
    
    write $data

}

Function Convert-ADSLargeInteger {
# Take a large value integer and return a 32 bit value
# Thanks to Brandon Shell for the function

    Param([object]$adsLargeInteger=$(Throw "You must specify an object."))

    $highPart = $adsLargeInteger.GetType().InvokeMember("HighPart",'GetProperty', `
    $null, $adsLargeInteger, $null)
    $lowPart  = $adsLargeInteger.GetType().InvokeMember("LowPart",'GetProperty', `
    $null, $adsLargeInteger, $null)
    $bytes = [System.BitConverter]::GetBytes($highPart)
    $tmp   = [System.Byte[]]@(0,0,0,0,0,0,0,0)
    [System.Array]::Copy($bytes, 0, $tmp, 4, 4)
    $highPart = [System.BitConverter]::ToInt64($tmp, 0)
    $bytes = [System.BitConverter]::GetBytes($lowPart)
    $lowPart = [System.BitConverter]::ToUInt32($bytes, 0)

    write ($lowPart + $highPart)
}

#connection credentials are optional
$admin="mycompany\administrator"
$pwd="P@ssw0rd"

#the ADSI path to the domain root
$DN="LDAP://yourcompany.local"

$DSRoot = New-Object DirectoryServices.DirectoryEntry $DN,$admin,$pwd

$msg="Account Policies for {0}" -f ($DSRoot.DC.Value.ToUpper())

Write-Host $msg

$DSRoot | Format-List `
@{label="Minimum Password Length";Expression={$_.MinPwdLength}},`
@{label="Password History";Expression={$_.PwdHistoryLength}},`
@{label="Lockout Threshold";Expression={$_.LockoutThreshold}},`
@{label="Lockout Duration (min)";Expression={(Convert-ADSLargeInteger `
$_.lockoutduration.value)/-600000000 }},`
@{label="Lockout Window (min)";Expression={(Convert-ADSLargeInteger `
$_.lockoutobservationWindow.value)/-600000000 }},`
@{label="Password Properties";Expression={Get-PWDProperties $_.PwdProperties.value}},`
@{label="Max Password Age (days)";Expression={(Convert-ADSLargeInteger `
$_.maxpwdage.value) /-864000000000}},`
@{label="Min Password Age (days)";Expression={(Convert-ADSLargeInteger `
$_.minpwdage.value) /-864000000000}}

