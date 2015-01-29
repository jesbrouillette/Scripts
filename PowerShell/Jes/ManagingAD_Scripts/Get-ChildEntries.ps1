#Get-ChildEntries.ps1

$DN="LDAP://dc=mycompany,dc=local"

$dsroot = New-Object DirectoryServices.DirectoryEntry $DN

$children=$dsroot.psbase.children | where {
$_.objectcategory -notmatch "Person" `
-AND $_.objectcategory -notmatch "Computer" `
-AND $_.objectcategory -notmatch "Group" `
-AND $_.objectcategory -notmatch "Contact"}

$children | sort Name | Format-List `
@{Label="DN";Expression={$_.DistinguishedName}},`
@{Label="Name";Expression={$_.Name}},`
@{Label="Description";Expression={$_.Description}},`
@{Label="Created";Expression={$_.WhenCreated}},`
ObjectClass,objectCategory

Write-Host "There are"($children | measure-object).count "child containers or OUs under " $dsroot.distinguishedname.value

