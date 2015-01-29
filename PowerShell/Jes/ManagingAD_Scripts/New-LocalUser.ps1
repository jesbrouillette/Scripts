# New-LocalUser.ps1

Function New-LocalUser {

    Param([string]$computer=$env:computername,
          [string]$User=$(Throw "You must enter a user name"),
          [string]$Password="P@ssw0rd",
          [string]$Description,
          [string]$FullName,
          [string]$Expires,
          [string]$HomeDir,
          [string]$Profile,
          [string]$HomeDirDrive,
          [boolean]$PwdNeverExpires=$False,
          [boolean]$Disabled=$False,
          [boolean]$ForcePwdChange=$False,
          [boolean]$NoPwdChangeAllowed=$False
    )

     New-Variable ADS_UF_ACCOUNTDISABLE 0x0002 -Option Constant
     New-Variable ADS_UF_PASSWD_CANT_CHANGE 0x0040 -Option Constant
     New-Variable ADS_UF_DONT_EXPIRE_PASSWD 0x10000 -Option Constant

    [ADSI]$Server="WinNT://$computer"
    
    $NewUser=$server.Create("user",$User)
    $NewUser.SetPassword($password)
    $NewUser.SetInfo()
    
    if ($Description) {
        $NewUser.psbase.Properties.item("Description").value=$Description
        }
        
    if ($FullName) {
        $NewUser.psbase.Properties.item("FullName").value=$FullName
        }
        
    if ($HomeDir) {
        $NewUser.psbase.Properties.item("HomeDirectory").value=$HomeDir
        }
    
    if ($Profile) {
        $NewUser.psbase.Properties.item("Profile").value=$Profile
        }
        
    if ($HomeDirDrive) {
        $NewUser.psbase.Properties.item("HomeDirDrive").value=$HomeDirDrive
        }
    
    if ($Expires) {
        $NewUser.psbase.Properties.item("AccountExpirationDate").value=`
        [datetime]$Expires
         } 
         
    if ($Disabled) {
        $NewUser.psbase.properties.item("userflags").value=`
         $NewUser.psbase.properties.item("userflags").value -bor `
         $ADS_UF_ACCOUNTDISABLE
        }     
    
    if ($PwdNeverExpires) {
        $NewUser.psbase.properties.item("userflags").value=`
         $NewUser.psbase.properties.item("userflags").value -bor `
         $ADS_UF_DONT_EXPIRE_PASSWD
        }  
    
    if ($ForcePwdChange) {
        $NewUser.psbase.properties.item("passwordexpired").value=1
        } 
    
    if ($NoPwdChangeAllowed) {
        $NewUser.psbase.properties.item("userflags").value=`
         $NewUser.psbase.properties.item("userflags").value -bor `
         $ADS_UF_PASSWD_CANT_CHANGE
        } 
        
    $NewUser.SetInfo()
    
    $NewUser.Psbase.RefreshCache()
    $NewUser | Format-List *

}
