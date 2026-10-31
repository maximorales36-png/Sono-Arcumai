# Estado del proyecto

Este archivo es la memoria entre sesiones. Cada sesión lo lee al empezar y lo actualiza al terminar.
Mantenerlo corto: reemplazar lo viejo, no acumular.

## Dónde estamos

- S0, S1 y S2 completos en la máquina de desarrollo, con sample placeholder.
- S2 suena: grilla, notas, nota fantasma y línea de barrido.
- Bloqueado antes de S3: S0b en el arcade y la prueba con una persona (obligatoria en S2).

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
| Samples de las capas (`layer_1.wav` … `layer_4.wav` y nota raíz MIDI de cada uno) | por entregar, antes de S3 |
| Carpeta donde se guardan las piezas | por decidir (S5) |
| ¿La mini PC tiene internet? | por confirmar |

## Hecho

- `project.godot`: Godot 4.7.2, renderer Compatibility, viewport 1280x720 con stretch `canvas_items`,
  pantalla completa, fondo oscuro (`default_clear_color`).
- `export_presets.cfg`: preset `Linux` (x86_64, pck embebido), salida `build/arcumai.x86_64`.
  Export verificado: ELF x86_64 de 70 MB. Falta probarlo en el arcade (S0b).
- `scenes/main.tscn`: un único nodo raíz con `scripts/main.gd`.
- `scripts/main.gd`: registra el InputMap en `_enter_tree`, crea `State`, `Sequencer`, `VoicePool`, `Controller`
  y `View`, conecta `step_entered`, oculta el mouse, Esc cierra solo en builds de debug.
- `scripts/config.gd`: acciones y mapeos, grilla (16x10, 1 capa), tiempos del cursor, colores, períodos por capa,
  escala pentatónica menor de 10 grados, nota raíz y volumen.
- `scripts/state.gd`: `State` y `State.Layer` (notas como conjunto de celdas `Vector2i`), cursor, `toggle_note`.
- `scripts/controller.gd`: cursor con repetición propia (250 ms inicial, 80 ms después), `btn1` alterna nota,
  `posmod` en X y `clampi` en Y.
- `scripts/sequencer.gd`: fase por capa calculada desde el origen; `step_entered(layer, step)` al cambiar de paso.
- `scripts/voice_pool.gd`: 16 voces en round-robin a -6 dB, `pitch_scale` = 2^(semitonos/12), nota fantasma del
  cursor, capa muda con `push_error` si falta el sample.
- `scripts/view.gd`: grilla, notas, línea de barrido por capa y cursor con contorno parpadeante (600 ms).
- `tools/make_placeholder_wav.gd` y `assets/samples/layer_1.wav`: seno de 220 Hz con decay, 2 s, mono, 44.1 kHz.
- Verificado por mí: `--headless --quit` sin errores de script; alturas (fila de abajo 1.000, de arriba 3.564);
  disparos correctos (nota en el paso, fantasma en el cursor, nada en paso vacío, nada en capa inactiva);
  captura de pantalla con notas y línea de barrido.

### Medición de tiempo (S2)

Corrida en ventana de 90 s con el monitor a 165 Hz: 204 pasos, intervalo medio 437.5 ms (esperado 437.5),
retraso medio del disparo dentro del paso 3.5 ms, un solo pico de 68 ms (coincide con un hitch de frame de 108 ms),
deriva acumulada 4.7 ms (dentro de la cuantización de frame), 0 pasos salteados, objetos estables (1567 → 1562).
En el arcade, a 60 fps, el peor caso esperado por frame es de ~17 ms.

## Decisiones tomadas durante el desarrollo

- S0: eventos de gamepad con `device = -1`. Probado: con `device = 0`, un gamepad de otro índice no matchea.
- S0: teclas por `physical_keycode`, para que no dependa del layout del teclado.
- S0: `quit_debug` (Esc) está en `Config.ACTIONS` y los HUDs de debug lo saltean.
- S0: el fondo oscuro va en `project.godot`, no en código.
- S1: la repetición del cursor se mide con `Time.get_ticks_msec()`, no con contadores de frames.
- S1: `Controller.move_cursor` es público para poder probar la vuelta y el tope sin simular input.
- S2: la fase se recalcula desde `Time.get_ticks_usec()` en cada frame; no se acumula `delta`.
- S2: las notas se disparan al entrar al paso (señal), no con temporizadores por nota.
- S2: pool fijo de 16 voces en round-robin, sin buscar voz libre: más simple y acota la polifonía.
- S2: la nota fantasma usa la misma voz y el mismo volumen que una nota asentada.
- S2: fila de abajo = MIDI 57 (nota raíz del placeholder); la de arriba queda 22 semitonos más aguda.

## Propuestas de diseño

Cambios que implican tocar `docs/DISENO.md`. El agente los anota acá; Maxi decide.
Formato: qué se propone, por qué, y qué evidencia lo sostiene (por ejemplo, la prueba con una persona de S2).

(vacío)

## Pendientes

- S0b en el arcade: correr `build/arcumai.x86_64`, probar joystick, 4 botones y sonido por el parlante.
- Confirmar en el arcade si el encoder aparece como gamepad o como teclado.
- Probar en el arcade la sensación del cursor: 250 ms de retardo y 80 ms por paso pueden quedar lentos o rápidos.
- Dejar la app 10 minutos corrida en el arcade (acá se midieron 90 s) y escuchar si aparece algún corte.
- Con los samples reales, escuchar el rango completo: 22 semitonos es más de una octava. Si la fila de arriba
  suena mal, bajar el rango o usar dos samples por capa.
- **Prueba con una persona (obligatoria antes de S3)**: 3 minutos sin explicar nada, anotar el resultado acá abajo.
- Medir FPS en el arcade (S0b). Optimizar la vista solo si hay problema.
- Medir el pico de RAM al guardar una grabación de 8 minutos (S5).

## Bugs conocidos

(vacío; el aviso de fuga de audio al cerrar es un artefacto de Godot, ver `AGENTS.md`)

## Resultado de la prueba con persona (S2)

(vacío)
