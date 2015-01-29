#Get-PasswordAge.ps1

Function Get-PasswordAge {
    Param([string]$computer=$env:computername,
          [string]$account="Administrator"
    )

    $errorActionPreference="SilentlyContinue"

    [ADSI]$user="WinNT://$computer/$account,user"
    
    if ($user.name) {
        [int]$age=($user.passwordAge[0])/86400
        [datetime]$lastchanged=(Get-Date).addDays(-$age)
    
        $obj=New-Object PSObject
    
        $obj | Add-Member -MemberType NoteProperty -Name "Computer" -Value $computer.ToUpper()
        $obj | Add-Member -MemberType NoteProperty -Name "Account" -Value $account.ToUpper()
        $obj | Add-Member -MemberType NoteProperty -Name "PasswordAge" -Value $age
        $obj | Add-Member -MemberType NoteProperty -Name "LastChanged" -Value $lastchanged

        write $obj
   
    } else {
        $msg="Failed to connect to {0}" -f ($computer.toUpper())
        Write-Warning $msg      
    }

}

#sample usage
#localhost
# Get-PasswordAge

#member server
# set-passwordage -computer server01

#domain
# get-passwordage -computer mydomain -account auser
# Get-PasswordAge $env:userdomain administrator
