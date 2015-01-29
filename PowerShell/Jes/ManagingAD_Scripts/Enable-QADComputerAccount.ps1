#Enable-QADComputerAccount.ps1

Function Enable-QADComputerAccount {
   Param([string]$computer=$(Throw "You must enter a computer name"),
         [switch]$disable)

    New-Variable UF_ACCOUNTDISABLE  0x2 -option Constant
    
    $computerObject=Get-QADComputer $computer
    if ($computerObject) {
    
             If ($disable) {
            #check and see if account is already disabled
            if ($computerObject.Useraccountcontrol -band $UF_ACCOUNTDISABLE) {
            Write-Host "$computer is already disabled"
            return }

            $UAC = $computerObject.Useraccountcontrol -bor $UF_ACCOUNTDISABLE
 
        }
        else {
        #enable the account
        #only enable the account if it is already disabled
            if ($computerObject.Useraccountcontrol -band $UF_ACCOUNTDISABLE) {
             $UAC = $computerObject.Useraccountcontrol -bxor $UF_ACCOUNTDISABLE
            }
            else {
            Write-Host "$computer is already enabled"
            return
            }
        }
        #set the new UAC value
        Set-QADObject $computer -ObjectAttributes @{"userAccountControl"=$UAC}
    }
    else {
       Write-Host "Failed to find $computer" -ForegroundColor Red
    }

}

#sample usage
#Enable-QADComputerAccount "VistaDesk20" 
#Enable-QADComputerAccount "VistaDesk20" -disable
