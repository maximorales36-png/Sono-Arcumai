# Estado del proyecto

Este archivo es la memoria entre sesiones. Cada sesión lo lee al empezar y lo actualiza al terminar.
Mantenerlo corto: reemplazar lo viejo, no acumular.

## Dónde estamos

- S0 a S5 completos en la máquina de desarrollo, con samples placeholder (dos por capa, cuatro capas).
- Suenan las 4 capas a la vez, cada una con su período, su color, su filtro y su reverb; `btn2` cambia la capa activa
  y, después de la cuarta, muestra las cuatro juntas en modo solo mirar. `btn3` mueve timbre y `btn4` envolvente.
- S5: la sesión se graba desde el arranque (tope de 8 min); B3 + B4 mantenidos 2 s guardan JSON + WAV en
  `user://piezas` y muestran el nombre 4 s; los 4 botones 5 s cierran la aplicación; a los 5 min sin input la pieza
  se vacía y la grabación se reinicia.
- S5b: en la vista de todas las capas el joystick maneja efectos globales: arriba enciende el delay (feedback creciente
  al mantener, izquierda/derecha el tiempo) y abajo el tremolo (profundidad creciente). Al soltar, se desvanecen.
- Bloqueado antes de S6: S0b en el arcade, la entrega de los samples reales y la prueba de S5/S5b por parte de Maxi.
  El arranque automático quedó fuera de alcance (la mini PC ya abre un menú de juegos).

## Datos a confirmar (Maxi)

| Dato | Valor |
|---|---|
| Versión de Godot | 4.7.2 stable oficial (`ed1daf0bf`), verificado con `--version` |
| Ruta del binario en la máquina de desarrollo | `C:\Users\maxim\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe` (esa carpeta se llama `...exe`; adentro está también el `_console.exe`, que es el que imprime en la terminal) |
| Especificaciones de la mini PC del arcumai (CPU, RAM, gráficos) | por confirmar |
| Cómo ve Fedora el joystick (gamepad o teclado) | por confirmar en S0b (probar con `evtest` o `jstest`) |
| Índice de gamepad que asigna el encoder | ya no bloquea: las acciones se registran con `device = -1` (cualquier dispositivo). Confirmar igual en S0b |
| Salida de audio (parlante interno, jack, HDMI, parlante externo) | por confirmar |
| Cómo se lanza hoy el arcade (frontend, launcher, escritorio) | la mini PC abre un menú con todos los juegos; el arranque automático y el reinicio si se cuelga quedaron fuera de S5 |
| Quién administra el arcade y conoce el combo de salida (4 botones, 5 s) | por confirmar |
| Samples de las capas (`layer_N_low.wav` / `layer_N_high.wav`, N = 1…4, y nota raíz MIDI de cada uno) | por entregar (S4 y S5 se probaron con placeholders) |
| ¿La mini PC tiene internet? | por confirmar |
| ¿Cuánto tarda en apagarse la mini PC con el combo de salida? | por confirmar en S0b |

## Hecho

- `project.godot`: Godot 4.7.2, renderer Compatibility, viewport 1280x720 con stretch `canvas_items`,
  pantalla completa, fondo oscuro (`default_clear_color`), directorio de usuario propio (`arcumai`):
  las piezas van a `~/.local/share/arcumai/piezas` en Linux y a `%APPDATA%\arcumai\piezas` en Windows.
- `export_presets.cfg`: preset `Linux` (x86_64, pck embebido), salida `build/arcumai.x86_64`.
  Export verificado: ELF x86_64 de 70 MB. Falta probarlo en el arcade (S0b).
- `scenes/main.tscn`: un único nodo raíz con `scripts/main.gd`.
- `scripts/main.gd`: registra el InputMap en `_enter_tree`, crea `State`, `Sequencer`, `VoicePool`, `GlobalFx`,
  `Controller`, `Saver` y `View`, conecta `step_entered` y los pedidos de guardar, salir y reiniciar; al reiniciar
  por inactividad vuelve a aplicar los parámetros a los cuatro buses. Oculta el mouse; Esc cierra solo en builds
  de debug.
