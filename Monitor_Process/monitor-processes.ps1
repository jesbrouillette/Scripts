# Powershell 2.0
# Copyright (c) 2013 RightScale, Inc, All Rights Reserved Worldwide.

# Stop and fail script when a command fails.
$ErrorActionPreference = "Stop"

# unconditionally copy monitoring scripts to support upgrade case.
Write-Output "Configuring Process Monitoring"

# explode monitor scripts into temporary directory using "tar" from RightScale sandbox.
$monitorsRbPath = Join-Path "$env:RS_ATTACH_DIR" "monitor_processes.rb"

# input user script data into the Ruby file
(gc $monitorsRbPath) | % { $_ -replace "REPLACE_PROCESSES","$env:MONITOR_PROCESSES"} | Out-File $monitorsRbPath -Force

# copy monitor scripts, overwriting any duplicates.
Copy-Item $monitorsRbPath "$env:rs_monitors_dir" -Force