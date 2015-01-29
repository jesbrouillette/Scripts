$farm = new-Object -com "MetaframeCOM.MetaframeFarm"
$farm.Initialize(1)
$OutFile = "output.txt"

$Applications = $farm.Applications
Foreach($App in $Applications) {
	#$App
	$AppName = $App.DistinguishedName
	$tmp = $AppName.Split("/")
	$AppName = $tmp[-1]
	#"#######################################################"
	$AppName >> $OutFile
	#"#######################################################"
	"`tProperties:" >> $OutFile
	#"`t-----------"
	$AppProps = $App.WinAppObject
	"`t`t" + $AppProps.DefaultInitProg >> $OutFile
	"`t`t" + $AppProps.DefaultWorkDir >> $OutFile
	"`tUsers:" >> $OutFile
	#"`t------"
	 $Users = $App.Users
	 foreach($User in $Users) { # Get User's added directly to the applic
	 	"`t`t" + $User.AAName + "\" + $User.UserName >> $OutFile
	}
	"`tGroups:" >> $OutFile
	#"`t-------"
	$Groups = $App.Groups
	Foreach($Group in $Groups) {
		"`t`t" + $Group.AAName + "\" + $Group.GroupName >> $OutFile
	}
	
	"`tServers:" >> $OutFile
	#"`t--------"
	$Servers = $App.Servers
	Foreach($Server in $Servers) {
		"`t`t" + $Server.ServerName >> $OutFile
	}
}