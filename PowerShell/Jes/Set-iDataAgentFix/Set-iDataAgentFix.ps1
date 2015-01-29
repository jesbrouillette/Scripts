$type = "DWord"
$Value = 1
$Name = "nUseVSSSoftwareProvider"
$galaxy_path = "HKLM:\SOFTWARE\CommVault Systems\Galaxy"

gci $galaxy_path | select PSChildName | % {
	$path = "HKLM:\SOFTWARE\CommVault Systems\Galaxy\{0}\FileSystemAgent" -f $_.PSChildName
	New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force | Out-Null
}