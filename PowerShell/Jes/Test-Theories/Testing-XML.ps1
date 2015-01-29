param (
	[string]$string1, # [DESCRIPTION]
	[switch]$switch1 # [DESCRIPTION]
)
################################################################################
#                                  ##########                                  #
#                                                                              #
# [Description]                                                                #
#                                                                              #
# Created By:  [CREATOR]                                                       #
# Creation Date:  [DATE]                                                       #
#                                                                              #
# Updated:  [DATE]                                                             #
#          [DESCRIPTION]                                                       #
#                                                                              #
# Usage:  .\GetNetInfo.ps1 [options]                                           #
#                                                                              #
# Switches:                                                                    #
#          -string1 [string]  - [DESCRIPTION]                                  #
#          -switch            - [DESCRIPTION]                                  #
#                                                                              #
# NOTE:    [NOTES]                                                             #
#                                                                              #
#                                  ##########                                  #
################################################################################

$erroractionpreference = "Continue"

$names = @()
$date = Get-Date
$array = "0n","worlds ended"
$int = 4
$string = "because of John"

$row = "" | Select First,Last
$row.First = "Edson"
$row.Last = "Greenston"
$names += $row

$row = "" | Select First,Last
$row.First = "Catalyn"
$row.Last = "Shay"
$names += $row

$data = @($names,$date,$array,$int,$string)
$data | Export-Clixml -Path .\Test.xml -Force
$data2 = Import-Clixml -Path .\Test.xml

Write-Host "Origional data:"
$data[0] | % { Write-Host $data[2][0] $data[1] $data[3] $data[2][1] $_.First $_.Last $data[4] }
Write-Host ""


Write-Host "Imported data:"
$data2[0] | % { Write-Host $data2[2][0] $data2[1] $data2[3] $data2[2][1] $_.First $_.Last $data2[4] }

Write-Host "--------------------------------------------------------------------------------"
@"
gc $data2
"@