#Watch-ADEvent.ps1

Function Get-WmiEvent {
  Param([string]$query)
  
  $path="root\directory\ldap"
  $EventQuery  = New-Object System.Management.WQLEventQuery $query
  $scope       = New-Object System.Management.ManagementScope $path
  $watcher     = New-Object System.Management.ManagementEventWatcher $scope,$EventQuery
  $options     = New-Object System.Management.EventWatcherOptions 
  $options.TimeOut = [timespan]"0.0:0:1"
  $watcher.Options = $options
  cls
  Write-Host ("Waiting for events in response to: {0}" -F $EventQuery.querystring)  -backgroundcolor cyan -foregroundcolor black
  $watcher.Start()
  while ($true) {
     trap [System.Management.ManagementException] {continue}
     
     $evt=$watcher.WaitForNextEvent() 
      if ($evt) {
         $evt.TargetInstance | select *
      Clear-Variable evt  
      }
  }
}

#Sample usage

# $query="Select * from __InstanceCreationEvent Within 10 where TargetInstance ISA 'DS_USER'"
# $query="Select * from __InstanceCreationEvent Within 10 where TargetInstance ISA 'DS_GROUP'"
# $query="Select * from __InstanceModificationEvent Within 10 where TargetInstance ISA 'DS_USER'"
# $query="Select * from __InstanceModificationEvent Within 10 where TargetInstance ISA 'DS_COMPUTER'"
# 
# Get-WmiEvent $query
