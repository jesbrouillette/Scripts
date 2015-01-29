@ECHO OFF
@ECHO ==========================================================================
@ECHO %computername%
if exist "c:\Program Files\Citrix\Independent Management Architecture\MF20.dsn" dsmaint config /dsn:"c:\Program Files\Citrix\Independent Management Architecture\MF20.dsn"
if exist "c:\Program Files (x86)\Citrix\Independent Management Architecture\MF20.dsn" dsmaint config /dsn:"c:\Program Files (x86)\Citrix\Independent Management Architecture\MF20.dsn"
if exist "D:\apps\util\citrix\Independent Management Architecture\MF20.dsn" dsmaint config /dsn:"D:\apps\util\citrix\Independent Management Architecture\MF20.dsn"
sc config "Citrix SMA Service" start=demand
sc config imaservice start=demand
net stop "Citrix SMA Service"
net stop imaservice
dsmaint recreatelhc
sc config imaservice start=auto
sc config "Citrix SMA Service" start=auto
net start imaservice
net start "Citrix SMA Service"
@ECHO ==========================================================================