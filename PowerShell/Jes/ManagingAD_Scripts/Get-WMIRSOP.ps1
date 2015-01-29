# Get-WMIRSOP.ps1

Function Get-GPOData {
    Param([string]$namespace="root\rsop\computer",
          [string]$computername=$env:computername)
          
    Function Get-GPOName {
        Param([string]$namespace="root\rsop\computer",
              [string]$GPOID=$(Throw "You must enter a GPOID"),
              [string]$computername=$env:computername)
        #a GPO id is something like:
        #RSOP_GPO.id="cn={8B273A4A-F50B-4306-B4E1-B148BCF084A6},
        #cn=policies,cn=system,DC=company,DC=local"
        
        $gporesult=Get-WmiObject -namespace $namespace -class RSOP_GPO `
        -computername $computername -filter "__RELPATH='$GPOID'" 
        
        write $gporesult  
    }
    
    Function Get-WMIFilter {
        Param([string]$FilterID=$(Throw "You must pass a SOMFilter ID"),
              [string]$computername=$env:computername)
        
        #A SOMFilter ID looks like this
        #MSFT_SomFilter.ID="{4BEE37FA-A82F-4497-84EC-E3B4CC9B5840}",Domain="mycompany.local"
        #It is part of a RSOP_GPO object
        
        #regex patter to get GUID
        [regex]$regex="{[\w-]*}"
        $FilterID -match $regex | Out-Null  #I don't want $True written 
                                            #to the pipeline or made part
                                            #of the functions return value
        $ID=$matches[0]
        
        #split out the domain
        $domain=$FilterID.Split("=")[2]
        
        $query="Select * from MSFT_SOMFilter where ID='$ID' AND domain=$domain"
        Get-WmiObject -Namespace root\policy -query $query -ComputerName $computername
            
    }

#main function body
    $data=Get-WmiObject -namespace $namespace -class RSOP_gplink `
    -ComputerName $computername    
  
    #strip out system classes
    $props=$data | Get-Member -membertype "Property" | where {
     $_.name -notlike "__*"}
     
    for ($j=0;$j -lt $data.count;$j++) {
      $obj=New-Object PSObject
      
      #add GPO specific properties
      $gpo=Get-GPOName -namespace $namespace -computername $computername `
      -gpoid $data[$j].GPO

      $obj | Add-Member -MemberType "NoteProperty" -Name "GPOName" -Value $gpo.name
      $obj | Add-Member -MemberType "NoteProperty" -Name "accessDenied" -value $gpo.AccessDenied
      $obj | Add-Member -MemberType "NoteProperty" -Name "GPOEnabled" -Value $gpo.enabled
      $obj | Add-Member -MemberType "NoteProperty" -Name "fileSystemPath" -Value $gpo.fileSystemPath
      $obj | Add-Member -MemberType "NoteProperty" -Name "filterAllowed" -Value $gpo.filterAllowed
      $obj | Add-Member -MemberType "NoteProperty" -Name "filterId" -Value $gpo.filterId
      
      #if FilterID has a value, get the name of the WMI filter
      if ($gpo.FilterID) {
        $gpofilter = Get-WMIFilter -filterID $gpo.filterID -computername $computername
        $obj | Add-Member -MemberType "NoteProperty" -Name "filterName" -Value $gpofilter.name
      }
      else {
        $obj | Add-Member -MemberType "NoteProperty" -Name "filterName" -Value $Null
      }
     
      for ($i=0;$i -lt $props.count;$i++) {
       $property=$props[$i].name
       $value= $data[$j].($property)
       $obj | Add-Member -MemberType "NoteProperty" -Name $property -Value $value 

      }
       write $obj
    }   
}

#sample usage    
# $computer=$env:computername
# $namespace="root\rsop\computer"
# 
# Get-GPOData -namespace $namespace -computername $computer `
#  | sort AppliedOrder | Select GPOName,SOM,GPOEnabled,*Order,Filter*




