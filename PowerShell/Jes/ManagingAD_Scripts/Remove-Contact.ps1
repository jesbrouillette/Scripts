#Remove-Contact.ps1

Function Remove-Contact {
    Param([string]$name=$(Throw "You must specify a contact name"))
    
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
            write $False
        }
    }

    $object=Get-Contact $name
    
    if ($object ) {    
        $parent=$object.psbase.parent.distinguishedname
        [ADSI]$OU="LDAP://$parent"
        $OU.Delete("contact","CN=$Name")
        
      } 
    else {
        write "$Name not found"
    }
}

#sample usage
# Remove-Contact "Ferdinand Rios"
