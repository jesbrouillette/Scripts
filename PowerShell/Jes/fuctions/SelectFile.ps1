Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;

public class Win32Window : IWin32Window
{
    private IntPtr _hWnd;
   
    public Win32Window(IntPtr handle)
    {
        _hWnd = handle;
    }

    public IntPtr Handle
    {
        get { return _hWnd; }
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms.dll"

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$owner = New-Object Win32Window -ArgumentList ([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle)

function Select-File
{
    param (
        [System.String]$Title = "Select File",
        [System.String]$InitialDirectory = "C:\",
        [System.String]$Filter = "All Files(*.*)|*.*"
    )
   
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = $filter
    $dialog.InitialDirectory = $initialDirectory
    $dialog.ShowHelp = $true
    $dialog.Title = $title
    $result = $dialog.ShowDialog($owner)

    if ($result -eq "OK")
    {
        return $dialog.FileName
    }
    else
    {
        Write-Error "Operation cancelled by user."
    }
}

Select-File