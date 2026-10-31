# Estado del proyecto

Este archivo es la memoria entre sesiones. Cada sesión lo lee al empezar y lo actualiza al terminar.
Mantenerlo corto: reemplazar lo viejo, no acumular.

## Dónde estamos

- S0 completo en la máquina de desarrollo. Falta S0b en el arcade (build Linux + joystick + parlante).
- S1 completo en la máquina de desarrollo (grilla, cursor, notas), verificado con captura de pantalla.
- Próxima sesión: S2 (secuenciador y audio).

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

- `project.godot`: Godot 4.7.2, renderer Compatibility, viewport 1280x720 con stretch `canvas_items`,
  pantalla completa, fondo oscuro (`default_clear_color`). El editor normalizó el encabezado al abrirlo.
- `export_presets.cfg`: preset `Linux` (x86_64, pck embebido), salida `build/arcumai.x86_64`.
  Export verificado: ELF x86_64 de 70 MB. Falta probarlo en el arcade (S0b).
- `scenes/main.tscn`: un único nodo raíz con `scripts/main.gd`.
- `scripts/main.gd`: registra el InputMap en `_enter_tree`, crea el `State` y los módulos, conecta las señales,
  oculta el mouse, Esc cierra solo en builds de debug.
- `scripts/config.gd`: acciones y mapeos, grilla (`STEPS` 16, `ROWS` 10, `LAYER_COUNT` 1), tiempos de repetición
  del cursor, colores de capa y estilos de grilla.
- `scripts/state.gd`: `State` y `State.Layer` (notas como conjunto de celdas `Vector2i`), cursor, `toggle_note`.
- `scripts/controller.gd`: mueve el cursor con repetición propia (250 ms inicial, 80 ms después), `btn1` alterna nota,
  `posmod` en X y `clampi` en Y.
- `scripts/view.gd`: grilla, notas de la capa activa y cursor con contorno parpadeante (600 ms).
- `tools/make_placeholder_wav.gd` y `assets/samples/layer_1.wav`: seno de 220 Hz con decay, 2 s, mono, 44.1 kHz.
- Verificado por mí: `--headless --quit` sin errores; captura de pantalla con input simulado (2 notas y cursor
  en la celda esperada); vuelta en X, tope en Y; 8 pasos en 800 ms manteniendo la dirección.
- Verificado en 4.7.2: `device = -1` matchea eventos de cualquier gamepad; `device = 0` no matchea otro índice.

## Decisiones tomadas durante el desarrollo

- S0: eventos de gamepad con `device = -1`. Probado: con `device = 0`, un gamepad de otro índice no matchea.
- S0: teclas por `physical_keycode`, para que no dependa del layout del teclado.
- S0: `quit_debug` (Esc) está en `Config.ACTIONS` y los HUDs de debug lo saltean.
- S0: el fondo oscuro va en `project.godot`, no en código.
- S1: la repetición del cursor se mide con `Time.get_ticks_msec()`, no con contadores de frames.
- S1: `Controller.move_cursor` es público para poder probar la vuelta y el tope sin simular input.

## Propuestas de diseño

Cambios que implican tocar `docs/DISENO.md`. El agente los anota acá; Maxi decide.
Formato: qué se propone, por qué, y qué evidencia lo sostiene (por ejemplo, la prueba con una persona de S2).

(vacío)

## Pendientes

- S0b en el arcade: correr `build/arcumai.x86_64`, probar joystick, 4 botones y sonido por el parlante.
- Confirmar en el arcade si el encoder aparece como gamepad o como teclado.
- Probar en el arcade la sensación del cursor: 250 ms de retardo y 80 ms por paso pueden quedar lentos o rápidos.
- Medir FPS en el arcade (S0b). Optimizar la vista solo si hay problema.
- Medir el pico de RAM al guardar una grabación de 8 minutos (S5).
- Reemplazar `layer_1.wav` placeholder cuando Maxi entregue los samples.

## Bugs conocidos

(vacío)

## Resultado de la prueba con persona (S2)

(vacío)
