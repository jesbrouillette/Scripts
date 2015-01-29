#New-GPOReport.ps1

Function New-GPOReport {
# this will create a GPO report to the specified location.
# the default type is HTML unless you specify -XML
# this function accepts pipelined input
    Param([string]$dir="\\file01\files\gporeports",
          [switch]$xml
          )
          
    BEGIN {          
        $errorActionpreference="SilentlyContinue"
        if ($xml) {
          $flag=0
         }
        else {
          $flag=1
        }
    }
    
    PROCESS {
        $gpo=$_.DisplayName

        if ($flag -eq 0) {
            $gpo=$gpo+".xml"
        }
        else {
            $gpo=$gpo+".html"
        }
 
        # replace any spaces with _
        $file=Join-Path $dir $gpo.Replace(" ","_")
        $report=$_.GenerateReportToFile($flag,$file) 
        
        if ($report.result) {
            write $report.result
        }
        else {
            Write-Warning "Failed to create $file"
        }
    } #end Process scriptblock
    
    END {
    }
}

# sample usage
# Get-SDMgpo * | New-GPOReport 
# Get-SDMgpo * | New-GPOReport -xml
# Get-SDMgpo "Default Domain Policy" | New-GPOReport -dir "n:\" -xml
