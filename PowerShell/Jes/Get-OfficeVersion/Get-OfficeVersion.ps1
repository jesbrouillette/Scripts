$outfile = "Office-Version.csv"

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$form = New-Object System.Windows.Forms.Form 
$form.Text = "Get Office Version"
$form.Size = New-Object System.Drawing.Size(300,128) 
$form.StartPosition = "CenterScreen"

$form.KeyPreview = $True
$form.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$file = $textbox.Text;$form.Close()}})
$form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$form.Close()}})

$textbox = New-Object System.Windows.Forms.TextBox 
$textbox.Location = New-Object System.Drawing.Size(10,40) 
$textbox.Size = New-Object System.Drawing.Size(260,20) 
$form.Controls.Add($textbox) 

$okbutton = New-Object System.Windows.Forms.Button
$okbutton.Location = New-Object System.Drawing.Size(65,70)
$okbutton.Size = New-Object System.Drawing.Size(75,23)
$okbutton.Text = "OK"
$okbutton.Add_Click({$file=$textbox.Text;$form.Close()})
$form.Controls.Add($okbutton)

$cancelbutton = New-Object System.Windows.Forms.Button
$cancelbutton.Location = New-Object System.Drawing.Size(160,70)
$cancelbutton.Size = New-Object System.Drawing.Size(75,23)
$cancelbutton.Text = "Cancel"
$cancelbutton.Add_Click({$form.Close()})
$form.Controls.Add($cancelbutton)

$formlabel = New-Object System.Windows.Forms.Label
$formlabel.Location = New-Object System.Drawing.Size(10,20) 
$formlabel.Size = New-Object System.Drawing.Size(280,20) 
$formlabel.Text = "Please enter the file with the computer(s) to queery"
$form.Controls.Add($formlabel) 

$form.Topmost = $True

$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()

$table = New-Object system.Data.DataTable "Full DataTable" # Setup the Datatable Structure
$col1 = New-Object system.Data.DataColumn Server,([string])
$col2 = New-Object system.Data.DataColumn Application,([string])
$col3 = New-Object system.Data.DataColumn Version,([string])
$col4 = New-Object system.Data.DataColumn Install_Date, ([string])

$table.columns.add($col1)
$table.columns.add($col2)
$table.columns.add($col3)
$table.columns.add($col4)

if ($file -eq $null)
{
	"Cancel"
} else
{
	$list = Get-Content $file

	foreach ($line In $list)
	{
		$apps = gwmi -class Win32_Product -namespace "root\cimv2" -comp $line | Select Name, Version

		foreach ($app In $apps)
		{
			$row = $table.NewRow()
			$row.Server = $line
			$row.Application = $app.Name
			$row.Version = $app.Version
			$row.Install_Date = $app.InstallDate
			$table.Rows.Add($row)
		}
	}
}

$table | Export-Csv $outfile -Force -Encoding ASCII