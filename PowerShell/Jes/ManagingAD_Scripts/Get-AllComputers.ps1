# Get-AllComputers.ps1

$searcher=New-Object System.DirectoryServices.DirectorySearcher
$searcher.filter="Objectcategory=computer"
$searcher.sort.propertyname="name"

$results=$searcher.findall()

Write-Host "Found" $results.count "computers"

$results | select @{name="Name";Expression={$_.properties.name}},`
@{name="DN";Expression={$_.properties.distinguishedname}}
