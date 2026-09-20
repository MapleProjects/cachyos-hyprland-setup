# Guía Técnica del Entorno de Escritorio: Hyprland (Lua) + Caelestia Shell

Documentación exhaustiva para replicar la experiencia de usuario y arquitectura gráfica en instalaciones nuevas de CachyOS / Arch Linux sin dependencias ni datos personales.

---

## 1. Arquitectura y Componentes del Sistema

El entorno combina un compositor Wayland basado en Lua con un shell dinámico en QML/Quickshell.

| Componente | Paquete / Fuente | Rol en el sistema |
| --- | --- | --- |
| **Compositor** | `hyprland` (soporte Lua, v0.56.2+) | Gestor de ventanas tipo *tiling*, composición gráfica y renderizado |
| **Shell / Barras** | `caelestia-shell-git` (Quickshell) | Barra de estado, lanzador de aplicaciones, notificaciones, centro de control |
| **Workspaces Multi-Monitor** | `hyprsplit` (librería Lua) | Espacios de trabajo 1-10 independientes por cada pantalla |
| **Terminal** | `tilix` | Emulador de terminal con paneles divisibles y soporte de transparencia |
| **Gestor de Archivos** | `thunar` | Explorador gráfico estándar integrado con UDisks2 |
| **Grabación de Pantalla** | `gpu-screen-recorder` + `gsr-ui` | Captura y repetición instantánea acelerada por hardware |
| **Display Manager** | `sddm` + `caelestia-sddm-locklike-git` | Pantalla de inicio de sesión unificada con la estética del shell |

---

## 2. Transparencias y Estética Visual

El efecto de vidrio esmerilado (*frosted glass*) se logra mediante la coordinación entre el compositor, la aplicación y el shell.

### A. Transparencia en la Terminal Tilix
Tilix requiere configuración en dos niveles para lograr transparencia con desenfoque de fondo.

1. **Configuración interna de Tilix (Dconf):**
   Tilix debe habilitar el canal alfa en su perfil predeterminado.
   ```bash
   dconf write /com/gexperts/Tilix/profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d/use-transparent-background true
   dconf write /com/gexperts/Tilix/profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d/background-transparency-percent 15
   dconf write /com/gexperts/Tilix/profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d/use-system-font true
   dconf write /com/gexperts/Tilix/profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d/font "'Rubik Bold 11'"
   ```

2. **Regla de ventana en Hyprland (`hyprland.lua`):**
   Hyprland captura la clase de Tilix y le aplica opacidad controlada.
   ```lua
   hl.window_rule({
       name    = "tilix-blur",
       match   = { class = "com.gexperts.Tilix" },
       opacity = 0.85,
   })
   ```

3. **Desenfoque global del compositor (`hyprland.lua`):**
   Para que las ventanas transparentes difuminen el fondo, se activa el desenfoque en la sección `decoration`.
   ```lua
   decoration = {
       rounding       = 10,
       rounding_power = 2,
       active_opacity   = 1.0,
       inactive_opacity = 1.0,

       blur = {
           enabled  = true,
           size     = 3,
           passes   = 1,
           vibrancy = 0.1696,
       },

       shadow = {
           enabled      = true,
           range        = 4,
           render_power = 3,
           color        = 0xee1a1a1a,
       },
   }
   ```

### B. Transparencia en Caelestia Shell
La barra superior y los paneles laterales manejan su transparencia interna desde `~/.config/caelestia/shell.json`.

```json
"appearance": {
    "deformScale": 1,
    "font": { "scale": 0.6 },
    "padding": { "scale": 1 },
    "rounding": { "scale": 1 },
    "spacing": { "scale": 1 },
    "transparency": {
        "base": 0.65,
        "enabled": true,
        "layers": 0.1
    }
}
```

### C. Bordes y Gaps Invisibles
Para una estética limpia sin líneas divisorias notorias, las variables de `general` eliminan gaps y usan bordes transparentes.
```lua
general = {
    gaps_in  = 0,
    gaps_out = 0,
    border_size = 1,
    col = {
        active_border   = "rgba(00000000)",
        inactive_border = "rgba(00000000)",
    },
    resize_on_border = true,
    allow_tearing    = true,
    layout           = "dwindle",
}
```

