@echo off
setlocal EnableExtensions DisableDelayedExpansion
title TV Escolar - Instalador v1.2

echo ============================================
echo       TV ESCOLAR - INSTALADOR v1.2
echo ============================================
echo.
echo Instala mpv (si hace falta) y configura el
echo acceso directo "TV Escolar" en el escritorio.
echo.

where winget.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: WinGet no esta disponible.
    echo Instala o actualiza "App Installer" desde Microsoft Store.
    goto :error
)

call :buscar_mpv
if not defined MPV_EXE (
    echo Instalando mpv con WinGet...
    winget install --id shinchiro.mpv --exact --source winget --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo ERROR: WinGet no pudo completar la instalacion.
        goto :error
    )
    call :buscar_mpv
)

if not defined MPV_EXE (
    echo ERROR: No se encuentra mpv.exe despues de la instalacion.
    goto :error
)

echo mpv localizado: "%MPV_EXE%"
echo.
echo Configurando el acceso directo...

rem Crear acceso directo directamente a mpv con una ventana visible
rem aun mientras espera la senal. Activar perfil de baja latencia.
rem Conservar la cache predeterminada; no usar --cache=no. Guardar log.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $d=Join-Path $env:LOCALAPPDATA 'TVEscolar'; New-Item -ItemType Directory -Path $d -Force | Out-Null; $log=Join-Path $d 'mpv.log'; $desktop=[Environment]::GetFolderPath('Desktop'); $shortcut=Join-Path $desktop 'TV Escolar.lnk'; $shell=New-Object -ComObject WScript.Shell; $s=$shell.CreateShortcut($shortcut); $s.TargetPath=$env:MPV_EXE; $s.Arguments='--no-terminal --force-window=immediate --idle=yes --profile=low-latency --log-file='+[char]34+$log+[char]34+' '+[char]34+'udp://239.10.10.10:5000'+[char]34; $s.WorkingDirectory=Split-Path -Parent $env:MPV_EXE; $s.IconLocation=$env:MPV_EXE+',0'; $s.Description='TV Escolar - UDP multicast'; $s.Save(); Write-Host ('Acceso directo creado: '+$shortcut); Write-Host ('Registro: '+$log)"
if errorlevel 1 (
    echo ERROR: No se pudo crear el acceso directo.
    goto :error
)

echo.
echo INSTALACION COMPLETADA.
echo.
echo Inicia el multicast en OBS y haz doble clic en
echo "TV Escolar". Se mostrara la ventana de mpv
echo incluso mientras espera el video. Usa perfil de baja latencia.
echo.
echo Si no aparece la imagen, revisa el fichero:
echo %LOCALAPPDATA%\TVEscolar\mpv.log
echo.
pause
exit /b 0

:buscar_mpv
for %%F in (
    "%ProgramFiles%\MPV Player\mpv.exe"
    "%ProgramFiles%\mpv\mpv.exe"
    "%ProgramFiles(x86)%\MPV Player\mpv.exe"
    "%LOCALAPPDATA%\Programs\MPV Player\mpv.exe"
    "%LOCALAPPDATA%\Programs\mpv\mpv.exe"
    "%LOCALAPPDATA%\Microsoft\WinGet\Links\mpv.exe"
    "%ProgramFiles%\WinGet\Links\mpv.exe"
) do if not defined MPV_EXE if exist "%%~F" set "MPV_EXE=%%~fF"
if not defined MPV_EXE (
    for /f "delims=" %%F in ('where mpv.exe 2^>nul') do if not defined MPV_EXE set "MPV_EXE=%%~fF"
)
exit /b 0

:error
echo.
echo Instalacion no finalizada. Revisa los mensajes anteriores.
pause
exit /b 1
