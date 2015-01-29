Run Order:

Convert-Share.ps1
will ask for the .txt file with folders

Create-ADGroup.ps1 [file.csv] [ou path]
Where [file.csv] is the output from Convert-Share.ps1
And[out path] is the full out path where the groups are to be created
Like: ou=x,ou=y,ou=z,dc=a,dc=y,dc=cargill,dc=com

Set-Permissions.ps1 [file.csv] [domain]
Where [file.csv] is the output from Convert-Share.ps1
And [domain] is the domain where the groups are

Add-Users.ps1 "[groupname]" [domain] [file.csv]
Where [groupname] is the name of the group to add users to
AND [domain] is the domain where the group is
AND [file.csv] contains the users to add in the following format:
  UserName,Domain
  user1,na
  user2,eu