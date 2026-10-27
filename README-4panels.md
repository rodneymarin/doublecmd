# Double Commander — 4 paneles de archivos

Fork de [Double Commander](https://doublecmd.github.io/) con **4 paneles de archivos** en
vez de 2, dispuestos en una cuadrícula 2×2 de igual tamaño.

El cambio es **multiplataforma**: todo el código nuevo es Pascal puro, sin
`{$IFDEF}` de plataforma, así que el mismo árbol de fuentes compila para
Windows, Linux y macOS.

---

## 1. Qué cambió

### 1.1 Modelo de paneles

El concepto de "panel" dejó de ser un par binario (`izquierda` / `derecha`) y
pasó a ser un índice:

```pascal
// src/ufilepanelselect.pas
TFilePanelIndex = 0..FILE_PANEL_COUNT-1;   // 0..3

const
  FILE_PANEL_COUNT  = 4;   // cantidad de paneles
  FILE_PANEL_ROWS   = 2;   // filas de la cuadrícula
  FILE_PANEL_COLUMNS= 2;   // columnas de la cuadrícula
```

Posiciones (orden de lectura):

| Índice | Posición    | Nota histórica |
|--------|-------------|----------------|
| 0      | arriba-izq. | era el panel izquierdo |
| 1      | arriba-der. | era el panel derecho |
| 2      | abajo-izq. | nuevo |
| 3      | abajo-der. | nuevo |

### 1.2 Archivos nuevos

| Archivo | Contenido |
|---------|-----------|
| `src/ufilepanel.pas` | Clase `TFilePanel`: contenedor, barra de discos, fila de herramientas, notebook con las pestañas de archivos. |
| `src/ufilepanelselectdlg.pas` | Diálogo modal para elegir el panel destino de una operación. |
| `build-win.ps1` | Script auxiliar de compilación en Windows. |

### 1.3 Layout

Los 4 paneles se dimensionan en `TfrmMain.LayoutPanels()`: la ventana se divide
en una cuadrícula de 2×2 con un margen de 2 px entre paneles. **No hay
splitters arrastrables**: los paneles son de igual tamaño y escalan con la
ventana.

Las constantes `FILE_PANEL_ROWS` / `FILE_PANEL_COLUMNS` controlan la
disposición. Cambiarlas a `1`/`4` (o `4`/`1`) da una fila o columna de 4
paneles sin tocar nada más.

### 1.4 Operaciones entre paneles

Antes "el otro panel" era único. Ahora hay un **panel destino** (`FTargetPanel`)
y las operaciones que dependían de él preguntan al usuario:

| Operación | Comportamiento |
|-----------|----------------|
| F5 Copiar / F6 Mover | Abre el diálogo "Copy to panel" / "Move to panel" |
| Ctrl+U Intercambiar | Abre el diálogo "Exchange with panel" |
| Comparar directorios | Abre el diálogo "Compare with panel" |
| Sincronizar directorios | Abre el diálogo "Synchronize with panel" |
| Symlink / Hardlink | Abre el diálogo "Create symlink/hardlink in panel" |
| Empaquetar | Abre el diálogo "Pack to panel" |
| Botón `<` de cada panel | Abre el diálogo "Take the directory from panel" |

El diálogo **excluye el panel activo**, así que nunca se copia un directorio
sobre sí mismo.

### 1.5 Teclado

| Tecla | Antes | Ahora |
|-------|-------|-------|
| `Tab` | alterna izquierda/derecha | cicla por los 4 paneles (arriba-izq → arriba-der → abajo-izq → abajo-der) |
| `Ctrl+Tab` | siguiente pestaña | siguiente pestaña (sin cambios) |

### 1.6 Persistencia

La configuración guarda las pestañas de los 4 paneles:

```xml
<Tabs>
  <OpenedTabs>
    <Left ActiveTab="0">   ...   <!-- panel 0, compatible con configs viejas -->
    <Right ActiveTab="0">  ...   <!-- panel 1, compatible con configs viejas -->
    <Panel3 ActiveTab="0"> ...   <!-- panel 2 (nuevo) -->
    <Panel4 ActiveTab="0"> ...   <!-- panel 3 (nuevo) -->
  </OpenedTabs>
</Tabs>
```

Las secciones `Left` / `Right` conservan el nombre histórico, así que una
configuración existente se sigue leyendo sin migración.

---

## 2. Compilar en Windows

Requisitos: **Lazarus 4.x** (con FPC 3.2.2) instalado. Probado con
Lazarus 4.8.0.0 + FPC 3.2.2 en `C:\lazarus`.

### Opción A — desde la línea de comandos

```powershell
# Registra los paquetes que el proyecto necesita (una sola vez)
$env:PATH = "C:\lazarus;C:\lazarus\fpc\3.2.2\bin\x86_64-win64;$env:PATH"
cd components
lazbuild chsdet\chsdet.lpk --ws=win32 --cpu=x86_64
lazbuild multithreadprocs\multithreadprocslaz.lpk --ws=win32 --cpu=x86_64
lazbuild kascrypt\kascrypt.lpk --ws=win32 --cpu=x86_64
lazbuild doublecmd\doublecmd_common.lpk --ws=win32 --cpu=x86_64
lazbuild Image32\Image32.lpk --ws=win32 --cpu=x86_64
lazbuild KASToolBar\kascomp.lpk --ws=win32 --cpu=x86_64
lazbuild viewer\viewerpackage.lpk --ws=win32 --cpu=x86_64
lazbuild gifview\gifview.lpk --ws=win32 --cpu=x86_64
lazbuild synunihighlighter\synuni.lpk --ws=win32 --cpu=x86_64
lazbuild virtualterminal\virtualterminal.lpk --ws=win32 --cpu=x86_64
```

Además hay que **registrar** (no compilar) los paquetes que ya trae Lazarus:

```powershell
lazbuild --add-package-link C:\lazarus\components\datetimectrls\datetimectrls.lpk
lazbuild --add-package-link C:\lazarus\components\lazcontrols\lazcontrols.lpk
lazbuild --add-package-link C:\lazarus\components\synedit\synedit.lpk
```

### Opción B — script auxiliar

```powershell
powershell -ExecutionPolicy Bypass -File .\build-win.ps1 -BuildMode release -Clean
```

Opciones: `-LazarusDir`, `-BuildMode release|debug`, `-WidgetSet`, `-Cpu`, `-Clean`.

Produce `doublecmd.exe` en la raíz del repositorio.

> **Nota:** el widgetset en Windows es `win32` (no `win64`); el objetivo de 64
> bits se elige con `--cpu=x86_64`.

### Opción C — build.sh / build.bat originales

`build.bat` y `build.sh` siguen funcionando sin cambios (salvo que el
proyecto ya no usa el splitter arrastrable, así que
`actPanelsSplitterPerPos` quedó como no-op).

---

## 3. Limitaciones conocidas

- **No hay redimensionado por arrastre.** Los 4 paneles son de igual tamaño.
  Si se quiere redimensionar, hay que cambiar `FILE_PANEL_ROWS` /
  `FILE_PANEL_COLUMNS` y recalcular `LayoutPanels()`.
- **La opción "Paneles horizontales"** del menú quedó sin efecto: la
  disposición es siempre la cuadrícula 2×2.
- **"Pestañas favoritas"** sigue restaurando solo en los paneles izquierdo y
  derecho (`Left` / `Right`); los paneles 3 y 4 no son destino de pestañas
  favoritas.
- **Comparar / Sincronizar directorios** siguen siendo operações entre **2**
  paneles (se eligen 2 de los 4), igual que en la versión original.
- El diálogo de selección de panel usa textos en inglés (como el resto de los
  textos nuevos del LFM, que no están traducidos).

---

## 4. Compilar para Linux

El árbol de fuentes es idéntico para Linux: **no hay nada específico de Windows**
en el código de los paneles, así que el mismo código compila y corre en Linux
sin cambios.

Hay dos vías disponibles desde una máquina Windows:

### 4.1 Vía WSL2 (la recomendada si tu Windows lo soporta)

WSL2 necesita el componente opcional **Virtual Machine Platform** y
**Windows Subsystem for Linux** habilitados:

```powershell
# desde una consola ELEVADA
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --install -d Ubuntu-22.04
```

> **Importante:** desactivá *Fast Startup* antes de reiniciar, o el reinicio
> puede restaurar el kernel anterior y **revertir** la activación de los
> componentes:
> ```powershell
> reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f
> powercfg /hibernate off
> ```

Después, dentro de WSL:

```bash
bash install/wsl/provision-wsl.sh
lcl=qt6 ./build.sh release
```

### 4.2 Vía VM con QEMU (funciona incluso sin WSL2)

Si WSL2 no es viable (por ejemplo, en builds *Insider* donde el payload de
virtualización no se aplica), se puede usar una VM Ubuntu completa con QEMU,
que emula x86_64 por software y no depende de ninguna función de
virtualización de Windows.

```powershell
# 1. Instalar QEMU
winget install SoftwareFreedomConservancy.QEMU

# 2. Preparar la semilla de cloud-init y el servidor que la publica
powershell -ExecutionPolicy Bypass -File .\install\linux-vm\make-seed.ps1
powershell -ExecutionPolicy Bypass -File .\install\linux-vm\seed-server.ps1   # en otra terminal

# 3. Levantar la VM (SSH en localhost:2222)
powershell -ExecutionPolicy Bypass -File .\install\linux-vm\run-vm.ps1 -Cpus 8 -MemMB 12288 -Display none

# 4. Dentro de la VM
tar xzf /tmp/dc-src.tar.gz -C ~/doublecmd    # el fuente, empaquetado desde Windows
bash install/linux-vm/provision-vm.sh
```

#### Ver y manejar la app desde Windows

La VM publica su escritorio X por **noVNC**, así que se maneja desde el
navegador sin instalar nada:

| Qué | Dónde |
|-----|-------|
| Escritorio Linux con el DC | **http://localhost:6080/vnc.html** |
| VNC nativo (cualquier cliente) | `localhost:5900` |
| SSH | `localhost:2222` (usuario `ubuntu`, clave `dcbuild`) |

El servicio `dcdesktop.service` arranca solo al iniciar la VM: Xorg (driver
`dummy`) + openbox + Double Commander + x11vnc + websockify.

#### Detalles importantes de esta vía

- **Widgetset `qt6`** (no gtk2): requiere el binding `qt6pas` 6.2.10, que se
  obtiene del paquete Debian `libqt6pas6-dev` (proyecto `davidbannon/libqt6pas`)
  y el runtime `libqt6pas6`. El `.so` también viene en
  `github.com/doublecmd/external` → `linux.tar.gz`.
- El **LCL de Lazarus** se compila aparte con `make LCL_PLATFORM=qt6` (el
  `make all` normal compila el widgetset por defecto).
- Los scripts del repo llegan con **CRLF** desde Windows: hay que normalizarlos
  (`sed -i 's/\r$//'`) o el hook `ExecuteBefore` del `.lpi` falla con exit 127.
- La VM **no tiene framebuffer** (`/dev/fb0` no existe), por eso el display de
  QEMU solo muestra la consola de texto y el escritorio se ve por VNC.
- Tiempos con 8 vCPU emulados: Lazarus ~13 min, Double Commander ~6 min
  (296.719 líneas).

### 4.3 Recipe original del proyecto (Linux nativo)

Es el que usa el CI oficial (`.github/workflows/snapshots.yml`, job `build-lin`):

```bash
sudo apt install fp-units-rtl fp-units-gtk2 fp-compiler fp-units-base fp-units-fcl \
                 fp-units-misc fp-units-net fp-utils patchelf libgtk-3-dev libdbus-1-dev zip
git clone --branch fixes_5 https://gitlab.com/freepascal.org/lazarus/lazarus.git
cd lazarus && make all && sudo make install
# ...
lcl=qt6 ./build.sh release
```

### 4.4 Empaquetado

```bash
install/create_packages.sh          # deb / rpm / tar.xz
```

---

## 5. Commits principales

```
d55578e67  WIP: add file panel model, 4-panel grid constants and panel select dialog
78f5d266d  WIP: frmMain refactor step 1 (panel model accessors)
19c138743  Feature: 4 file panels in a 2x2 grid (core refactor)
1da89b20c  Fix: panel layout, tools row and startup order for the 4 panel grid
1eda0cf38  Feature: panel selection dialog for operations between panels
```

---

## 6. Identidad de la app: coexistencia con el DC original (fork `doublecmd-4p`)

Este fork se instala como **aplicación independiente** para que no sustituya
ni interfiera con un Double Commander original ya presente en el sistema:

- **Configuración de usuario** (Linux): `~/.config/doublecmd-4p/`, controlada
  por la constante devuelta en `src/uGlobsPaths.pas::GetAppName` (ahora
  `'doublecmd-4p'`); esa misma cadena es el ID de instancia única, así que
  ambas apps pueden correr a la vez con la opción "una sola copia".
- **Instalación Linux** (`install/linux/install.sh`): binario
  `/usr/bin/doublecmd-4p`, ficheros en `/usr/lib{,64}/doublecmd-4p/` y
  `/usr/share/doublecmd-4p/`, entrada de menú `doublecmd-4p.desktop`
  ("Double Commander 4P") con icono `doublecmd-4p`, página de manual
  `doublecmd-4p.1` y política polkit `org.doublecmd4p.root`.
- Comando para regenerar dcrevision tras cambios:
  `install/linux/update-revision.sh <repo> <repo>` (escribe `units/dcrevision.inc`).