- `scripts/config.gd`: acciones y mapeos, grilla (16x10, 4 capas), tiempos del cursor, colores por capa, períodos por
  capa con `TEMPO_SCALE` global, escala pentatónica menor de 10 grados, dos samples por capa (grave/agudo) con su
  nota raíz, corte de zona, volumen, rangos de timbre/envolvente (S4) y parámetros de sesión (S5: carpeta, tope de
  grabación, tiempos de los combos, inactividad, palabras del nombre, cartel).
- `scripts/state.gd`: `State` y `State.Layer` (notas como conjunto de celdas `Vector2i`), parámetros de timbre y
  envolvente por capa, cursor, `active_plane`, `toggle_note`, nombre de la última pieza guardada con su vencimiento,
  `reset_piece()` y `Layer.reset()`, y los parámetros de los efectos globales (modo, tiempo, feedback, wet, profundidad).
- `scripts/controller.gd`: cursor con repetición propia (250 ms inicial, 80 ms después), `btn1` alterna nota,
  `btn2` pasa a la capa siguiente (circular) y emite `layer_changed`; con `btn3`/`btn4` apretados el joystick mueve
  cutoff/reverb o ataque/decay de la capa activa y emite `parameters_changed`, sin mover el cursor. Detecta los
  combos de guardado y salida (`save_requested`, `quit_requested`) y el tiempo sin input (`inactivity_reset`).
  En la vista de todas las capas maneja el modo de los efectos globales en `State.fx_mode`.
- `scripts/sequencer.gd`: fase por capa calculada desde el origen con su período y `TEMPO_SCALE`;
  `step_entered(layer, step)` al cambiar de paso.
- `scripts/voice_pool.gd`: un pool por capa y zona (4 x 2 x 8 voces = 64 reproductores), un bus por capa
  (`layer_1` … `layer_4`) con `AudioEffectLowPassFilter` + `AudioEffectReverb`, envolvente de volumen con `Tween`
  por voz (corta el tween anterior si la voz se reusa), `pitch_scale` = 2^(semitonos/12) contra la raíz del sample
  de la zona, suenan las notas de todas las capas y la nota fantasma solo en la capa activa, vista previa al cambiar
  de capa o de parámetro, zona muda con `push_error` si falta el sample.
- `scripts/saver.gd`: `AudioEffectRecord` en el bus Master, grabación desde el arranque con tope de 8 min, WAV y
  JSON en la carpeta de piezas al guardar (y grabación nueva después de guardar), nombre de dos palabras y dos
  dígitos sin pisar una pieza existente, `restart_recording()` para el reinicio por inactividad.
- `scripts/global_fx.gd`: crea el bus común `fx`, manda ahí los cuatro buses de capa, y aplica cada frame el delay
  (`AudioEffectDelay`, wet fijo 0.4, feedback y tiempo desde el `State`) y el tremolo (`AudioEffectAmplify` con una
  LFO de amplitud a 4 Hz), con entrada rápida y desvanecido lento.
- `scripts/view.gd`: grilla, notas de la capa activa (o de las 4 en la vista de todas, con las celdas compartidas
  partidas en franjas por capa), una línea de barrido por capa (la activa más gruesa y encima), cursor con contorno
  parpadeante (600 ms) que desaparece en la vista de todas, cuadrado con punto (abajo a la derecha) mientras
  B3 o B4 están apretados (o mientras suena un efecto global, con su color) y el cartel "guardado: nombre" arriba
  al centro por 4 s.
- `tools/make_placeholder_wav.gd` y `assets/samples/layer_N_low.wav` / `layer_N_high.wav` (N = 1…4):
  senos con decay, 2 s, mono, 44.1 kHz, raíz MIDI 57 el grave y 69 el agudo, con armónicos distintos por capa
  para distinguirlas de oído.
