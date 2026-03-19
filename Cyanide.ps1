$ActionScript = {
    $LogFile = "C:\Windows\Temp\CyanideLog.txt"
    Add-Content -Path $LogFile -Value "[$(Get-Date)] Inicia proceso de auto-destruccion (Orden 66)"

    # Esperar a que GLPI cierre la conexion de la tarea actual
    Add-Content -Path $LogFile -Value "[$(Get-Date)] Esperando 20 segundos..."
    Start-Sleep -Seconds 20

    # Forzar detencion del servicio
    Add-Content -Path $LogFile -Value "[$(Get-Date)] Deteniendo servicio GLPI-Agent..."
    Stop-Service -Name "GLPI-Agent" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "glpi-agent" -Force -ErrorAction SilentlyContinue

    # Buscar GUID de desinstalacion MSI
    Add-Content -Path $LogFile -Value "[$(Get-Date)] Buscando GLPI Agent en registro..."
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    $app = Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "GLPI Agent" } | Select-Object -First 1
    
    if ($app) {
        $guid = $app.PSChildName
        Add-Content -Path $LogFile -Value "[$(Get-Date)] Encontrado: $($app.DisplayName) con GUID $guid. Ejecutando msiexec..."
        $msiArgs = "/x `"$guid`" /quiet /norestart"
        $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -NoNewWindow -PassThru
        Add-Content -Path $LogFile -Value "[$(Get-Date)] msiexec finalizo con codigo: $($proc.ExitCode)"
    } else {
        Add-Content -Path $LogFile -Value "[$(Get-Date)] No se encontro el agente en el registro, procediendo a purga manual."
    }

    # Limpieza de rastros
    Add-Content -Path $LogFile -Value "[$(Get-Date)] Purgando archivos y registros remanentes..."
    cmd.exe /c "sc delete GLPI-Agent"
    Remove-Item -Path "C:\Program Files\GLPI-Agent" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\ProgramData\GLPI-Agent" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\GLPI-Agent" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\GLPI-Agent" -Recurse -Force -ErrorAction SilentlyContinue

    Add-Content -Path $LogFile -Value "[$(Get-Date)] Purga completada."
}

# Codificar el script en Base64 para pasarlo a WMI de forma segura sin problemas de comillas
$encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ActionScript.ToString()))

# Desplegar el payload desconectado usando WMI
$WmiArgs = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encodedCommand"
Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $WmiArgs
