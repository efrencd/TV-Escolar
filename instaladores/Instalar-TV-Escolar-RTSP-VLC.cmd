@echo off
setlocal EnableExtensions
title TV Escolar - Instalador RTSP VLC
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$t=Get-Content -Raw -LiteralPath '%~f0'; $mark='###PS_START###'; $i=$t.LastIndexOf($mark); if($i -lt 0){throw 'No se encuentra el instalador PowerShell'}; & ([scriptblock]::Create($t.Substring($i+$mark.Length)))"
set "RESULT=%errorlevel%"
echo.
if not "%RESULT%"=="0" echo La instalacion no se ha completado. Revisa el error.
pause
exit /b %RESULT%
###PS_START###

$ErrorActionPreference = 'Stop'
try {
    Write-Host 'TV ESCOLAR - VLC (RTSP unicast/TCP)'
    $paths = @(
        (Join-Path $env:ProgramFiles 'VideoLAN\VLC\vlc.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\VideoLAN\VLC\vlc.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\vlc.exe')
    )
    $pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($pf86) { $paths += (Join-Path $pf86 'VideoLAN\VLC\vlc.exe') }

    function Find-Vlc {
        foreach ($p in $paths) {
            if (Test-Path -LiteralPath $p -PathType Leaf) { return $p }
        }
        $command = Get-Command 'vlc.exe' -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
        return $null
    }

    $vlc = Find-Vlc
    if (-not $vlc) {
        if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
            throw 'No se encuentra WinGet. Instala App Installer desde Microsoft Store.'
        }
        Write-Host 'Instalando VLC mediante WinGet...'
        & winget.exe install --id VideoLAN.VLC --exact --source winget --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw ('WinGet devolvio el codigo ' + $LASTEXITCODE) }
        $vlc = Find-Vlc
        if (-not $vlc) { throw 'VLC se instalo pero no se encontro vlc.exe. Comprueba la ruta de instalacion.' }
    }

    $desktop = [Environment]::GetFolderPath('Desktop')
    $linkPath = Join-Path $desktop 'TV Escolar (VLC).lnk'
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut($linkPath)
    $link.TargetPath = $vlc
    # VLC ya ha demostrado resolver PCTV en esta LAN.
    $link.Arguments = '--fullscreen --rtsp-tcp "rtsp://PCTV:80/live"'
    $link.WorkingDirectory = Split-Path -Parent $vlc
    $link.IconLocation = $vlc + ',0'
    $link.Description = 'TV Escolar RTSP - VLC - PCTV (TCP)'
    $link.Save()

    Write-Host ('VLC: ' + $vlc)
    Write-Host ('Acceso directo creado: ' + $linkPath)
    Write-Host 'Direccion RTSP: rtsp://PCTV:80/live (TCP)'
    Write-Host 'Instalacion terminada.'
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