- Verificado por mí: `--headless --quit` sin errores de script; 4 capas con sus 8 samples cargados; alturas por zona
  (fila 9 = 1.000 y fila 0 = 1.782 en las cuatro capas); una nota en el paso 3 suena en las 4 capas; la nota fantasma
  solo suena en la capa activa; `btn2` recorre 1→2→3→4→vista de todas→1 conservando las notas y hace sonar la vista
  previa en cada capa; en la vista de todas, B1 y el joystick no tocan el estado y el fantasma no suena;
  celdas compartidas con 1, 2, 3 y 4 capas partidas en la cantidad correcta de franjas con el color de cada capa
  (muestreado del PNG); avance de fase medido en 2 s dentro de 0.01 pasos de lo esperado; capturas de la vista de
  todas y de la capa 1.
- Verificado en S4: 5 buses (Master + 4 capas), cada bus de capa con LowPass + Reverb y las voces asignadas a su bus;
  B3 paso el cutoff 12000 → 10435 (una pulsación) y lo llevó a los topes 200/12000, la reverb a 0/1, siempre con el
  bus reflejando el valor; B4 llevó ataque a 0.005/1 s y decay a 0.1/4 s; el plano se activa con B3/B4 y vuelve a
  ninguno al soltar; envolvente medida con ataque 0.2 s y decay 0.4 s: -60 dB al disparar, -22.8 dB a 0.155 s,
  -60 dB a 0.70 s; captura del indicador con el punto en la posición esperada.
- Verificado en S5: un combo de 0.9 s no guarda nada; el combo de 2 s escribe `WAV` (48 kHz estéreo 16 bits, se abre
  con `AudioStreamWAV.load_from_file`) y `JSON` (versión 1, 4 capas, las notas asentadas con sus parámetros, fecha);
  el cartel "guardado: nombre" aparece en el PNG; el reinicio por inactividad vacía las notas, vuelve a la capa 1,
  borra el nombre y devuelve el cutoff del bus a 12000 Hz; al simular el tope de 8 min la grabación se corta
  (`push_error`) y el guardado siguiente escribe JSON sin WAV y vuelve a grabar; el combo de los 4 botones a los 5 s
  cierra la aplicación.
- Verificado en S5b: 6 buses (Master, 4 capas y `fx`); las 4 capas envían a `fx` y `fx` a Master, con pico medido en
  Master de -8.3 dB (el audio llega); el bus `fx` tiene `AudioEffectDelay` + `AudioEffectAmplify`; con arriba
  mantenido el feedback llegó a 0.75 (tap -8 dB, feedback -2.5 dB), el wet a 0.4 y el dry a 0.6; izquierda llevó el
  tiempo de 300 a 525 ms y derecha lo devolvió a 300 ms; al soltar el wet llegó a 0, el dry a 1.0 y el tap a -80 dB;
  con abajo el tremolo moduló el amplificador entre -12 y 0 dB; 1.7 s después de soltar, wet y profundidad en 0;
  fuera de la vista el joystick mueve el cursor y el modo de efectos queda en ninguno; captura del indicador del delay
  con el punto arriba (feedback máximo) y a la derecha del centro (tiempo 300 ms).

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
- S3: en la vista de todas, una celda con varias capas se parte en franjas horizontales iguales, una por capa en
  orden de capa (decisión de Maxi). Una celda con una sola capa queda entera.
- S4: un bus por capa (`layer_1` … `layer_4`) creado por código, con cutoff y reverb propios. Las voces de una capa
  se asignan al bus por nombre, nunca por índice.
- S4: el cutoff se mueve en saltos proporcionales (×1.15) porque el oído lo escucha en proporción; la posición en el
  indicador también es logarítmica. Ataque y decay se mueven en pasos fijos, que es como se perciben.
- S4: mientras B3 o B4 están apretados, el joystick mueve parámetros y no el cursor, y B1/B2 quedan ignorados
  (hay que soltar el botón para cambiar de capa). El plano se guarda en `State.active_plane` para que la vista lo dibuje.
- S4: cada cambio de parámetro hace sonar la fila del cursor (`parameters_changed` → bus + vista previa), porque
  la nota fantasma sola puede tardar hasta 13 s en sonar y el cambio tiene que escucharse en el acto.
