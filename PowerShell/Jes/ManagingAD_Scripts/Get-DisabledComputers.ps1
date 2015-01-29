#Get-DisabledComputers.ps1

$searcher=New-Object DirectoryServices.DirectorySearcher
$searcher.Filter="(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=2))"

$results=$searcher.FindAll()

$results | select Path
