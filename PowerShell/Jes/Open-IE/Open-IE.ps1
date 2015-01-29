$UrlTemplateMap = @{
	"bs" = "http://blogsearch.google.com/blogsearch?hl=en&q={0}&ie=UTF-8&scoring=d"
	"dr" = "http://drudgereport.com"
	"gtr" = "http://www.google.com/language_tools?hl=en"
	"verb" = "http://msdn2.microsoft.com/en-us/library/ms714428.aspx"
	"v" = "http://msdn2.microsoft.com/en-us/library/ms714428.aspx"
	"ps" = "http://blogs.msdn.com/powershell/default.aspx"
}
$Script:OutIE = $Null
function Out-IE ($url, [Switch]$Reuse) {
	if ($Script:OutIE -eq $null -OR $Script:OutIE.Application -eq $null -OR !($Reuse)) {
		$Script:OutIE = New-Object -Com InternetExplorer.Application
	}
	if ((!$url) -OR ($url -eq "?") -OR ($url -eq "-?")) {
		$urlTemplateMap.GetEnumerator() |Sort Name |Format-Table @{Expression={$_.Name};Label="Name";Width=10},Value
		return
	}
	$navOpenInBackGroundTab = 0
	foreach ($u in @($url)) {
		$templateUrl = $u
		$MappedUrl = $UrlTemplateMap.$u
		if ($MappedUrl) {
			$templateUrl = $MappedUrl
		}
	}
	
	# Use the Template and $args to generage the final URL
	$realUrl = $templateUrl -f $args
	$Script:OutIE.Navigate2($realUrl, $navOpenInBackGroundTab)
	$navOpenInBackGroundTab = 0x1000
}
$Script:OutIE.visible=1
Set-Alias oie Out-IE