---

## 3. Configuración de Caelestia Shell (`shell.json`)

Archivo principal de configuración ubicado en `~/.config/caelestia/shell.json`.

### Espacios de Trabajo (Workspaces en la Barra)
- Muestra los escritorios en grupos de 5.
- Renderiza pequeños íconos representativos de las ventanas abiertas (máximo 3 por espacio).
```json
"workspaces": {
    "activeLabel": "",
    "activeTrail": false,
    "capitalisation": "Lower",
    "label": "",
    "occupiedBg": false,
    "occupiedLabel": "",
    "perMonitorWorkspaces": false,
    "showWindows": true,
    "maxWindowIcons": 3,
    "shown": 5
}
```

### Iconos de Estado Habilitados en la Barra
```json
"statusIcons": [
    { "enabled": false, "id": "lockStatus" },
    { "enabled": true,  "id": "kbLayout" },
    { "enabled": true,  "id": "audio" },
    { "enabled": true,  "id": "microphone" },
    { "enabled": true,  "id": "network" },
    { "enabled": true,  "id": "bluetooth" },
    { "enabled": false, "id": "battery" }
]
```

### Rutas y Terminal Preferida
```json
"general": {
    "apps": { "terminal": ["tilix"] },
    "logo": "cachyos"
},
"paths": {
    "wallpaperDir": "/home/maple/Imagenes/wallpapers"
}
```

---

## 4. Multi-Monitor Independiente con `hyprsplit` en Lua

La librería `hyprsplit` (`~/.config/hypr/hyprsplit`) desacopla los escritorios por monitor. El monitor principal (`eDP-1`) aloja IDs 1-10, y el secundario (`HDMI-A-1`) aloja IDs 11-20.

### Carga y Prioridad en `hyprland.lua`
```lua
package.path = os.getenv("HOME") .. "/.config/hypr/?.lua;" .. os.getenv("HOME") .. "/.config/hypr/?/init.lua;" .. package.path

local hs = require("hyprsplit")
hs.config({ num_workspaces = 10, persistent_workspaces = true })
hs.monitor_priority({ "eDP-1", "HDMI-A-1" })
```

### Lógica de Renombrado Ordinal
Caelestia Shell muestra el `name` del espacio de trabajo. Para que ambas pantallas muestren números idénticos del 1 al 0 (10) en sus barras, una función calcula el ordinal y renombra la instancia.
```lua
local function hyprsplit_ordinal(ws_id)
    local nws = hs.get_config("num_workspaces") or 10
    return ((ws_id - 1) % nws) + 1
end

local function hyprsplit_rename(ws)
    if not ws or ws.special then return end
    local ordinal = hyprsplit_ordinal(ws.id)
    local name = tostring(ordinal == 10 and 0 or ordinal)
    if ws.name ~= name then
        hl.dispatch(hl.dsp.workspace.rename({ workspace = ws.id, name = name }))
    end
end

function hyprsplit_rename_all()
    for _, ws in ipairs(hl.get_workspaces()) do
        hyprsplit_rename(ws)
    end
end
```

---

## 5. Tabla Maestra de Atajos de Teclado (Keybindings)

### A. Gestión de Ventanas y Sistema Base (`SUPER` = Tecla Windows)

