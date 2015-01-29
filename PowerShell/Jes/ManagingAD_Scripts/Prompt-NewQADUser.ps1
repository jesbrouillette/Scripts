#Prompt-NewQADUser.ps1

$cmd="New-Qaduser"

#a list of typically set new user parameters
$p="ParentContainer","Name","SamAccountName","UserPrincipalName","FirstName","Initials",`
"LastName","Description","DisplayName","UserPassword","Department","PhoneNumber","Office",`
"Company","StreetAddress","PostOfficeBox","City","StateOrProvince","PostalCode","HomePhone",`
"Manager","MobilePhone","Notes","Fax","Pager","WebPage","ObjectAttributes"

#go through each parameter and build a command string
Write-Host "When prompted to enter a parameter value, enclose it in quotes. `r`
Press Enter to leave it empty, type Exit to stop prompts or Abort to quit completely."

$p | foreach {
    $paramname=$_
    $value=Read-Host "Enter a value for $paramname "
    
    Switch -regex ($value) {
        "exit" {$done=$True;Break}
        "abort" {$abort=$True;break}
        #only build a command for something entered
        "\S+" {$cmd = $cmd + " -$paramname " + $value}
    }
    
    if ($abort) {
        Break
        }
    elseif ($done) {
        Write-Host $cmd -ForegroundColor cyan
        $rc=Read-Host "Do you want to run this command?[YN]"
        if ($rc -match "Y") {Invoke-Expression $cmd}
        Break
        }
}

write-host $cmd -ForegroundColor cyan

$rc=Read-Host "Do you want to run this command?[YN]"

if ($rc -match "Y") {
  Invoke-Expression $cmd
  }

