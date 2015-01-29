#Get-QADComputerAge.ps1

$computers=Get-QADComputer -IncludedProperties pwdLastSet

$computers | foreach {
    [int]$pwdAge=(Get-Date).Subtract($_.pwdLastSet).TotalDays
    $_ | Add-Member -MemberType NoteProperty -Name "PasswordAge" -Value $pwdage -PassThru
   }

