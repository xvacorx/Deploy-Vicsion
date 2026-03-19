@echo off
set "PS1=%TEMP%\NukeDetached.ps1"
echo Start-Sleep -Seconds 15 > "%PS1%"
echo $app = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -ErrorAction SilentlyContinue ^| Get-ItemProperty ^| Where-Object { $_.DisplayName -match 'GLPI Agent' } >> "%PS1%"
echo if ($app) { >> "%PS1%"
echo $guid = $app.PSChildName >> "%PS1%"
echo Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $guid /quiet /norestart" -Wait -NoNewWindow >> "%PS1%"
echo } >> "%PS1%"
echo Stop-Service -Name 'GLPI-Agent' -Force -ErrorAction SilentlyContinue >> "%PS1%"
echo Stop-Process -Name 'glpi-agent*' -Force -ErrorAction SilentlyContinue >> "%PS1%"
echo sc.exe delete GLPI-Agent >> "%PS1%"
echo Remove-Item -Path 'C:\Program Files\GLPI-Agent' -Recurse -Force -ErrorAction SilentlyContinue >> "%PS1%"
echo Remove-Item -Path 'C:\ProgramData\GLPI-Agent' -Recurse -Force -ErrorAction SilentlyContinue >> "%PS1%"
echo reg delete HKLM\SOFTWARE\GLPI-Agent /f >> "%PS1%"
echo reg delete HKLM\SOFTWARE\WOW6432Node\GLPI-Agent /f >> "%PS1%"

powershell -WindowStyle Hidden -Command "Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList 'powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%TEMP%\NukeDetached.ps1\"'"
exit