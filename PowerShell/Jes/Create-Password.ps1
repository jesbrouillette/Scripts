function GenPwd ($CharLen) {
	
	$alphaLow = "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
	$alphaCap = "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
	$numb = "1","2","3","4","5","6","7","8","9"
	$special = "`~","`!","`@","`#","`$","`%","`^","`&","`*","`(","`)","`_","`+","`|","`{","`}","`:","`"","`<","`>","`?","``","`-","`=","`\","`[","`]","`;","`'","`,","`.","`/"
	
	$aLLen = $alphaLow.Length
	$aCLen = $alphaCap.Length
	$nLen = $numb.Length
	$sLen = $special.Length
	
	$rand = New-Object System.Random
	
	$generate = (0..($CharLen - 1)) | % {
		$rand.Next(0,4)
		Start-Sleep -m 1
	}
	
	$generated = [regex]::split($generate," ")
	
	foreach ($number in $generated) {
		if ($number -eq 0) { $charNumb = $rand.Next(0,([Int32]$aLLen - 1)) ; $char += $alphaLow[$charNumb] ; Start-Sleep -m 1 }
		elseif ($number -eq 1) { $charNumb = $rand.Next(0,([Int32]$aCLen - 1)) ; $char += $alphaCap[$charNumb] ; Start-Sleep -m 1 }
		elseif ($number -eq 2) { $charNumb = $rand.Next(0,([Int32]$nLen - 1)) ; $char += $numb[$charNumb] ; Start-Sleep -m 1 }
		elseif ($number -eq 3) { $charNumb = $rand.Next(0,([Int32]$sLen - 1)) ; $char += $special[$charNumb] ; Start-Sleep -m 1 }
	}
	return $char
}
$Password = GenPwd 8
$Password