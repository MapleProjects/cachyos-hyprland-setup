# Guía de Diagnóstico y Resolución del Bucle de Inicio de Sesión (Login Loop) en SDDM e Hyprland

Documento técnico especializado para resolver el fallo en el que SDDM solicita la contraseña, la pantalla parpadea en negro y regresa de inmediato al inicio de sesión sin cargar el entorno gráfico.

---

## Causa Raíz General

SDDM autentica al usuario a través de PAM correctamente. Sin embargo, al invocar el script o ejecutable de la sesión seleccionada (`Hyprland`), el compositor encuentra un fallo fatal en su inicialización temprana y aborta el proceso con código de error. Al morir el proceso hijo de la sesión, SDDM asume que la sesión terminó y reabre el greeter de login.

---

## 1. Problemas Frecuentes, Causas y Soluciones

### Problema 1: Sesión Incompatible Seleccionada (`Hyprland` vs `Hyprland (UWSM)`)
- **Causa:** CachyOS y Arch Linux instalan por defecto la entrada de sesión gestionada por UWSM (*Universal Wayland Session Manager*). Si está seleccionada dicha sesión pero las unidades de usuario en systemd no están habilitadas o fallan al enlazar el compositor, el entorno no inicia.
- **Solución:**
  1. En la pantalla de SDDM, localizar el menú desplegable de sesiones (usualmente en la esquina superior izquierda o inferior).
  2. Cambiar la selección de `Hyprland (UWSM)` a `Hyprland` (sesión directa).
  3. Ingresar la contraseña para iniciar de manera estándar.

### Problema 2: Variables de Entorno del Greeter y Permisos Qt (`caelestia.conf`)
- **Causa:** El tema de SDDM de Caelestia (`caelestia-sddm-locklike-git`) utiliza componentes QML que leen archivos locales (fondos de pantalla en `/usr/share/sddm/themes/caelestia/assets/`). Si SDDM opera bajo un backend incompatible o sin permisos XHR de lectura de archivos, el greeter colapsa o no realiza la transición hacia la sesión Wayland.
- **Solución:**
  Crear el archivo de configuración `/etc/sddm.conf.d/caelestia.conf` con las siguientes directivas:
  ```ini
  [General]
  GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1,QT_QPA_PLATFORM=xcb

  [Theme]
  Current=caelestia
  ```

### Problema 3: Falta de Modosetting en Controladores NVIDIA
- **Causa:** En tarjetas gráficas NVIDIA (híbridas o dedicadas), Wayland requiere que el módulo del kernel inicialice el búfer de cuadros mediante DRM (*Direct Rendering Manager*). Sin el parámetro `modeset=1`, Hyprland no puede abrir el dispositivo gráfico y cierra la sesión.
- **Solución:**
  1. Editar `/etc/default/grub` y añadir los siguientes parámetros a `GRUB_CMDLINE_LINUX_DEFAULT`:
     ```text
     nvidia_drm.modeset=1 nvidia_drm.fbdev=1
     ```
  2. Regenerar el archivo de configuración de GRUB:
     ```bash
     sudo grub-mkconfig -o /boot/grub/grub.cfg
     ```
  3. Asegurar que `/etc/mkinitcpio.conf` incluya los módulos en el orden correcto:
     ```text
     MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
     ```
  4. Reconstruir las imágenes initramfs:
     ```bash
     sudo mkinitcpio -P
     ```

### Problema 4: Error Fatal de Sintaxis en `hyprland.lua` o Dependencias Faltantes
- **Causa:** Si la configuración en Lua contiene errores de sintaxis, invoca funciones inexistentes o intenta cargar librerías no presentes (como `hyprsplit`), el runtime de Lua falla inmediatamente durante el arranque.
- **Solución:**
  1. Acceder a la consola virtual TTY presionando `Ctrl + Alt + Fn + F3`.
  2. Iniciar sesión con usuario y contraseña.
  3. Invocar el compositor directamente en la terminal:
     ```bash
     Hyprland
     ```
  4. El comando imprimirá el rastreo de error en la consola, indicando el número exacto de línea y archivo con el fallo (por ejemplo, en `~/.config/hypr/hyprland.lua`). Corregirlo con un editor de texto de terminal (`nano` o `vim`).

### Problema 5: Permisos de Archivos Corruptos en `$HOME`
- **Causa:** El uso de comandos gráficos con `sudo` sin el parámetro `-H` puede cambiar la propiedad de carpetas críticas a `root:root` (por ejemplo `.Xauthority`, `~/.local/share/hyprland` o sockets en `/run/user/1000/`). Al no poder escribir en sus propios archivos de bloqueo o registro, Hyprland finaliza abruptamente.
- **Solución:**
  Restaurar los permisos desde la consola TTY:
  ```bash
  sudo chown -R $USER:$USER /home/$USER
  ```

---

## 2. Metodología de Diagnóstico en Tiempo Real desde TTY

Cuando el sistema rebota al login, no se deben adivinar las causas. Se accede a la consola de texto puro para leer los registros exactos.

### Paso 1: Cambiar a la TTY
Presionar `Ctrl + Alt + Fn + F3` (o `F4`/`F5`) e iniciar sesión con las credenciales de usuario.

### Paso 2: Consultar los registros de SDDM
Ejecutar el siguiente comando para ver qué reportó el gestor de pantalla en el intento de inicio:
```bash
journalctl -u sddm -b --no-pager -n 80
```
- Si reporta `Authentication error`, revisar PAM o bloqueo de contraseña por intentos fallidos (`pam_faillock`).
- Si reporta `Session "/usr/share/wayland-sessions/hyprland.desktop" selected` y luego `Session finished with exit code X`, el fallo es 100% interno de Hyprland.

### Paso 3: Consultar el registro de Hyprland
Revisar el archivo de registro generado por el compositor en el intento fallido:
```bash
cat ~/.local/share/hyprland/hyprland.log | tail -n 100
```
- Buscar líneas marcadas con `[ERROR]` o `[CRITICAL]`.
- En caso de problemas de GPU, reportará mensajes del tipo `EGL_NOT_INITIALIZED` o `Failed to open DRM device`.
