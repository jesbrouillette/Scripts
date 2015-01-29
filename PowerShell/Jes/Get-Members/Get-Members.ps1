function Set-ADSIRoot ($strDomainF) {# sets the correct ADSI container for each domain
	if ($strDomainF.ToLower() -eq "ap"){
		return "dc=ap,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "eu"){
		return "dc=eu,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "la"){
		return "dc=la,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "meat"){
		return "dc=meat,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "na"){
		return "dc=na,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "corp"){
		return "dc=corp,dc=cargill,dc=com"
	}
	else {
		return "no ADSI path found"
	}
} # end Set-ADSIRoot function

function Get-Domain ($strADSIPathF) { # sets the correct domain for the given adsi path
	if ($strADSIPathF -match "dc=ap") {
		return "ap"
	}
	elseif ($strADSIPathF -match "dc=eu") {
		return "eu"
	}
	elseif ($strADSIPathF -match "dc=la") {
		return "la"
	}
	elseif ($strADSIPathF -match "dc=na") {
		return "na"
	}
	elseif ($strADSIPathF -match "dc=meat") {
		return "meat"
	}
	else {
		return "corp"
	}
} # end Get-Domain function

function Get-GMemb ($strSAMNameF,$strClassTypeF,$strADSIF) { # function retuns the full CN of the user or group
	$objRootF = [ADSI]("LDAP://$strADSIF")
	$objSearcherF = new-object System.DirectoryServices.DirectorySearcher
	$objSearcherF.SearchRoot = $objRootF
	$objSearcherF.Filter = "(&(objectCategory=$strClassTypeF)(sAMAccountName=$strSAMNameF))"
	$objGNameF = $objSearcherF.findall()
	if ($objGNameF.length -gt 1) {
		$objGNameF[0]
	}
	else {
		$objGNameF
	}
} # end Get-DN function

function Output-Members ($objOutGroupF,$strGNameF,$strNestedF) { 
	if ($objOutGroupF.objectclass[1] -eq "group") {
		foreach ($strMemberF in $objOutGroupF.Member) {
			$objMemberF = [ADSI]("LDAP://$strMemberF")
			if ($objMemberF.objectclass[1] -eq "group") {
				$strNestedGroupF = [string]$objMemberF.Name
				$strNGDomainF = Get-Domain $objMemberF.distinguishedName
				$strNGNameF = $strNGDomainF.ToUpper() + "\" + $strNestedGroupF
				$strGNestNameF = $strGNameF + " < " + $strNGNameF
				Output-Members $objMemberF $strGNestNameF $strNGNameF
			}
			else {
				$strNameF = [string]$objMemberF.Name
				$strDomainF = Get-Domain $objMemberF.distinguishedName
				$strsAMF = [string]$objMemberF.sAMAccountName
				$strEmailF = [string]$objMemberF.mail
				
				$objTableRowF = $objOutput.NewRow()
				$objTableRowF.Name = $strNameF
				$objTableRowF.Logon = $strsAMF
				$objTableRowF.Domain = $strDomainF.ToUpper()
				$objTableRowF.Email = $strEmailF
				$objTableRowF.Nested_Group = $strNestedF
				$objOutput.Rows.Add($objTableRowF)
				$objMemberF
			}
			$countF += 1
			if ($countF -eq 10) {
				$counthundF += 1
				$countOutF = $countF * $counthundF
				Write-Host "Found" $countOutF "users in" $strGNameF
				$countF = 0
			}
		}
	}
}

$objGroups = Import-Csv -Path groups.csv | Sort-Object Domain

foreach ($objGroup in $objGroups) {
	$objOutput = New-Object system.Data.DataTable "Full DataTable" # Setup the Datatable Structure
	$col1 = New-Object system.Data.DataColumn Name,([string])
	$col2 = New-Object system.Data.DataColumn Logon,([string])
	$col3 = New-Object system.Data.DataColumn Domain,([string])
	$col4 = New-Object system.Data.DataColumn Email,([string])
	$col5 = New-Object system.Data.DataColumn Nested_Group,([string])
	
	$objOutput.columns.add($col1)
	$objOutput.columns.add($col2)
	$objOutput.columns.add($col3)
	$objOutput.columns.add($col4)
	$objOutput.columns.add($col5)

	$strGroupDomain = [string]$objGroup.domain -replace "`t","" -replace " ",""
	$strOutFile = $strGroupDomain.ToUpper() + "." + [string]$objGroup.group + ".csv"

	$strADSI = Set-ADSIRoot $objGroup.Domain
	
	if ($strADSI -eq "no ADSI path found") {
		Write-Output "The domain was set incorreclty" | Out-File $strOutFile
	}
	else {
		$objGProp = Get-GMemb $objGroup.Group "group" $strADSI
		if ($objGProp.Path -eq $null) {
			$strMessage = "`"" + $objGroup.domain + "\" + $objGroup.group + "`" was not found"
			$strMessage | Out-File $strOutFile
		}
		else {
			$strGADSI = $objGProp.Path
			$objGADSI = [ADSI]("$strGADSI")
			$strGroupName = [string]$objGADSI.Name
			$strGroupName = $strGroupDomain.ToUpper() + "\" + $strGroupName
			$strMessage = "Getting members in " + $strGroupName
			$strMessage
			
			$objGroupMemb = Output-Members $objGADSI $strGroupName
			
			$objOutput | Select-Object Name,Logon,Domain,Email,Nested_Group |  Export-Csv -Path $strOutFile -noTypeInformation
		}
	}
	Remove-Variable objOutput
}