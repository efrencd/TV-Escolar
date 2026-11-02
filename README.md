# TV Escolar en directo

Recursos técnicos del proyecto **TV Escolar** del **CEIP Villaverde (Fuerteventura, Canarias)**, para producir programas escolares en directo y distribuirlos por la red informática del centro.

Este repositorio publica el **instalador de mpv para los ordenadores Windows de las aulas**. La documentación y los recursos se ampliarán conforme se vayan validando.

## Arquitectura del sistema

```text
Cámaras / VillaCam (SRT) ──► OBS Studio (ordenador principal)
                                      │
                         ┌────────────┼────────────┐
                         ▼            ▼            ▼
                   UDP Multicast   Mediateca     Grabación local*
                     (red LAN)    (Internet)      (opcional)
                         │         (opcional)
                         ▼
                  Aulas: mpv / VLC
```

*La grabación local simultánea todavía está pendiente de concretar y validar.*

- **Cámaras:** conexión directa al ordenador o teléfonos Android con [VillaCam](https://github.com/efrencd/VillaCam), mediante SRT. VDO.Ninja/WebRTC es otra posibilidad.
- **Realización:** OBS Studio mezcla imágenes y sonido y produce el programa.
- **Distribución:** OBS emite un único flujo UDP Multicast para los ordenadores de las aulas.
- **Recepción:** mpv o VLC reproducen la señal dentro de la red del centro.

## Instalador de mpv para Windows

**Versión recomendada: v1.2.**

- [Instalar-TV-Escolar.cmd — enlace estable](instaladores/Instalar-TV-Escolar.cmd)
- [Instalar-TV-Escolar-v1.2.cmd — versión archivada](instaladores/Instalar-TV-Escolar-v1.2.cmd)

En GitHub, abre el archivo y selecciona **Download raw** para descargarlo.

### Qué hace el instalador

1. Comprueba que **WinGet** está disponible.
2. Busca mpv en el equipo y, si no está instalado, ejecuta `winget install --id shinchiro.mpv --exact --source winget --silent --accept-package-agreements --accept-source-agreements`.
3. Crea el acceso directo **TV Escolar** en el escritorio del usuario.
4. Configura mpv para mostrar una ventana incluso mientras espera la emisión, con el perfil `--profile=low-latency`.
5. Guarda el registro de diagnóstico en `%LOCALAPPDATA%\TVEscolar\mpv.log`.

El instalador se puede ejecutar de nuevo para recrear el acceso directo.

### Requisitos

- Windows con **WinGet** instalado (normalmente mediante *App Installer*).
- Acceso a Internet para instalar mpv si todavía no está presente.
- Conexión a una red desde la que se permita recibir tráfico **UDP Multicast**.
- OBS Studio configurado y emitiendo desde el ordenador principal.

Descarga el archivo `.cmd`, **revisa el código** y ejecútalo. Después, haz doble clic en **TV Escolar** en el escritorio. La ventana puede permanecer abierta mientras espera la transmisión.

La dirección que usa actualmente el instalador es:

```text
udp://239.10.10.10:5000
```

**Importante:** la dirección y el puerto están fijados en el script. Si tu centro utiliza otra configuración, hay que modificar el archivo o el acceso directo. El instalador **no configura OBS, cortafuegos ni dispositivos de red** y no puede habilitar multicast cuando la infraestructura lo bloquea.

## Alternativas: mpv y VLC

Se puede utilizar **mpv** o **VLC** en Windows y macOS. Para Android se recomienda **VLC**, siempre que la red Wi-Fi admita recepción multicast.

- **mpv:** `udp://239.10.10.10:5000`
- **VLC:** `udp://@239.10.10.10:5000`

Enlaces oficiales: [mpv](https://mpv.io/installation/) · [VLC](https://www.videolan.org/vlc/) · [OBS Studio](https://obsproject.com/es/download).

## Seguridad y pruebas

Antes de ejecutar un archivo `.cmd`, revisa su contenido y comprueba que cumple las políticas informáticas de tu centro. Windows puede mostrar avisos de seguridad y WinGet puede solicitar permisos.

La emisión multicasting depende de la infraestructura de red y puede no atravesar ciertas subredes o redes Wi-Fi. Comprueba la reproducción entre OBS y un ordenador receptor antes de implantarlo en todas las aulas.

## Proyecto relacionado

- [VillaCam](https://github.com/efrencd/VillaCam): aplicación Android de cámara inalámbrica para OBS mediante SRT.


---

## Distribucion RTSP unicast (OBS RTSP Server)

Para la red escolar mixta Ethernet y Wi-Fi, esta modalidad evita depender de UDP multicast en los puntos de acceso.

### Instaladores Windows

- [Instalar-TV-Escolar-RTSP-MPV.cmd](instaladores/Instalar-TV-Escolar-RTSP-MPV.cmd): instala MPV si es necesario y crea el acceso directo **TV Escolar (MPV)**. En cada apertura resuelve la IPv4 actual de PCTV mediante PowerShell (priorizando LLMNR/NetBIOS) y abre RTSP por TCP en una ventana normal. El docente puede alternar a pantalla completa pulsando **f**. El registro se guarda en %LOCALAPPDATA%\TVEscolar\mpv-rtsp.log.
- [Instalar-TV-Escolar-RTSP-VLC.cmd](instaladores/Instalar-TV-Escolar-RTSP-VLC.cmd): instala VLC si es necesario y crea el acceso directo **TV Escolar (VLC)**, que abre la direccion RTSP por TCP en una ventana normal directamente con el nombre PCTV, como ya se comprobo en el centro. El docente puede alternar a pantalla completa haciendo doble clic en el video.

Los dos usan **RTSP en el puerto 80, ruta /live**, con nombre de servidor **PCTV**. Son instaladores independientes; los archivos antiguos de multicast permanecen disponibles. Cada acceso directo se crea en el escritorio del usuario que ejecuta el instalador.

### Configuracion de OBS

En el equipo PCTV, activar el plugin OBS RTSP Server, el audio y el video H.264, usar el puerto **80** y la ruta **live**, desactivar multicast e iniciar el servidor. La direccion completa es **rtsp://PCTV:80/live**.

### Diagnostico y requisitos

MPV no resolvia el nombre PCTV con FFmpeg, aunque Windows pudo resolver una IPv4 mediante Resolve-DnsName. El nuevo lanzador consulta la IP cada vez; si no puede encontrarla, muestra un aviso. VLC usa el nombre directamente porque funciono en las pruebas. Si cambia el nombre, puerto o ruta del servidor, sera necesario actualizar los scripts.

Los scripts dependen de WinGet para instalar software ausente y pueden estar sujetos a las politicas del equipo. No modifican el cortafuegos, OBS ni los equipos Huawei. Probar primero con un equipo cableado y otro Wi-Fi, y despues con los 10–11 receptores. **No se ha verificado su ejecucion real en Windows gestionado por la Consejeria**.