| Atajo | Acción técnica | Propósito |
| --- | --- | --- |
| `SUPER + Enter` | `hl.dsp.exec_cmd("tilix")` | Abre la terminal predeterminada |
| `SUPER + E` | `hl.dsp.exec_cmd("thunar")` | Abre el gestor de archivos Thunar |
| `SUPER + V` | `hl.dsp.window.float({ action = "toggle" })` | Alterna modo flotante / mosaico |
| `SUPER + J` | `hl.dsp.layout("togglesplit")` | Alterna división horizontal o vertical |
| `SUPER + P` | `hl.dsp.window.pseudo()` | Modo pseudo-tiling |
| `ALT + F4` | `hl.dsp.window.close()` | Cierra la ventana activa |
| `SUPER + M` | `hyprshutdown` | Menú de apagado y salida |
| `SUPER + Flechas` | `hl.dsp.focus({ direction = ... })` | Mueve el foco entre ventanas adyacentes |
| `SUPER + SHIFT + Derecha` | `hl.dsp.window.move({ monitor = "HDMI-A-1" })` | Traslada ventana al monitor externo |
| `SUPER + SHIFT + Izquierda` | `hl.dsp.window.move({ monitor = "eDP-1" })` | Traslada ventana a la pantalla de la laptop |
| `SUPER + Click Izquierdo` | `hl.dsp.window.drag()` | Arrastra ventanas |
| `SUPER + Click Derecho` | `hl.dsp.window.resize()` | Redimensiona ventanas |

### B. Espacios de Trabajo (Workspaces con `follow = true`)

| Atajo | Acción técnica | Comportamiento |
| --- | --- | --- |
| `SUPER + [1..9, 0]` | `hs.dsp.focus({ workspace = i })` | Cambia de espacio en el monitor activo (0 representa el 10) |
| `SUPER + SHIFT + [1..9, 0]` | `hs.dsp.window.move({ workspace = i, follow = true })` | Mueve la ventana y traslada el foco y la pantalla al espacio destino |
| `SUPER + Rueda Ratón` | `hs.dsp.focus({ workspace = "e+1" / "e-1" })` | Navega entre espacios contiguos con ventanas |
| `SUPER + G` | `hs.dsp.grab_rogue_windows()` | Rescata ventanas huérfanas al desconectar un monitor |

### C. Paneles de Caelestia Shell (IPC / DBus)

| Atajo | Acción ejecutada | Componente desplegado |
| --- | --- | --- |
| `SUPER` (toque suelto) o `SUPER + D` | `caelestia:launcher` | Buscador de aplicaciones |
| `SUPER + Tab` | `caelestia:dashboard` | Panel de métricas y reloj central |
| `SUPER + Escape` | `caelestia:session` | Menú de sesión (bloqueo, reiniciar, apagar) |
| `SUPER + N` | `caelestia:nexus` | Centro de conexiones y configuración rápida |
| `SUPER + S` | `caelestia:sidebar` | Barra lateral de utilidades y calendario |
| `SUPER + U` | `caelestia:utilities` | Cajón de herramientas complementarias |
| `SUPER + SHIFT + D` | `caelestia:showall` | Despliega todos los paneles simultáneamente |
| `SUPER + L` | `loginctl lock-session` | Bloquea la sesión de usuario |

### D. Capturas, Grabación y Multimedia

| Atajo | Comando ejecutado | Función |
| --- | --- | --- |
| `Print` | `screenshot` | Captura de pantalla completa |
| `SUPER + SHIFT + S` o `SHIFT + Print` | `screenshot --area` | Captura de área seleccionada |
| `ALT + F9` | `gsr-toggle` | Alterna grabación de GPU Screen Recorder |
| `ALT + Z` | `gsr-ui` | Abre interfaz gráfica de GPU Screen Recorder |
| `XF86AudioRaiseVolume` | `wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+` | Sube volumen (límite 100%) |
| `XF86AudioLowerVolume` | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-` | Baja volumen |
| `XF86MonBrightnessUp` | `brightnessctl -e4 -n2 set 5%+` | Incrementa brillo del panel |
| `XF86MonBrightnessDown` | `brightnessctl -e4 -n2 set 5%-` | Reduce brillo del panel |

---

## 6. Variables de Entorno y Autostart

Sección de inicialización en `hyprland.lua`.

```lua
-- Autostart
hl.on("hyprland.start", function ()
    hl.exec_cmd("caelestia shell -d")
    hl.exec_cmd("gsr-ui launch-daemon")
end)

