#Const
$RSDownloads = "C:\RSDownloads"
if (!(Test-Path $RSDownloads)) { New-Item $RSDownloads -ItemType Directory | Out-Null }

#Create Desired State Configuration Pull Server
Import-Module ServerManager

#Enable WINRM
Enable-PSRemoting -Force

#Check for .NET 4.5.2 (required for unzip processes)
$KB2934520 = Get-HotFix "KB2934520"

if (!$KB2934520) {
    #Download .NET 4.5
    $DotNet452  = "NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
    $Source     = "http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/{0}" -f $DotNet452
    $Folder     = "{0}\DotNET_4.5.2" -f $RSDownloads
    $Installer  = "{0}\{1}" -f $Folder,$DotNet452

    if (!(Test-Path $Folder)) { New-Item $Folder -ItemType Directory | Out-Null }

    Invoke-WebRequest -Uri $Source -OutFile $Installer

    #Install .NET 4.5.2
    Start-Process -FilePath $Installer -ArgumentList "/q /norestart" -Wait
    #rs_shutdown -r -i
}

#Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1

#Download additional module from MSDN
$xPSDSC       = "xPSDesiredStateConfiguration_3.0.3.4.zip"
$Source       = "https://gallery.technet.microsoft.com/xPSDesiredStateConfiguratio-417dc71d/file/131370/1/{0}" -f $xPSDSC
$xPSDSCFolder = "{0}\xPSDSC" -f $RSDownloads
$Zip          = "{0}\{1}" -f $xPSDSCFolder,$xPSDSC

if (!(Test-Path $xPSDSCFolder)) { New-Item $xPSDSCFolder -ItemType Directory | Out-Null }

Invoke-WebRequest -Uri $Source -OutFile $Zip | Out-Null

#Extract module
$Module = "{0}\WindowsPowerShell\modules\" -f $ENV:ProgramFiles

[Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

[IO.Compression.ZipFile]::OpenRead($Zip).Entries | % {
    $file   = Join-Path $Module $_.FullName
    $parent = Split-Path -Parent $file
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -Path $parent -Type Directory | Out-Null
    }
    if ($_.Length -ge 1) {
        if (!(Test-Path $file)) {
            [IO.Compression.ZipFileExtensions]::ExtractToFile($_, $file, $true)
        } elseif (!(Get-Item $file).PSIsContainer) {
            [IO.Compression.ZipFileExtensions]::ExtractToFile($_, $file, $true)
        }
    }
}

#Install DSC Service
if (Get-WindowsFeature "DSC-Service" | Select -Expand Installed) { Write-Host "DSC-Service is already installed" }
else { Write-Host "Installing DSC-Service" ; Install-WindowsFeature "DSC-Service" -IncludeAllSubFeatures -IncludeManagementTools }

#Create NewPullServer MOF
$CommandFile = "{0}\xPSDSCFolder.ps1" -f $xPSDSCFolder

$hereCommand = @"
configuration NewPullServer
{
    param ( [string[]]`$ComputerName = "localhost" )

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    Node `$ComputerName
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = "Present"
            Name   = "DSC-Service"
        }

        xDscWebService PSDSCPullServer
        {
            Ensure                  = "Present"
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            PhysicalPath            = "`$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint   = "AllowUnencryptedTraffic"
            ModulePath              = "`$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "`$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                   = "Started"
            DependsOn               = "[WindowsFeature]DSCServiceFeature"
        }

        xDscWebService PSDSCComplianceServer
        {
            Ensure                  = "Present"
            EndpointName            = "PSDSCComplianceServer"
            Port                    = 9080
            PhysicalPath            = "`$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
            CertificateThumbPrint   = "AllowUnencryptedTraffic"
            State                   = "Started"
            IsComplianceServer      = `$true
            DependsOn               = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
        }
    }
}

#Call the above function to create the MOF file.
NewPullServer
"@

$hereCommand.Split("`n") -join "`r`n" | Out-File $CommandFile -Force

& $CommandFile

Start-DscConfiguration .\NewPullServer –Wait