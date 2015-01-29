#Get-Contact.ps1

Function Get-Contact {
    Param([string]$name=$(Throw "You must specify a contact name"))
    
    $searcher=New-Object DirectoryServices.DirectorySearcher
    $searcher.Filter="(&(objectcategory=person)(objectclass=contact)(name=$Name))"
    
    $result=$searcher.FindOne()
    
    if ($result.path) {
        [ADSI]$contact=$result.path
        write $contact
    }
    else {
        write "Not Found"
    }
}

