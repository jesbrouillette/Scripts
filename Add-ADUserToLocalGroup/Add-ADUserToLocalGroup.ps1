$local_group = $ENV:LOCAL_GROUP
$ad_domain   = $ENV:AD_DOMAIN_NAME

# Searching for the users email account that launched the instance in Self Service.
$user_email  = rs_tag --list  | ? { $_ -notmatch "\[|\]" -and $_ -match "servicenow:launched_by"} | % { $_ -replace "^\s\s|[`",]","" } | % { $_.Split("=")[1] }

if ($user_email) {
    Import-Module ServerManager
    
    # Install the AD tools for PowerShell if they are not already.
    if (!(Get-WindowsFeature -Name RSAT-AD-PowerShell).Installed) {
        Write-Host "Installing the AD tools for PowerShell."
        Add-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature | Out-Null
    }
    
    Import-Module ActiveDirectory

    # Searching for the domain account of the user with an email matching the launch account.
    $user = get-aduser -filter {mail -eq $user_email } | select -ExpandProperty SamAccountName

    # Search for the domain account in the local group.
    #   Only add if it is not already a member.
    #   Report if it is.
    if ($user) {

        # Validating the user is not already in the local group.
        $local_members = @(([ADSI]"WinNT://localhost/$local_group,group").psbase.Invoke("Members") | % { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) } )
        if ($local_members -contains $user) {
            Write-Host "The user $user `($user_email`) is already a member of the local $local_group group."
            Break
        }
    
        # Adding the user to the local group.
        ([ADSI]"WinNT://localhost/$local_group,group").psbase.Invoke("Add",([ADSI]"WinNT://$ad_domain/$user").path)
        
        # Validating the user is now in the group.
        $local_members = @(([ADSI]"WinNT://localhost/$local_group,group").psbase.Invoke("Members") | % { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) } )
        if ($local_members -notcontains $user) {
            Throw "Unable to add $user `($user_email`) to the local $local_group group."
        } else {
            Write-Host "Added $user `($user_email`) to the local $local_group group."
        }
    } else {
        Throw "A user with the email account $user_email was not found in $ad_domain.  Unable to add the user to $local_group."
    }
} else {
    Throw "No user launch information was found in the tag 'servicenow:launched_by='.  Unable to add a user to $local_group."
}