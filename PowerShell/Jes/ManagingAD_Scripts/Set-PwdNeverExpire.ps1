#Set-PwdNeverExpire.ps1

Function Set-PwdNeverExpire {
    Param ([string]$sam=$(throw "you must enter a sAMAccountname"),
           [boolean]$NeverExpire=$True)
    
    Function Get-UserDN {
        Param ([string]$sam=$(throw "you must enter a sAMAccountname"))
        
        $searcher=New-Object DirectoryServices.DirectorySearcher
        $searcher.Filter="(&(objectcategory=person)(objectclass=user)(sAMAccountname="+$sam+"))"
    
        $user=$searcher.FindOne()
        
        if ($user.path) {
            write $user
        } 
        else {
            write "NotFound"
        }
}

#main part of the function
    $dn=Get-UserDN $sam
    
    #only run if user distinguishedname  was found
    if ($dn.path) {
    
        [ADSI]$user=$dn.path
        
        New-Variable ADS_UF_DONT_EXPIRE_PASSWD 0x10000 -Option Constant
        
      	[int]$flag=$user.useraccountcontrol[0]

        if ($NeverExpire) {
            $user.useraccountcontrol=$flag -bor $ADS_UF_DONT_EXPIRE_PASSWD
            $user.setinfo()
          }
         else {
         #remove flag
            $user.useraccountcontrol=$flag -bxor $ADS_UF_DONT_EXPIRE_PASSWD
            $user.setinfo()
         }
        
        }
        
    else {
        write "Failed to find $sam"   
    }

}

