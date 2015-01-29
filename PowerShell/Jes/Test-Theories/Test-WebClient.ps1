$user = $env:USERNAME
$domain = $env:USERDNSDOMAIN
$webproxy = "http://web.us.proxy.cargill.com:4200"
$pwd = Read-Host "Password?" -assecurestring

$proxy = new-object System.Net.WebProxy
$proxy.Address = $webproxy
$account = new-object System.Net.NetworkCredential($user,[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd)),$domain)
$proxy.credentials = $account

$wc = new-object System.Net.WebClient
$wc.proxy = $proxy
$webpage = ($wc.DownloadString("http://samueltoth.com/show/wn2.txt")).Split("`n")

do { $word1 = Get-Random $webpage }
until ($word1.Length -ge 4 -and $word1.Length -le 8)
do { $word2 = Get-Random $webpage }
until ($word2.Length -ge 4 -and $word2.Length -le 8)

[string]::Join(" ",($word1,$word2))