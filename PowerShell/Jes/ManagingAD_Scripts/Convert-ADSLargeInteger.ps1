#Convert-ADSLargeInteger.ps1

Function Convert-ADSLargeInteger {
# Take a large value integer and return a 32 bit value
# Thanks to Brandon Shell (http://bsonposh.com/) for the function

    Param([object]$adsLargeInteger=$(Throw "You must specify an object."))

    $highPart = $adsLargeInteger.GetType().InvokeMember("HighPart",'GetProperty', `
    $null, $adsLargeInteger, $null)
    $lowPart  = $adsLargeInteger.GetType().InvokeMember("LowPart",'GetProperty', `
    $null, $adsLargeInteger, $null)
    $bytes = [System.BitConverter]::GetBytes($highPart)
    $tmp   = [System.Byte[]]@(0,0,0,0,0,0,0,0)
    [System.Array]::Copy($bytes, 0, $tmp, 4, 4)
    $highPart = [System.BitConverter]::ToInt64($tmp, 0)
    $bytes = [System.BitConverter]::GetBytes($lowPart)
    $lowPart = [System.BitConverter]::ToUInt32($bytes, 0)

    write ($lowPart + $highPart)
}
 
