# Estado del proyecto

Este archivo es la memoria entre sesiones. Cada sesión lo lee al empezar y lo actualiza al terminar.
Mantenerlo corto: reemplazar lo viejo, no acumular.

## Dónde estamos

- Sesión en curso: S0 (esqueleto y prueba en hardware real), hecho lo que se puede hacer en la máquina de desarrollo.
- Falta de S0: el preset de exportación `Linux` (lo hace Maxi) y la prueba en el arcade (S0b).

## Datos a confirmar (Maxi)

| Dato | Valor |
|---|---|
| Versión de Godot | 4.7.2 stable oficial (`ed1daf0bf`), verificado con `--version` |
| Ruta del binario en la máquina de desarrollo | `C:\Users\maxim\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe` (esa carpeta se llama `...exe`; adentro está también el `_console.exe`, que es el que imprime en la terminal) |
| Especificaciones de la mini PC del arcumai (CPU, RAM, gráficos) | por confirmar |
| Cómo ve Fedora el joystick (gamepad o teclado) | por confirmar en S0b (probar con `evtest` o `jstest`) |
| Índice de gamepad que asigna el encoder | ya no bloquea: las acciones se registran con `device = -1` (cualquier dispositivo). Confirmar igual en S0b |
| Salida de audio (parlante interno, jack, HDMI, parlante externo) | por confirmar |
| Cómo se lanza hoy el arcade (frontend, launcher, escritorio) | por confirmar |
| Quién administra el arcade y conoce el combo de salida (4 botones, 5 s) | por confirmar |
| Samples de las capas (`layer_1.wav` … `layer_4.wav` y nota raíz MIDI de cada uno) | por entregar, antes de S2 |
| Carpeta donde se guardan las piezas | por decidir (S5) |
| ¿La mini PC tiene internet? | por confirmar |

## Hecho

- `project.godot`: Godot 4.7.2, renderer Compatibility, viewport 1280x720 con stretch `canvas_items`/`keep`,
  pantalla completa, fondo oscuro (`default_clear_color`).
- `scenes/main.tscn`: un único nodo raíz con `scripts/main.gd`.
- `scripts/config.gd`: `class_name Config`, lista única de acciones y mapeos (WASD + HJKL; flechas + Ctrl, Alt,
  Espacio, Shift; D-pad; botones A/B/X/Y; eje izquierdo).
- `scripts/main.gd`: registra el InputMap en `_enter_tree`, oculta el mouse, HUD temporal con las 8 acciones y
  contador, reproduce el sample con `btn1`, Esc cierra solo en builds de debug.
- `tools/make_placeholder_wav.gd` y `assets/samples/layer_1.wav`: seno de 220 Hz con decay, 2 s, mono, 44.1 kHz.
- Verificado por mí: `--headless --quit` sin errores; corrida en ventana con captura PNG (HUD visible, acciones
  apretadas resaltadas, contador en 1); `device = -1` matchea eventos de cualquier gamepad en 4.7.2.

## Decisiones tomadas durante el desarrollo

- S0: eventos de gamepad con `device = -1`. Probado: con `device = 0`, un gamepad de otro índice no matchea.
- S0: teclas por `physical_keycode`, para que no dependa del layout del teclado.
- S0: `quit_debug` (Esc) está en `Config.ACTIONS` y el HUD lo saltea.
- S0: el fondo oscuro va en `project.godot`, no en código.

## Propuestas de diseño

Cambios que implican tocar `docs/DISENO.md`. El agente los anota acá; Maxi decide.
Formato: qué se propone, por qué, y qué evidencia lo sostiene (por ejemplo, la prueba con una persona de S2).

(vacío)

## Pendientes

- Crear el preset de exportación `Linux` (Maxi) e instalar las plantillas de exportación de 4.7.2.
- Exportar el build Linux x86_64 y probarlo en el arcade (S0b): joystick, 4 botones, sonido por el parlante.
- Confirmar en el arcade si el encoder aparece como gamepad o como teclado, y con qué índice.
- Medir FPS en el arcade (S0b). Optimizar la vista solo si hay problema.
- Medir el pico de RAM al guardar una grabación de 8 minutos (S5).
- Reemplazar `layer_1.wav` placeholder cuando Maxi entregue los samples.

## Bugs conocidos

(vacío)

## Resultado de la prueba con persona (S2)

(vacío)
