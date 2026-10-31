# Estado del proyecto

Este archivo es la memoria entre sesiones. Cada sesión lo lee al empezar y lo actualiza al terminar.
Mantenerlo corto: reemplazar lo viejo, no acumular.

## Dónde estamos

- S0, S1, S2 y S3 completos en la máquina de desarrollo, con samples placeholder (dos por capa, cuatro capas).
- Suenan las 4 capas a la vez, cada una con su período y su color; `btn2` cambia la capa activa y, después de la
  cuarta, muestra las cuatro juntas en modo solo mirar.
- Bloqueado antes de S4: S0b en el arcade y la entrega de los samples reales.

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
| Samples de las capas (`layer_N_low.wav` / `layer_N_high.wav`, N = 1…4, y nota raíz MIDI de cada uno) | por entregar, antes de S4 |
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
- `scripts/config.gd`: acciones y mapeos, grilla (16x10, 4 capas), tiempos del cursor, colores por capa, períodos por
  capa con `TEMPO_SCALE` global, escala pentatónica menor de 10 grados, dos samples por capa (grave/agudo) con su
  nota raíz, corte de zona y volumen.
- `scripts/state.gd`: `State` y `State.Layer` (notas como conjunto de celdas `Vector2i`), cursor, `toggle_note`.
- `scripts/controller.gd`: cursor con repetición propia (250 ms inicial, 80 ms después), `btn1` alterna nota,
  `btn2` pasa a la capa siguiente (circular) y emite `layer_changed`, `posmod` en X y `clampi` en Y.
- `scripts/sequencer.gd`: fase por capa calculada desde el origen con su período y `TEMPO_SCALE`;
  `step_entered(layer, step)` al cambiar de paso.
- `scripts/voice_pool.gd`: un pool por capa y zona (4 x 2 x 8 voces = 64 reproductores), `pitch_scale` =
  2^(semitonos/12) contra la raíz del sample de la zona, suenan las notas de todas las capas y la nota fantasma
  solo en la capa activa, vista previa al cambiar de capa, zona muda con `push_error` si falta el sample.
- `scripts/view.gd`: grilla, notas de la capa activa (o de las 4 en la vista de todas), una línea de barrido por capa
  (la activa más gruesa y encima) y cursor con contorno parpadeante (600 ms) que desaparece en la vista de todas.
- `tools/make_placeholder_wav.gd` y `assets/samples/layer_N_low.wav` / `layer_N_high.wav` (N = 1…4):
  senos con decay, 2 s, mono, 44.1 kHz, raíz MIDI 57 el grave y 69 el agudo, con armónicos distintos por capa
  para distinguirlas de oído.
- Verificado por mí: `--headless --quit` sin errores de script; 4 capas con sus 8 samples cargados; alturas por zona
  (fila 9 = 1.000 y fila 0 = 1.782 en las cuatro capas); una nota en el paso 3 suena en las 4 capas; la nota fantasma
  solo suena en la capa activa; `btn2` recorre 1→2→3→4→vista de todas→1 conservando las notas y hace sonar la vista
  previa en cada capa; en la vista de todas, B1 y el joystick no tocan el estado y el fantasma no suena;
  avance de fase medido en 2 s dentro de 0.01 pasos de lo esperado; capturas de la vista de todas (4 colores) y de
  la capa 1 (solo su color).

### Medición de tiempo (S2)

Corrida en ventana de 90 s con el monitor a 165 Hz: 204 pasos, intervalo medio 437.5 ms (esperado 437.5),
retraso medio del disparo dentro del paso 3.5 ms, un solo pico de 68 ms (coincide con un hitch de frame de 108 ms),
deriva acumulada 4.7 ms (dentro de la cuantización de frame), 0 pasos salteados, objetos estables (1567 → 1562).
En el arcade, a 60 fps, el peor caso esperado por frame es de ~17 ms.

En S3 se midió el avance de las 4 líneas durante 2 s: 4.59 / 3.38 / 2.84 / 2.34 pasos, todos dentro de 0.01 pasos
de lo esperado por período.

