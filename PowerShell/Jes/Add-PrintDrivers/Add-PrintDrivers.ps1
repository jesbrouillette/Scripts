$objDriver = [WmiClass]'Win32_PrinterDriver'
$objNewDriver = $objDriver.CreateInstance()
$objNewDriver.Name = "HP LaserJet P3005 PCL 6"
$objNewDriver.SupportedPlatform = "Windows NT x86"
$objNewDriver.Version = "3"
$objNewDriver.FilePath = "C:\temp\HP LJP3005 PCL6 Driver"
$objNewDriver.InfName = "C:\temp\HP LJP3005 PCL6 Driver\hpc300xc.inf"
$objDriver.AddPrinterDriver($objNewDriver)
$objDriver.Put()


$objWMI = [wmiclass]"Win32_PrinterDriver"
$objDriver = $objWMI.CreateInstance()
$objDriver.ConfigFile = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpmdp5r1.dll"
$objDriver.DataFile = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpc30056.GPD"
$objDriver.DependentFiles = @("C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcp3005.CFG,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpc30x56.XML,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcsc5r1.DTD,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpc30xx6.GPD,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpc30xxc.INI,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcP6.hpx,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcui5r1.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcpe5r1.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpc6r5r1.DLL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcdmc32.DLL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpbcfgre.DLL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpzbdi.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\HPZBDI32.msi,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpc6m5r1.GPD,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcsm5r1.GPD,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcst5r1.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcur5r1.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcsat.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcev5r1.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\pclxl.DLL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\pjl.GPD,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\pclxl.GPD,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\HPCHL5r1.CAB,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIRES.DLL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIDRVUI.DLL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\STDNAMES.GPD,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\STDDTYPE.GDL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\STDSCHEM.GDL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\STDSCHMX.GDL,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcls5r1.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcss5r1.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcpn5r1.dll,C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\hpcc35r1.DLL")
$objDriver.DriverPath = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\unidrv.dll"
$objDriver.HelpFile = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\unidrv.hlp"
$objDriver.OEMUrl = "http://go.microsoft.com/fwlink/?LinkID=37&prd=10798&sbp=Printers"
$objDriver.Name = "HP LaserJet P3005 PCL 6"
$objDriver.SupportedPlatform = "Windows NT x86"
$objDriver.Version = 3
$objWMI.addPrinterDriver($objDriver)
#$rtnCode = $objwmi.addPrinterDriver($objDriver)
#$rtncode.returnValue

$objWMI = [wmiclass]"Win32_PrinterDriver"
$objDriver = $objWMI.CreateInstance()
$objDriver.name = "Generic / Text Only"
$objDriver.DriverPath = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIDRV.DLL"
$objDriver.ConfigFile = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIDRVUI.DLL"
$objDriver.DataFile = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTY.GPD"
$objDriver.DependentFiles = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTYRES.DLL","C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTY.INI","C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTY.DLL","C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTYUI.DLL","C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIRES.DLL","C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTYUI.HLP","C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\STDNAMES.GPD"
$objDriver.HelpFile = "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIDRV.HLP"
$rtnCode = $objwmi.addPrinterDriver($objDriver)
$rtncode.returnValue
