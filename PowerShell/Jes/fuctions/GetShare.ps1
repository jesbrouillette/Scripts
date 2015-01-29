function getshare {
	param (
		[string]$name,  #Machine to gather shares from
		[string]$exclude, #Text to filter out (*$ to filter out admin shares)
		[string]$include, #Text to search for
		[string]$csv      #Output to csv
	)
	if ($exclude) { $list = GWMI win32_share -computer $name | ? {$_.name -notlike $exclude} }
	elseif ($include) { $list = GWMI win32_share -computer $name | ? {$_.name -like $include} }
	else { $list = GWMI win32_share -computer $name }
	if ($csv) { $list | Export-Csv $csv -NoTypeInformation ; Import-Csv $csv | fl}
	else { $list | fl }
}