param (
	[string]$convert, #phrase to convert to passphrase
	[switch]$poss #ask for total phrases possible
)
################################################################################
#                                  ##########                                  #
#                                                                              #
# Generates a passphrase password from given input                             #
#                                                                              #
# Created By:  Jes Brouillette                                                 #
# Creation Date:  10/9/09                                                      #
#                                                                              #
# Usage:  .\Convert-PassPhrase.ps1 [string]                                    #
#                                                                              #
#                                  ##########                                  #
################################################################################

$ErrorActionPreference = "SilentlyContinue"

function GenRand ($char) { # returns a random number between 0 and the input string length
	$random = $rand.Next(0,($char.Count))
	Start-Sleep -m 1
	$char[$random]
}

function GenPoss ($text) { # generates the number of possible outputs for a specific character or phonetic string
	$possible = 1
	$chars = (0..($text.Length - 1)) | % { $text[$_] }
	foreach ($char in $chars) {
		foreach ($count in (0..($alpha.Count - 1))) {
			$alphaMatch = $alpha[$count][0]
			if ($char -match $alphaMatch) { $match = $true ; break }
		}
		if ($match) { $possible *= $alpha[$count].Count ; $match = $false }
		else {
			foreach ($spec in $special) {
				if ($char -match $spec) { $match = $true ; break }
			}
			if ($match) { $possible *= $special.Count ; $match = $false }
		}

	}
	return $possible
}

$rand = New-Object System.Random

$a = "a","A","4","`@"
$b = "b","B","8"
$c = "c","C","`("
$d = "d","D"
$e = "e","E","3"
$f = "f","F","ph"
$g = "g","G","6"
$h = "h","H"
$i = "i","I","`!","1"
$j = "j","J"
$k = "k","K"
$l = "l","L","`|"
$m = "m","M"
$n = "n","N"
$o = "o","O","0"
$p = "p","P","`?"
$q = "q","Q","9"
$r = "r","R"
$s = "s","S","`$","5"
$t = "t","T","7","`+"
$u = "u","U"
$v = "v","V"
$w = "w","W"
$x = "x","X","`*"
$y = "y","Y"
$z = "z","Z"
$space = " ","_","-"

$ate = "ate","8"
$eat = "eat","8"
$any = "any","ne"
$one = "one","1"
$won = "won","1"
$ph = "ph","f"
$oo = "oo","u"
$ck = "ck","k"
$ew = "ew","oo"
$two = "two","too","to"
$to = "to","two","too"
$too = "too","to","two"
$0 = "0","O","o"
$1 = "1","one","won"
$2 = "2","two","to","too"
$3 = "3","three"
$4 = "4","four","fore","for"
$5 = "5","five"
$6 = "6","six"
$7 = "7","seven"
$8 = "8","eight","ate"
$9 = "9","nine"

$special = "`~","`!","`@","`#","`$","`%","`^","`&","`*","`(","`)","`_","`+","`{","`}","`|","`:","`"","`<","`>","`?","``","`-","`=","`[","`]","`\","`;","`'","`,","`.","`/"

$alpha = @($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s,$t,$u,$v,$w,$x,$y,$z,$space)
$phone = @($ate,$eat,$any,$one,$won,$ph,$oo,$ck,$ew,$two,$to,$too,$0,$1,$2,$3,$4,$5,$6,$7,$8,$9)

$text = $convert

foreach ($count in (0..($phone.Count-1))) {
	$old = $phone[$count][0]
	$new = GenRand ($phone[$count])
	$text = $text.Replace($old,$new)
}

$chars = (0..($text.Length - 1)) | % { $text[$_] }
$newChars = ""

foreach ($char in $chars) {
	foreach ($count in (0..($alpha.Count - 1))) {
		$alphaMatch = $alpha[$count][0]
		if ($char -match $alphaMatch) { $match = $true ; break }
	}
	if ($match) { $newChars += GenRand $alpha[$count] ; $match = $false }
	else {
		foreach ($spec in $special) {
			if ($char -match $spec) { $match = $true ; break }
		}
		if ($match) { $newChars += GenRand $special ; $match = $false }
		else { $newChars += $char }
	}
}

if ($poss) {
	$possible = 1
	
	foreach ($count in (0..($phone.Count-1))) {
		if ($convert -match $phone[$count][0]) {
			$possible *= GenPoss ($phone[$count][0])
		}
	}
	$possible *= GenPoss $convert
}

if ($poss) { Write-Host "Password:" $newChars ; Write-Host "Possible:" $possible }
else { $newChars }