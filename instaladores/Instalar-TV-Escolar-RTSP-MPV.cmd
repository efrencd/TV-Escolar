@echo off
setlocal EnableExtensions
title TV Escolar - Instalador RTSP MPV
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$t=Get-Content -Raw -LiteralPath '%~f0'; $mark='###PS_START###'; $i=$t.LastIndexOf($mark); if($i -lt 0){throw 'No se encuentra el instalador PowerShell'}; & ([scriptblock]::Create($t.Substring($i+$mark.Length)))"
set "RESULT=%errorlevel%"
echo.
if not "%RESULT%"=="0" echo La instalacion no se ha completado. Revisa el error.
pause
exit /b %RESULT%
###PS_START###

$ErrorActionPreference = 'Stop'
$server = 'PCTV'
$port = 80
$streamPath = 'live'
$appDir = Join-Path $env:LOCALAPPDATA 'TVEscolar'

function Find-Mpv {
    $paths = @(
        (Join-Path $env:ProgramFiles 'MPV Player\mpv.exe'),
        (Join-Path $env:ProgramFiles 'mpv\mpv.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\MPV Player\mpv.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\mpv\mpv.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\mpv.exe')
    )
    $pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($pf86) { $paths += (Join-Path $pf86 'MPV Player\mpv.exe') }
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p -PathType Leaf) { return $p }
    }
    $command = Get-Command 'mpv.exe' -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    return $null
}

try {
    Write-Host 'TV ESCOLAR - MPV (RTSP unicast/TCP)'
    $mpv = Find-Mpv
    if (-not $mpv) {
        if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
            throw 'No se encuentra WinGet. Instala App Installer desde Microsoft Store.'
        }
        Write-Host 'Instalando MPV mediante WinGet...'
        & winget.exe install --id shinchiro.mpv --exact --source winget --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw ('WinGet devolvio el codigo ' + $LASTEXITCODE) }
        $mpv = Find-Mpv
        if (-not $mpv) { throw 'MPV se instalo pero no se encontro mpv.exe. Comprueba la ruta de instalacion.' }
    }
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    $launcherPath = Join-Path $appDir 'Abrir-TV-Escolar-MPV.ps1'

    $launcher = @'
$ErrorActionPreference = 'Stop'
$mpvExe = '__MPV_EXE__'
$server = 'PCTV'
$port = 80
$streamPath = 'live'
$appDir = Join-Path $env:LOCALAPPDATA 'TVEscolar'
$logFile = Join-Path $appDir 'mpv-rtsp.log'

function Resolve-TvServerIPv4 {
    # Esta combinacion devolvio la IP de PCTV en la LAN del colegio.
    foreach ($name in @("$server.local", $server)) {
        foreach ($localOnly in @($true, $false)) {
            try {
                if ($localOnly) {
                    $answers = @(Resolve-DnsName -Name $name -Type A -LlmnrNetbiosOnly -ErrorAction Stop)
                } else {
                    $answers = @(Resolve-DnsName -Name $name -Type A -ErrorAction Stop)
                }
                foreach ($a in $answers) {
                    if (-not $a.IPAddress) { continue }
                    $parsed = $null
                    if ([Net.IPAddress]::TryParse([string]$a.IPAddress, [ref]$parsed) -and
                        $parsed.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
                        return $parsed.ToString()
                    }
                }
            } catch { }
        }
    }
    return $null
}

function Show-Error($message) {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show(
        $message, 'TV Escolar - MPV',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}

try {
    $ip = Resolve-TvServerIPv4
    if (-not $ip) {
        throw 'No se pudo localizar el equipo PCTV en la red. Comprueba la conexion al Wi-Fi o LAN escolar.'
    }
    if (-not (Test-Path -LiteralPath $mpvExe -PathType Leaf)) {
        throw ('No se encuentra MPV: ' + $mpvExe + '. Ejecuta otra vez el instalador.')
    }
    $url = 'rtsp://' + $ip + ':' + $port + '/' + $streamPath
    & $mpvExe '--fs' '--rtsp-transport=tcp' '--profile=low-latency' ('--log-file=' + $logFile) $url
} catch {
    Show-Error ([string]$_)
    exit 1
}
'@
    $launcher = $launcher.Replace('__MPV_EXE__', $mpv.Replace("'", "''"))
    Set-Content -LiteralPath $launcherPath -Value $launcher -Encoding UTF8

    $desktop = [Environment]::GetFolderPath('Desktop')
    $linkPath = Join-Path $desktop 'TV Escolar (MPV).lnk'
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut($linkPath)
    $link.TargetPath = Join-Path $PSHOME 'powershell.exe'
    $link.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $launcherPath + '"'
    $link.WorkingDirectory = $appDir
    $link.IconLocation = $mpv + ',0'
    $link.Description = 'TV Escolar RTSP - MPV - PCTV (TCP)'
    $link.Save()

    Write-Host ('MPV: ' + $mpv)
    Write-Host ('Acceso directo creado: ' + $linkPath)
    Write-Host ('En cada apertura se resuelve PCTV.local y se usa RTSP/TCP, puerto 80.')
    Write-Host ('Registro MPV: ' + (Join-Path $appDir 'mpv-rtsp.log'))
    Write-Host 'Instalacion terminada.'
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
