# Rename-User.ps1

Function Rename-User {
    Param([string]$sam=$(Throw "You must enter the user's original SAMACCOUNTNAME"),
          [string]$lastname=$(Throw "You must enter the user's original LASTNAME"),
          [string]$newname=$(Throw "You must enter the user's new LASTNAME"),
          [boolean]$properCase=$TRUE
         )
            
    $errorActionPreference="SilentlyContinue"
    
    Function New-UserProperties {
        Param([string]$sam=$(Throw "You must enter the user's original SAMACCOUNTNAME"),
              [string]$lastname=$(Throw "You must enter the user's original LASTNAME"),
              [string]$newname=$(Throw "You must enter the user's new LASTNAME"),
              [boolean]$properCase=$TRUE
             )
             
        #Create a new custom object
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name samAccountName -Value ($sam -Replace $lastname,$newname)
    
        #By default the function will convert $newname to proper case
        #when used for lastname, displayname and new AD object name
        #Pass a $FALSE value to $propercase if you do not want this
        #behavior.
        if ($properCase) { 
            $newname=$newname.substring(0,1).toUpper()+$newname.substring(1)
            }
            
        $obj | Add-Member -MemberType NoteProperty -Name LastName -Value $newname
        $obj | Add-Member -MemberType NoteProperty -Name UserPrincipalname -Value ($user.userprincipalname -Replace $lastname, $newname)
        $obj | Add-Member -MemberType NoteProperty -Name DisplayName -Value ($user.displayname -Replace $lastname,$newname)
        
        write $obj  
    }
    
    Function Revise-Properties {
        Param([system.object]$obj)
        
        if ($obj) {
             #prompt for new values
            $rc = Read-Host "Enter a value for the new SAMACCOUNTNAME. Press enter to keep" $obj.samaccountname
        
            if ($rc) { 
                $obj | Add-Member -MemberType NoteProperty -Name samAccountName -Value $rc -force
            } 
        
            $rc = Read-Host "Enter a value for the new LASTNAME. Press enter to keep" $obj.lastname
        
            if ($rc) { 
                $obj | Add-Member -MemberType NoteProperty -Name LastName -Value $rc -force
            }
        
            $rc = Read-Host "Enter a value for the new USERPRINCIPALNAME. Press enter to keep" $obj.userprincipalname
        
            if ($rc) { 
                $obj | Add-Member -MemberType NoteProperty -Name UserPrincipalname -Value $rc -force
            }           
        
            $rc = Read-Host "Enter a value for the new DISPLAYNAME. Press enter to keep" $obj.displayname
        
            if ($rc) { 
                $obj | Add-Member -MemberType NoteProperty -Name DisplayName -Value $rc -force
            }

        }
        else {
            write "No object passed to revise"
            break
        }
        
        write $obj
        
    }
    
    Function Prompt-User {
        Param([system.object]$obj)
        
        $rc = Read-Host "Do you want to make these changes? Enter N to edit values. [YN]"
        
        if ($rc -match "y") {
        #this function assumes the user object name is the same as their display nam
            Rename-QADObject $script:user -newname $obj.Displayname  | `
            Set-QADUser -samaccount $obj.samaccountname -userprincipal $obj.userprincipalname `
            -display $obj.displayname -LastName $obj.LastName
        }
        else {
            $renamed = Revise-Properties $renamed
            $renamed | Format-List *
            Prompt-User $renamed
        }
    }
    
    #this is the main part of the function
    $script:user=Get-QADUser "$env:userdomain\$sam"
    
    if ($script:user) {
        Write "Renaming $script:user"
        $renamed=New-UserProperties -sam $sam -lastname $lastname -newname $newname -propercase $properCase
        $renamed | Format-List *
        Prompt-User $renamed
    }
    else {
        write "Failed to find $env:userdomain\$sam"
    }
}

#sample usage
#Rename-User -sam jjones -lastname jones -newname smith

