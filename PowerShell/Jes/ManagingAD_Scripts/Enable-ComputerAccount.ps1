#Enable-ComputerAccount.ps1

Function Enable-ComputerAccount {
    Param([string]$computer=$(Throw "You must enter a computer name"),
    [switch]$disable)

    New-Variable UF_ACCOUNTDISABLE  0x2 -option Constant    
    
    #find computer account
    $searcher=New-Object DirectoryServices.DirectorySearcher
    $searcher.Filter="(&(objectcategory=computer)(cn="+$computer+"))"
    $result=$searcher.findOne()
    If ($result.path) {
      [ADSI]$computerObject=$result.path   

         If ($disable) {
            #check and see if account is already disabled
            if ($computerObject.Useraccountcontrol.value -band $UF_ACCOUNTDISABLE) {
            Write-Host "$computer is already disabled"
            return }

            $UAC = $computerObject.Useraccountcontrol.value -bor $UF_ACCOUNTDISABLE
 
        }
        else {
        #enable the account
        #only enable the account if it is already disabled
            if ($computerObject.Useraccountcontrol.value -band $UF_ACCOUNTDISABLE) {
             $UAC = $computerObject.Useraccountcontrol.value -bxor $UF_ACCOUNTDISABLE
            }
            else {
            Write-Host "$computer is already enabled"
            return
            }
        }
        
        #set the new UAC value
         $computerObject.put("userAccountControl", $UAC)
         $computerObject.setinfo()  
                    
     } #end if $result.path   
    else {
        Write-Host "Failed to find $computer" -ForegroundColor Red
    }
}

#sample usage
#Enable-ComputerAccount "VistaDesk20" 
#Enable-ComputerAccount "VistaDesk20" -disable
