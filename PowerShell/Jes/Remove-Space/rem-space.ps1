﻿Get-ChildItem * -Include *.csv -Exclude users.csv,out.csv | foreach {(Get-Content $_.name) -replace " ","" | Set-Content $_.name }