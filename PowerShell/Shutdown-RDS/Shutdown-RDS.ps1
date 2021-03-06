#$serverArray = "244161004"
#$refreshToken = "d615fba99d86f4fcc18040ec3fa2270de6f56335"
$serverArray  = $ENV:SERVER_ARRAY
$refreshToken = $ENV:REFRESHTOKEN

# ==--== OAuth2 Begin ==--==
$oauthURL   = "https://us-4.rightscale.com/api/oauth2"
$postString = "grant_type=refresh_token;refresh_token=$refreshToken;"

$postBytes  = [System.Text.Encoding]::UTF8.GetBytes($postString)

$httpRequest               = [System.Net.WebRequest]::Create($oauthUrl)
$httpRequest.Method        = "POST"
$httpRequest.ContentLength = $postbytes.Length
$httpRequest.headers.Add("X_API_VERSION","1.5")

$requestStream = $httpRequest.GetRequestStream()
$requestStream.Write($postBytes,0,$postBytes.length)

[System.Net.WebResponse]$httpResponse = $httpRequest.GetResponse()

$responseStream = $httpResponse.GetResponseStream()

[System.IO.StreamReader]$streamReader = New-Object System.IO.Streamreader -ArgumentList $responseStream

$httpResult  = ConvertFrom-Json ($streamReader.ReadToEnd())
$accessToken = $httpResult.access_token
# ==--== OAuth2 End ==--==

$serverArrayUrl    = "https://us-4.rightscale.com/api/server_arrays/$($serverArray).xml"
$arrayInstancesURL = "https://us-4.rightscale.com/api/server_arrays/$($serverArray)/current_instances"

#Array Info
$listArrayRequest        = [System.Net.WebRequest]::Create($serverArrayUrl)
$listArrayRequest.Method = "GET"
$listArrayRequest.Headers.Add("X_API_VERSION","1.5");
$listArrayRequest.Headers.Add("Authorization","Bearer $accessToken")

[System.Net.WebResponse]$listArrayResponse = $listArrayRequest.GetResponse()

$listArrayResponseStream       = $listArrayResponse.GetResponseStream()
$listArrayResponseStreamReader = New-Object System.IO.StreamReader -argumentList $listArrayResponseStream
[xml]$listArrayResponseXML     = $listArrayResponseStreamReader.ReadToEnd().toString()

#Instance Info
$listInstanceRequest        = [System.Net.WebRequest]::Create($arrayInstancesURL)
$listInstanceRequest.Method = "GET"
$listInstanceRequest.Headers.Add("X_API_VERSION","1.5");
$listInstanceRequest.Headers.Add("Authorization","Bearer $accessToken")

[System.Net.WebResponse]$listInstanceResponse = $listInstanceRequest.GetResponse()

$listInstanceResponseStream       = $listInstanceResponse.GetResponseStream()
$listInstanceResponseStreamReader = New-Object System.IO.StreamReader -argumentList $listInstanceResponseStream
$listInstanceResponseJSON         = ConvertFrom-Json $listInstanceResponseStreamReader.ReadToEnd().toString()

$date    = Get-Date
$dateUTC = $date.ToUniversalTime()
$day     = $dateUTC.DayOfWeek
$hour    = $dateUTC.Hour
$minute  = $dateUTC.Minute

$schedules = $listArrayResponseXML.server_array.elasticity_params.schedule_entries.schedule_entry

[int]$instances = $listArrayResponseXML.server_array.instances_count
[int]$minimum   = $schedules | ? { $_.Day -eq $day -and $_.Time -le "$($hour):$($minute)" } | Sort -Descending time | Select -First 1 -ExpandProperty min_count

$killCount = $instances - $minimum
$rsName    = (ConvertFrom-Json ((rs_tag -l) -join "")) | ? { $_ -match "ec2:name" }
$found     = $listInstanceResponseJSON | sort created_at | select -First $killCount | % { $_ -match $rsName }

if ($found) {
    rs_tag -a rs_rds_shutdown:rds_state=terminate
    rs_run_rightscript -i 528610004
    do {
        $sessions = gwmi -Query "SELECT ActiveSessions FROM Win32_PerfFormattedData_LocalSessionManager_TerminalServices"
        Start-Sleep -Seconds 120
        $count += 1
    } until (($sessions -le 2) -or ($count -eq 10))
    rs_shutdown -t
}