## Decisiones tomadas durante el desarrollo

- S0: eventos de gamepad con `device = -1`. Probado: con `device = 0`, un gamepad de otro índice no matchea.
- S0: teclas por `physical_keycode`, para que no dependa del layout del teclado.
- S0: `quit_debug` (Esc) está en `Config.ACTIONS` y los HUDs de debug lo saltean.
- S0: el fondo oscuro va en `project.godot`, no en código.
- S1: la repetición del cursor se mide con `Time.get_ticks_msec()`, no con contadores de frames.
- S1: `Controller.move_cursor` es público para poder probar la vuelta y el tope sin simular input.
- S2: la fase se recalcula desde `Time.get_ticks_usec()` en cada frame; no se acumula `delta`.
- S2: las notas se disparan al entrar al paso (señal), no con temporizadores por nota.
- S2: 16 voces repartidas en dos zonas de 8 (grave/agudo), en round-robin por zona. Así cada disparo no reutiliza
  una voz de la otra zona, y el tope de polifonía sigue acotado.
- S2: la nota fantasma usa la misma voz y el mismo volumen que una nota asentada.
- S2: dos samples por capa (decisión de Maxi): filas 5–9 con el grave, 0–4 con el agudo. Cada zona se estira
  como máximo 10 semitonos en vez de 22. La raíz MIDI de cada sample se declara en `LAYER_SAMPLE_ROOT_MIDI`.
- S3: un pool de voces por capa y zona, creado al arrancar. Cambiar de capa no recarga samples ni corta lo que suena.
- S3: suenan las notas de todas las capas; la nota fantasma (cursor) solo en la capa activa.
- S3: `btn2` emite `layer_changed` y main lo conecta a la vista previa del cursor, para que el cambio de timbre
  se escuche en el acto.
- S3: la línea de la capa activa va más gruesa y se dibuja última (encima). En la vista de todas valen lo mismo.
- S3: `TEMPO_SCALE` divide los períodos (más grande = más rápido), fijo en 1.0 por ahora.
- S3: después de la capa 4, `btn2` muestra la vista de todas las capas (decisión de Maxi). Es solo para mirar:
  `State.show_all_layers` corta el cursor, el fantasma, B1 y el joystick; solo responde B2, que vuelve a la capa 1
  y hace sonar la vista previa. `get_active_layer()` tiene un assert para que nadie edite en esa vista.

## Propuestas de diseño

Cambios que implican tocar `docs/DISENO.md`. El agente los anota acá; Maxi decide.
Formato: qué se propone, por qué, y qué evidencia lo sostiene (por ejemplo, la prueba con una persona de S2).

(vacío)

## Pendientes

- S0b en el arcade: correr `build/arcumai.x86_64`, probar joystick, 4 botones y sonido por el parlante.
- Confirmar en el arcade si el encoder aparece como gamepad o como teclado.
- Probar en el arcade la sensación del cursor: 250 ms de retardo y 80 ms por paso pueden quedar lentos o rápidos.
- Dejar la app 10 minutos corrida en el arcade (acá se midieron 90 s) y escuchar si aparece algún corte.
- Escuchar con las 4 capas si se distinguen de oído y si el conjunto no se ensucia. Los placeholders son senos;
  con los samples reales cambia.
- Con los samples reales, escuchar la unión de las dos zonas: en la fila 5 (grave, 10 semitonos arriba) y en la
  fila 4 (agudo, sin transponer) el timbre tiene que emparejar. Si no, mover `ZONE_SPLIT_ROW` o ajustar raíces.
- Medir FPS en el arcade (S0b) con las 4 capas y 64 voces. Optimizar la vista solo si hay problema.
- Medir el pico de RAM al guardar una grabación de 8 minutos (S5).

## Bugs conocidos

(vacío; el aviso de fuga de audio al cerrar es un artefacto de Godot, ver `AGENTS.md`)

## Resultado de la prueba con persona (S2)

Aprobada. Lo probó una persona unos minutos: "suena bien y la lógica es entretenida". No hizo falta explicarle nada.
S3 desbloqueado.
