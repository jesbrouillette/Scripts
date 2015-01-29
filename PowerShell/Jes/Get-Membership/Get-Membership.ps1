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

function Get-Memb ($strSAMNameF,$strClassTypeF,$strADSIF) { # function retuns the full CN of the user or group
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

function Output-Membership ($objOutUserF,$strUNameF) { 
	if ($objOutUserF.objectclass[3] -eq "user") {
		foreach ($Groups in $objOutUserF.memberOf) {
			$GroupCount += 1
		}
		foreach ($strGroupF in $objOutUserF.memberOf) {
			$objGroupF = [ADSI]("LDAP://$strGroupF")
			$strNameF = [string]$objGroupF.Name
			$strGroupDomainF = [string]$objGroupF.distinguishedName
			$strGroupDomainF = Get-Domain $strGroupDomainF
			
			$objTableRowF = $objOutput.NewRow()
			$objTableRowF.Group = $strNameF
			$objTableRowF.Domain = $strGroupDomainF.ToUpper()
			$objOutput.Rows.Add($objTableRowF)
			$objMemberF

			$countF += 1
			if (($countF % 10) -eq 0 -or $countF -eq $GroupCount) {
				Write-Host "Found" $countF "of" $GroupCount "group memberships for" $strUNameF
			}
		}
	}
}

$objUsers = Import-Csv -Path users.csv

foreach ($objUser in $objUsers) {
	$objOutput = New-Object system.Data.DataTable "Full DataTable" # Setup the Datatable Structure
	$col1 = New-Object system.Data.DataColumn Group,([string])
	$col2 = New-Object system.Data.DataColumn Domain,([string])
	
	$objOutput.columns.add($col1)
	$objOutput.columns.add($col2)

	$strUserDomain = [string]$objUser.domain -replace "`t","" -replace " ",""
	$strOutFile = $strUserDomain.ToUpper() + "." + ([string]$objUser.user).ToLower() + ".csv"

	$strADSI = Set-ADSIRoot $objUser.Domain
	
	if ($strADSI -eq "no ADSI path found") {
		$strMessage = "The domain is incorrect for " + $objUser.user
		$strMessage | Out-File $strOutFile
	}
	else {
		$objUProp = Get-Memb $objUser.User "user" $strADSI
		if ($objUProp.Path -eq $null) {
			$strMessage = "`"" + $objUser.domain + "\" + $objUser.User + "`" was not found"
			$strMessage | Out-File $strOutFile
		}
		else {
			$strUADSI = $objUProp.Path
			$objUADSI = [ADSI]("$strUADSI")
			$strUserName  = (([string]$objUADSI.userPrincipalName).split("@"))[0]
			$strUserDomain = $objUser.Domain
			$strMessage = "Getting membership for " + ($objUser.Domain).ToUpper() + "\" + $strUserName.ToLower()
			$strMessage
			
			$objUserMemb = Output-Membership $objUADSI $strUserName
			
			$objOutput | Export-Csv -Path $strOutFile -noTypeInformation
		}
	}
	Clear-Variable objUserMemb
}