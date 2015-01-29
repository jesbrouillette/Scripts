#Get-DomainPWDProperties.ps1

Function Get-PWDProperties {
    Param([int]$flag=$(Throw "You must specify a property flag value."))
    
    # constant values for pwdProperties bitmask flag
    New-Variable DOMAIN_PASSWORD_COMPLEX 1 -option constant
    New-Variable DOMAIN_PASSWORD_NO_ANON_CHANGE 2 -option constant
    New-Variable DOMAIN_PASSWORD_NO_CLEAR_CHANGE 4 -option constant
    New-Variable DOMAIN_LOCKOUT_ADMINS 8 -option constant
    New-Variable DOMAIN_PASSWORD_STORE_CLEARTEXT 16 -option constant
    New-Variable DOMAIN_REFUSE_PASSWORD_CHANGE 32 -option constant
    
    if ($flag -band $DOMAIN_PASSWORD_COMPLEX) {
         write "Complex passwords required"
        }
    
    if ($flag -band $DOMAIN_PASSWORD_NO_ANON_CHANGE) {
         write "Anonymous change not allowed"
        }
    
    if ($flag -band $DOMAIN_PASSWORD_NO_CLEAR_CHANGE) {
         write "No clear change allowed"
        }
    
    if ($flag -band $DOMAIN_LOCKOUT_ADMINS) {
         write "Admin lockout allowed"
        }
        
    if ($flag -band $DOMAIN_PASSWORD_STORE_CLEARTEXT) {
         write "Reversible encryption enabled"
        }
    
    if ($flag -band $DOMAIN_REFUSE_PASSWORD_CHANGE) {
         write "Refuse domain password change"
        }
    
}

#Sample usage
# [ADSI]$root="LDAP://RootDSE"
# [ADSI]$domain="LDAP://" + $root.defaultnamingcontext
# Write-Host ($domain.name).tostring().toUpper() "Password Settings"
# Get-PWDProperties $domain.pwdproperties.value