- S4: la envolvente es un `Tween` de `volume_db` por voz: sube desde -60 dB hasta -6 dB en el ataque y baja a -60 dB
  en el decay. Si la voz se reusa, se mata el tween anterior para que no pise la nota nueva.
- S5: el directorio de usuario es propio (`arcumai`), así las piezas no se mezclan con otros juegos. `user://piezas`
  queda en `~/.local/share/arcumai/piezas` en Linux.
- S5: la grabación arranca al abrir la aplicación y se reinicia después de cada guardado y de cada reinicio por
  inactividad. Así el WAV contiene la pieza desde que se encendió, y la RAM no crece más allá del tope de 8 min.
- S5: al guardar se corta la grabación y se crea un `AudioEffectRecord` nuevo, en vez de reusar el anterior: el
  efecto nuevo trae su propio buffer y no hay carrera con el que se está liberando.
- S5: el combo de los 4 botones manda sobre el de guardado, para que la salida no escriba una pieza de paso.
  Guardar necesita 2 s; salir, 5 s.
- S5: el nombre de la pieza son dos palabras y dos dígitos. Antes de escribir se buscan hasta 20 nombres libres,
  para no pisar una pieza anterior (las combinaciones son 20 x 19 x 90).
- S5: la inactividad se mide con cualquier `InputEvent` y con cualquier acción apretada. Cualquier movimiento del
  joystick cuenta como actividad.
- S5: el arranque automático quedó fuera de S5 por decisión de Maxi: la mini PC ya abre un menú de juegos.
- S5b: las cuatro capas pasan por un bus común `fx` antes de Master. El delay y el tremolo viven ahí, así afectan
  a todo por igual y el `AudioEffectRecord` de Master los graba. El envío `fx` → Master se fija explícito porque un
  bus nuevo no lo trae.
- S5b: el delay se apaga bajando el wet a 0 y **subiendo el dry a 1.0** al mismo tiempo. Si solo bajara el wet, el
  instrumento quedaría 4 dB más bajo al desaparecer el efecto.
- S5b: cada efecto entra en 0.2 s y se va en 1.5 s. El feedback, el tiempo y la profundidad quedan guardados entre
  usos; solo el "wet" y la profundidad que suenan se desvanecen.
- S5b: el tiempo del delay se mueve en proporción (×1.15), como el cutoff; izquierda alarga y derecha acorta
  (decisión de Maxi). Izquierda/derecha solo responden con arriba apretado.
- S5b: el tremolo es una LFO de amplitud hecha con un `AudioEffectAmplify` en el bus `fx`, con fase desde
  `Time.get_ticks_usec()` (no se acumula `delta`). La velocidad es fija en 4 Hz; solo cambia la profundidad.
- S5b: el efecto global no se guarda en el JSON (la pieza son las notas y los parámetros por capa); el WAV sí lo
  contiene tal como se tocó.

## Propuestas de diseño

Cambios que implican tocar `docs/DISENO.md`. El agente los anota acá; Maxi decide.
Formato: qué se propone, por qué, y qué evidencia lo sostiene (por ejemplo, la prueba con una persona de S2).

- **Actualizar `DISENO.md` con S5b**: hoy dice que en la vista de todas las capas "el joystick no hace nada" y que
  "es solo para mirar". Con S5b el joystick maneja el delay (arriba, con izquierda/derecha para el tiempo) y el
  tremolo (abajo), y los dos se desvanecen al soltar. Propongo corregir ese párrafo y agregar los efectos globales
  al bus `fx` en la sección Sonido. Código ya implementado y verificado.
- **Actualizar la lista de scripts de `AGENTS.md`** con `scripts/global_fx.gd`.

## Pendientes

- S0b en el arcade: correr `build/arcumai.x86_64`, probar joystick, 4 botones y sonido por el parlante.
- Confirmar en el arcade si el encoder aparece como gamepad o como teclado.
- Probar en el arcade la sensación del cursor: 250 ms de retardo y 80 ms por paso pueden quedar lentos o rápidos.
- Dejar la app 10 minutos corrida en el arcade (acá se midieron 90 s) y escuchar si aparece algún corte.
- Escuchar con las 4 capas si se distinguen de oído y si el conjunto no se ensucia. Los placeholders son senos;
  con los samples reales cambia.
