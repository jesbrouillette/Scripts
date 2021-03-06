Param (
	$CSV	= "C:\Temp\Permissions.csv",
	$Path	= "C:\Temp",
	$Ident	= "Administrator"
)

GCI $Path -recurse | ? {$_.PSIsContainer -eq $True} | % {
	$Folder = $_
	Get-ACL $_.fullname | % {
		$_.Access | ? { $_.IdentityReference.Value -match $Ident } | Select `
				@{Name="Fullname";			Expression={$Folder.Fullname}},`
				@{Name="IdentityReference";	Expression={$_.IdentityReference}},`
				@{Name="AccessControlType";	Expression={$_.AccessControlType}},`
				@{Name="IsInherited";		Expression={$_.IsInherited}},`
				@{Name="InheritanceFlags";	Expression={$_.InheritanceFlags}},`
				@{Name="PropagationFlags";	Expression={$_.PropagationFlags}}
	}
} | Export-Csv $CSV -Force -NoTypeInformation