-- Variables de entorno globales
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Renderizado hibrido NVIDIA (Apps pesadas a NVIDIA, compositor a Intel)
hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")
```

---

## 7. Notas Críticas de Resolución de Problemas y Quirks

### 1. Inconveniente de Eventos en Hyprland Lua (`hl.on`)
- **Problema:** En ciertas versiones compiladas con backend Lua (como 0.56.2-Maple), los eventos `hl.on("workspace.active")` o `hl.on("workspace.created")` no disparan de forma confiable.
- **Solución implementada:** Las llamadas de cambio y movimiento de workspaces se encapsulan en wrappers (`hyprsplit_wrap`). Además, se programó un re-escaneo diferido a 1.2 segundos tras iniciar o recargar (`hyprctl eval "hyprsplit_rename_all()"`), permitiendo que los escritorios persistentes concluyan su inicialización antes del renombrado.

### 2. Conflicto de Paquetes AUR con `qt6-m3shapes-git`
- **Problema:** Caelestia Shell 2.4.0 separó sus módulos gráficos creando el paquete `qt6-m3shapes-git`. Al actualizar vía `paru --overwrite`, los archivos huérfanos se limpian después del desempaquetado, dejando `/usr/lib/qt6/qml/M3Shapes` vacío e impidiendo el inicio de Caelestia (`module 'M3Shapes' is not installed`).
- **Solución:** Reinstalar el paquete explícitamente sin sobrescritura destructiva:
  ```bash
  sudo pacman -U /home/maple/.cache/paru/clone/qt6-m3shapes-git/*.pkg.tar.zst
  ```

### 3. Sincronización Automática de Wallpaper con SDDM
- **Procedimiento:** Caelestia unifica el wallpaper del escritorio, la pantalla de bloqueo y SDDM ejecutando:
  ```bash
  caelestia wallpaper -f /ruta/absoluta/imagen.jpg
  ```
- **Requisito:** `~/.config/caelestia/cli.json` debe contener el posthook apuntando a `/usr/share/sddm/themes/caelestia/scripts/sync.sh --posthook`, y `/etc/sudoers.d/caelestia-sddm-sync` debe otorgar permisos `NOPASSWD` para ejecutar ese script sin solicitar contraseña.

### 4. Aceleración de Video en Navegadores (Vivaldi / Chromium)
- **Problema:** Si `LIBVA_DRIVER_NAME=nvidia` se exporta de forma global para toda la sesión, los navegadores basados en Chromium fallan la inicialización de VA-API en la GPU discreta y caen a decodificación por software en CPU.
- **Solución:** Ejecutar el navegador con driver Intel dedicado:
  ```bash
  LIBVA_DRIVER_NAME=iHD vivaldi-stable --enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,AcceleratedVideoDecodeLinuxGL --disable-features=AcceleratedVideoDecodeLinuxZeroCopyGL
  ```

---

## 8. Bloqueo de Pantalla y Gestión de Sesión

El bloqueo de pantalla está integrado dentro de Caelestia Shell mediante su módulo nativo en Quickshell, interactuando directamente con PAM y `systemd-logind`.

### A. Mecanismo de Activación
- **Atajo global:** `SUPER + L`.
- **Comando subyacente:** `loginctl lock-session`.
- **Módulo de interfaz:** `LockSurface.qml` (en `/etc/xdg/quickshell/caelestia/modules/lock/`).
- **Autenticación:** Utiliza PAM (`Pam.qml`) con soporte biométrico para Howdy (reconocimiento facial por infrarrojos) y Fprint (sensor de huellas dactilares).

### B. Configuración del Bloqueo (`~/.config/caelestia/shell.json`)
```json
"lock": {
    "enabled": true,
    "enableFprint": true,
    "enableHowdy": true,
    "hideNotifs": false,
    "maxFprintTries": 3,
    "maxHowdyTries": 3,
    "recolourLogo": true,
    "triggerHowdyOnWake": true
}
```

### C. Gestor de Inicio de Sesión (SDDM)
- **Paquete AUR:** `caelestia-sddm-locklike-git`
- **Repositorio fuente:** [ItsABigIgloo/caelestia-sddm](https://github.com/ItsABigIgloo/caelestia-sddm)
- **Comando de instalación:**
  ```bash
  paru -S caelestia-sddm-locklike-git
  ```
- **Ruta de instalación:** `/usr/share/sddm/themes/caelestia`
- **Configuración en `/etc/sddm.conf`:**
  ```ini
  [Theme]
  Current=caelestia
  ```

### D. Sincronización Automática del Fondo de Pantalla (Escritorio, Bloqueo y SDDM)
El sistema no utiliza demonios externos como `swww` ni `hyprpaper`. La renderización del fondo la gestiona directamente Caelestia Shell (`quickshell`) para cada pantalla habilitada.

#### 1. Archivo de Hooks (`~/.config/caelestia/cli.json`)
Permite disparar la actualización del tema de login cada vez que cambia el fondo.
```json
{
  "wallpaper": {
    "postHook": "sudo /usr/share/sddm/themes/caelestia/scripts/sync.sh --posthook"
  },
  "theme": {
    "postHook": "sudo /usr/share/sddm/themes/caelestia/scripts/sync.sh --posthook"
  }
}
```

#### 2. Permiso Sudoers (`/etc/sudoers.d/caelestia-sddm-sync`)
Permite a Caelestia actualizar los archivos protegidos de SDDM sin solicitar contraseña interactiva.
```text
maple ALL=(root) NOPASSWD: /usr/share/sddm/themes/caelestia/scripts/sync.sh
```

#### 3. Comando Único para Cambiar Fondo
Para aplicar un nuevo fondo en todo el sistema sin reiniciar servicios:
```bash
caelestia wallpaper -f /ruta/absoluta/a/la/imagen.jpg
```
Este comando actualiza simultáneamente cuatro áreas del sistema:
- El fondo del escritorio activo en todos los monitores habilitados.
- La pantalla de bloqueo de sesión de usuario (`LockSurface.qml`).
- La pantalla de inicio de sesión de SDDM (`/usr/share/sddm/themes/caelestia/assets/background`).
- La paleta dinámica de colores de la interfaz (Material You / M3) aplicada a la barra, menús y acentos visuales.

---

## 9. Gestor de Arranque: Tema GRUB (Furina)

El menú de inicio utiliza el tema gráfico personalizado **Furina** (Genshin Impact).

### A. Ubicación de Archivos
- **Directorio del tema:** `/boot/grub/themes/Furina/`
- **Estructura del tema:**
  - `theme.txt` (definición de fuentes, posiciones de botones y colores de texto)
  - `background.png` (imagen de fondo en alta resolución)
  - `select_c.png`, `select_e.png`, `select_w.png` (estilos del cursor de selección)
  - `icons/` (íconos representativos para CachyOS, Windows, Arch Linux, UEFI)

### B. Configuración en `/etc/default/grub`
Para aplicar el tema en cualquier instalación nueva:
```ini
GRUB_GFXMODE=auto
GRUB_THEME="/boot/grub/themes/Furina/theme.txt"
```

### C. Aplicación de Cambios
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 10. Paquete de Respaldo Generado

Los archivos listos para transferir a la nueva computadora quedaron organizados en el directorio del escritorio:
`~/Escritorio/entorno-escritorio-backup/`

### Contenido de la Carpeta
- `grub-theme/Furina/`: Tema completo de GRUB con fondos, fuentes y reglas de estilo.
- `hypr/`: Configuración íntegra de Hyprland (`hyprland.lua`), atajos de Caelestia (`caelestia-keybinds.conf`), librería `hyprsplit` y shaders.
- `caelestia/`: Ajustes del shell (`shell.json`), hooks de sincronización (`cli.json`) y configuraciones de monitores.
- `SOUL.md`: Archivo maestro de identidad, directivas y protocolos del agente.
- `desktop-environment-guide.md`: Esta misma guía técnica de referencia.

---

## 11. Ecosistema de IA: Hermes Agent, Qdrant, MCPs y Obscura

Infraestructura de agentes de desarrollo, memoria persistente semántica y navegación web headless.

### A. Base de Datos Vectorial: Qdrant
Qdrant actúa como el almacén de memoria duradera del sistema.

1. **Despliegue con Docker:**
   Se ejecuta como contenedor persistente con política de reinicio automático.
   ```bash
   docker run -d \
     --name qdrant \
     --restart unless-stopped \
     -p 6333:6333 \
     -p 6334:6334 \
     -v qdrant_storage:/qdrant/storage:z \
     qdrant/qdrant:latest
   ```
2. **Puertos y Acceso:**
   - Puerto `6333`: API HTTP REST (utilizada por los clientes y servidores MCP).
   - Puerto `6334`: API gRPC interna.
   - Volumen `qdrant_storage`: Mantiene los vectores e índices guardados en disco.

### B. Hermes Agent
Plataforma de agente de código autónomo desarrollada por Nous Research.

1. **Instalación y Despliegue:**
   - Repositorio base: [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent.git)
   - Clonación: `git clone https://github.com/NousResearch/hermes-agent.git ~/.hermes/hermes-agent`
   - Configuración inicial: Ejecutar `./setup-hermes.sh` dentro del repositorio clonado.
   - Script lanzador en `~/.local/bin/hermes`:
     ```bash
     #!/usr/bin/env bash
     unset PYTHONPATH
     unset PYTHONHOME
     exec "$HOME/.hermes/hermes-agent/venv/bin/hermes" "$@"
     ```
2. **Identidad del Agente (`SOUL.md`):**
   - Ubicación: `~/.hermes/SOUL.md`
   - Define el estilo de comunicación directo, reglas de cero relleno, flujo de trabajo Qdrant-First y protocolos de auto-documentación.
   - Se incluye una copia directa en la carpeta de respaldo generada.

### C. Servidores MCP Configurados (`~/.hermes/config.yaml`)
Hermes interactúa con el entorno mediante servidores de protocolo MCP definidos bajo la clave `mcp_servers`:

```yaml
mcp_servers:
  # Memoria vectorial persistente
  qdrant-memory:
    command: uvx
    args:
      - --from
      - git+https://github.com/sascha08-15/mcp-server-qdrant@feature/add-delete-tool
      - mcp-server-qdrant
    connect_timeout: 120
    timeout: 180
    env:
      QDRANT_URL: http://localhost:6333
      COLLECTION_NAME: hermes-memory
      EMBEDDING_MODEL: sentence-transformers/all-MiniLM-L6-v2

  # Grafo de código y análisis estático
  codebase-memory-mcp:
    command: codebase-memory-mcp
    args:
      - serve
    connect_timeout: 120
    timeout: 300

  # Inspección e interacción con Chromium
  chrome-devtools-mcp:
    command: npx
    args:
      - -y
      - chrome-devtools-mcp@latest
      - --browserUrl
      - http://127.0.0.1:9222
    connect_timeout: 120
    timeout: 300

  # Automatización web con Playwright
  playwright-mcp:
    command: npx
    args:
      - -y
      - '@playwright/mcp@latest'
      - --browser
      - chrome
      - --cdp-endpoint
      - http://127.0.0.1:9222
      - --caps
      - testing,storage
    connect_timeout: 120
    timeout: 300
```

### D. Navegador Headless: Obscura
Navegador ligero de alto rendimiento con capacidades anti-detección para scraping y navegación automatizada.

1. **Instalación en CachyOS / Arch:**
   Se encuentra disponible en el AUR mediante el paquete oficial binario.
   ```bash
   paru -S obscura-browser-bin
   ```
2. **Rutas y Binarios:**
   - Binario base: `/usr/bin/obscura`
   - Enlace simbólico de conveniencia: `/usr/local/bin/obscura`
   - Repositorio oficial: [h4ckf0r0day/obscura](https://github.com/h4ckf0r0day/obscura)
3. **Uso habitual en scripts y agentes:**
   - Extracción de contenido con protección anti-bot:
     ```bash
     obscura fetch "https://ejemplo.com" --dump text --stealth
     ```
   - Evaluación rápida de JavaScript:
     ```bash
     obscura fetch "https://ejemplo.com" --eval "document.title"
     ```