- **S4 por Maxi**: con B3, probar el recorrido de cutoff y reverb en las 4 capas (la capa 1 es un seno puro: el filtro
  casi no le cambia el timbre, solo el volumen) y con B4, el ataque largo y el decay corto. Definir si los rangos
  (cutoff 200–12000 Hz, ataque 0.005–1 s, decay 0.1–4 s) y la velocidad de los pasos quedan cómodos.
- Revisar si el disparo de la nota del cursor en cada paso del joystick es cómodo o cansa; se puede limitar a un
  disparo al empezar a mover o dejar solo la nota fantasma.
- Con los samples reales, escuchar la unión de las dos zonas: en la fila 5 (grave, 10 semitonos arriba) y en la
  fila 4 (agudo, sin transponer) el timbre tiene que emparejar. Si no, mover `ZONE_SPLIT_ROW` o ajustar raíces.
- Medir FPS en el arcade (S0b) con las 4 capas y 64 voces. Optimizar la vista solo si hay problema.
- **S5 por Maxi**: armar una pieza, guardar con K + L mantenidas 2 s y escuchar el WAV desde la carpeta de piezas;
  verificar que el cartel muestra el nombre 4 s. Dejar la aplicación 5 min sin tocar y ver que se vacía sola.
  Probar el combo de los 4 botones 5 s y confirmar que no se dispara por accidente en uso normal.
- Decidir si el combo de guardado (B3 + B4, 2 s) es cómodo, teniendo en cuenta que esos botones también mueven
  timbre y envolvente mientras se los mantiene apretados.
- Decidir si el reinicio por inactividad tiene que avisar algo en pantalla: hoy la grilla se vacía sin cartel.
- **S5b por Maxi**: en la vista de todas las capas, empujar el stick arriba (delay) y escuchar cómo el feedback crece
  al mantener; con arriba + izquierda/derecha, escuchar el cambio de tiempo (con feedback alto aparece el warble
  típico de cinta). Empujar abajo (tremolo) y escuchar la profundidad creciendo. Soltar y confirmar el desvanecido.
  Definir si 4 Hz, el rango de tiempo (80–800 ms), el feedback máximo (0.75) y los tiempos de fade (0.2/1.5 s) quedan
  cómodos.
- Escuchar si el tremolo, modulado desde `_process` a 60 fps, suena escalonado a 4 Hz y con profundidad máxima.
  Si molesta: bajar la velocidad, bajar la profundidad máxima o usar `AudioEffectChorus`.
- Revisar el volumen general con el delay al 40 % de wet: el dry baja a 0.6 mientras el efecto está encendido.
- Medir el pico de RAM al guardar una grabación de 8 minutos (~92 MB de audio en RAM, 48 kHz estéreo 16 bits,
  y al codificar el WAV se duplica un momento).
- Si una pieza se toca más de 8 min seguidos, la grabación ya se cortó: al guardar queda solo el JSON. Decidir si
  conviene un tope más alto, avisar en pantalla o rotar la grabación.
- Autostart en el arcade: la mini PC ya abre un menú de juegos; falta definir (con Maxi) si se agrega el juego a ese
  menú y si hace falta reiniciarlo si se cuelga. Quedó fuera de S5.

## Bugs conocidos

- Al abrir el editor, Godot puede escribir `default_bus_layout.tres` (con el volumen del Master tocado). No va en el
  repo: borrarlo. Los buses se crean por código y ese archivo los contradice.

(El aviso de fuga de audio al cerrar es un artefacto de Godot, ver `AGENTS.md`.)

## Resultado de la prueba con persona (S2)

Aprobada. Lo probó una persona unos minutos: "suena bien y la lógica es entretenida". No hizo falta explicarle nada.
S3 desbloqueado.
