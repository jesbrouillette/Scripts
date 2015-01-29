$ErrorActionPreference = "silentlycontinue"
$starttime = get-date
$HKLM = 2147483650
$servers = Read-Host "Please input the list of machines to check"
get-content $servers
$auth = get-credential
# display the header info
write-host $servers
write-host $('{0,-17}{1}' -f "ServerName","Registry Key")
write-host "---------------  -----------"
$count = 0
# sort the computer names and get various wmi info for that server
$servers.keys | sort | foreach `
  {  $ping = get-wmiobject win32_pingstatus -filter "address='$_'"
  if ($ping.statuscode -eq 0)
    {
    if ($servers.$_ -eq "ad" )
      {
      $reg = get-wmiobject -list -namespace root\default -computer $_ | where-object {$_.name -eq "StdRegProv" }
      if ($? -eq $false)
        {
        write-host $_.tolower() "...wmi query failed." -foregroundcolor Red
        }
      else
        {
        $o2kInstPath = $reg.getstringvalue($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{00010409-78E1-11D2-B60F-006097C998E7}","InstallSource")
        write-host $('{0,-17}{1}' -f $_.tolower(),$o2kInstPath.svalue)
        }
      }
    else
      {
      $reg = get-wmiobject -list -namespace root\default -computer $_ -credential $auth
      if ($? -eq $false)
        {
        write-host $_.tolower() "...wmi query failed." -foregroundcolor Red
        }
      else
        {
        $o2kInstPath = $reg.getstringvalue($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{00010409-78E1-11D2-B60F-006097C998E7}","InstallSource")
        write-host $('{0,-17}{1}' -f $_.tolower(),$o2kInstPath.svalue)
        }
      }
    }
  else
    {
    write-host $_.tolower() "...ping failed." -foregroundcolor Red
    }
  $count += 1
  }
write-host
write-host "Total servers: $count"
$endtime = (get-date).subtract($starttime)
write-host "Elapsed time:" $('{0:D2}:{1:D2}:{2:D2}' -f $endtime.hours,$endtime.minutes,$endtime.seconds)
write-host