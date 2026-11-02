# Estado del proyecto

Este archivo es la memoria entre sesiones. Cada sesión lo lee al empezar y lo actualiza al terminar.
Mantenerlo corto: reemplazar lo viejo, no acumular.

## Dónde estamos

- S0 a S5 completos en la máquina de desarrollo, con samples placeholder (dos por capa, cuatro capas).
- Suenan las 4 capas a la vez, cada una con su período, su color, su filtro y su reverb; `btn2` cambia la capa activa
  y, después de la cuarta, muestra la vista general con las cuatro juntas. `btn3` mueve timbre y `btn4` envolvente.
- S5: la sesión se graba desde el arranque (tope de 8 min); B3 + B4 mantenidos 2 s guardan JSON + WAV en
  `user://piezas` y muestran el nombre 4 s; los 4 botones 5 s cierran la aplicación; a los 5 min sin input la pieza
  se vacía y la grabación se reinicia.
- S-FX fase 1: en la vista general (la quinta posición de B2) el joystick no mueve el cursor y maneja dos efectos
  globales. Arriba enciende el delay y sube su wet; arriba + izquierda/derecha mueven su speed (tiempo). Abajo hace
  lo mismo con el trémolo (profundidad y velocidad). Al soltar, wet y speed vuelven al reposo en 3 s. Dos paneles
  abajo a la derecha muestran wet y speed. B1 no hace nada ahí, B3/B4 solos tampoco, y el secuenciador sigue.
- S-FX fase 2: B2 + B3 graban el gesto del joystick (entre 1 y 5 s); al soltar se repite en bucle en todas las
  vistas, con una segunda instancia de la lógica de efectos. Por efecto, el joystick real manda si mantiene su
  dirección vertical; si no, el vivo sigue el valor grabado. B2 + B4 (2 s) borran el gesto (con barra de progreso) y
  "REC" muestra el tiempo restante. B2 cambia de vista al soltarlo y solo si no se usó en un combo. El gesto va al JSON.
- Bloqueado antes de S6: S0b en el arcade, la entrega de los samples reales y la prueba de S-FX por parte de Maxi.
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
- `scripts/main.gd`: registra el InputMap en `_enter_tree`, crea `State`, dos `FxDrive` (el vivo con
  `state.live_fx` y el del gesto con `state.gesture_fx`), `GestureDrive`, `Sequencer`, `VoicePool`, `GlobalFx`,
  `Controller`, `Saver` y `View`, conecta `step_entered` y los pedidos de guardar, salir y reiniciar; al reiniciar
  por inactividad vuelve a aplicar los parámetros a los cuatro buses. Oculta el mouse; Esc cierra solo en debug.
- `scripts/config.gd`: acciones y mapeos, grilla (16x10, 4 capas), tiempos del cursor, colores por capa, períodos por
  capa con `TEMPO_SCALE` global, escala pentatónica menor de 10 grados, dos samples por capa (grave/agudo) con su
  nota raíz, corte de zona, volumen, rangos de timbre/envolvente (S4), parámetros de sesión (S5: carpeta, tope de
  grabación, tiempos de los combos, inactividad, palabras del nombre, cartel), efectos globales de S-FX (bus `fx`,
  tiempos de rampa, salto inicial, tiempos y feedback del delay, velocidades del trémolo, paneles de la vista) y
  gesto grabado de S-FX fase 2 (máscaras de dirección, `GESTURE_MAX_SECONDS`, `GESTURE_MIN_SECONDS`,
  `GESTURE_CLEAR_MSEC`, indicadores REC y barra). El JSON pasó a versión 2 (`SAVE_FORMAT_VERSION`).
- `scripts/state.gd`: `State` y `State.Layer` (notas como conjunto de celdas `Vector2i`), parámetros de timbre y
  envolvente por capa, cursor, `active_plane`, `toggle_note`, nombre de la última pieza guardada con su vencimiento,
  `reset_piece()` y `Layer.reset()`, los efectos globales de S-FX (`FxUnit`, `FxSet`, `live_fx`, `gesture_fx`), el
  gesto (`Gesture` con duración y eventos `[tiempo, máscara]`) y los indicadores REC/progreso. Todo se limpia con
  `reset_piece()`.
- `scripts/controller.gd`: cursor con repetición propia (250 ms inicial, 80 ms después), `btn1` alterna nota,
  `btn2` cambia de vista **al soltarlo** y solo si no se usó en un combo, y emite `layer_changed`; con `btn3`/`btn4`
  apretados el joystick mueve cutoff/reverb o ataque/decay de la capa activa y emite `parameters_changed`, sin mover
  el cursor. Combos: los 4 botones (salir), B2+B3 (grabar gesto), B2+B4 (borrar gesto) y B3+B4 (guardar), en ese
  orden de prioridad. Detecta el tiempo sin input (`inactivity_reset`). Alimenta los efectos en vivo solo en la vista
  general y el gesto con el joystick crudo en cualquier vista.
- `scripts/fx_drive.gd`: lógica de los efectos, sin nodos ni audio. Convierte `(arriba, abajo, izquierda, derecha,
  delta)` en wet y speed de un `State.FxSet`: salto inicial de 0.15, wet 0→1 en 3 s, speed centro→extremo en 2 s,
  retorno en 3 s, y el speed se queda quieto si no hay horizontal. Si tiene `fallback` (la instancia viva lo apunta
  a `gesture_fx`), el efecto no mantenido vuelve hacia el valor grabado en vez de 0.
- `scripts/gesture_drive.gd`: graba los cambios de dirección del joystick con su tiempo y los reproduce en bucle
  sobre una segunda instancia de `FxDrive`. Corta sola en `GESTURE_MAX_SECONDS`, cancela si no llegó al mínimo,
  reemplaza el gesto al regrabar y lo borra a pedido. Sin nodos ni audio.
- `scripts/sequencer.gd`: fase por capa calculada desde el origen con su período y `TEMPO_SCALE`;
  `step_entered(layer, step)` al cambiar de paso.
- `scripts/voice_pool.gd`: un pool por capa y zona (4 x 2 x 8 voces = 64 reproductores), un bus por capa
  (`layer_1` … `layer_4`) con `AudioEffectLowPassFilter` + `AudioEffectReverb`, envolvente de volumen con `Tween`
  por voz (corta el tween anterior si la voz se reusa), `pitch_scale` = 2^(semitonos/12) contra la raíz del sample
  de la zona, suenan las notas de todas las capas y la nota fantasma solo en la capa activa, vista previa al cambiar
  de capa o de parámetro, zona muda con `push_error` si falta el sample.
- `scripts/saver.gd`: `AudioEffectRecord` en el bus Master, grabación desde el arranque con tope de 8 min, WAV y
  JSON en la carpeta de piezas al guardar (y grabación nueva después de guardar), nombre de dos palabras y dos
  dígitos sin pisar una pieza existente, `restart_recording()` para el reinicio por inactividad. El JSON incluye el
  gesto (`duration` y `events`; `{}` si no hay).
- `scripts/global_fx.gd`: crea el bus común `fx`, manda ahí los cuatro buses de capa y fija `fx` → Master. Cada
  frame lleva `state.live_fx` al audio: el delay (`AudioEffectDelay`, tiempo geométrico 900/400/120 ms según speed,
  feedback fijo 0.4, dry = 1 − wet) y el trémolo (`AudioEffectAmplify` con LFO de amplitud, velocidad geométrica
  0.5/3/12 Hz, profundidad = wet). La fase del LFO se acumula con `delta` para que no salte al cambiar la velocidad.
- `scripts/view.gd`: grilla, notas de la capa activa (o de las 4 en la vista general, con las celdas compartidas
  partidas en franjas por capa), una línea de barrido por capa (la activa más gruesa y encima), cursor con contorno
  parpadeante (600 ms) que desaparece en la vista general, cuadrado con punto (abajo a la derecha) mientras
  B3 o B4 están apretados, dos paneles de efectos en la vista general (delay arriba, trémolo abajo, con barra de wet
  y marcador de speed), "REC" con el tiempo restante arriba al centro, barra de progreso del borrado abajo al centro
  y el cartel "guardado: nombre" arriba al centro por 4 s.
- `tools/make_placeholder_wav.gd` y `assets/samples/layer_N_low.wav` / `layer_N_high.wav` (N = 1…4):
  senos con decay, 2 s, mono, 44.1 kHz, raíz MIDI 57 el grave y 69 el agudo, con armónicos distintos por capa
  para distinguirlas de oído.
- Verificado por mí: `--headless --quit` sin errores de script; 4 capas con sus 8 samples cargados; alturas por zona
  (fila 9 = 1.000 y fila 0 = 1.782 en las cuatro capas); una nota en el paso 3 suena en las 4 capas; la nota fantasma
  solo suena en la capa activa; `btn2` recorre 1→2→3→4→vista de todas→1 conservando las notas y hace sonar la vista
  previa en cada capa; en la vista general B1 no toca las notas, el joystick no mueve el cursor y el fantasma no suena;
  celdas compartidas con 1, 2, 3 y 4 capas partidas en la cantidad correcta de franjas con el color de cada capa
  (muestreado del PNG); avance de fase medido en 2 s dentro de 0.01 pasos de lo esperado; capturas de la vista de
  todas y de la capa 1.
- Verificado en S4: 5 buses (Master + 4 capas), cada bus de capa con LowPass + Reverb y las voces asignadas a su bus;
  B3 paso el cutoff 12000 → 10435 (una pulsación) y lo llevó a los topes 200/12000, la reverb a 0/1, siempre con el
  bus reflejando el valor; B4 llevó ataque a 0.005/1 s y decay a 0.1/4 s; el plano se activa con B3/B4 y vuelve a
  ninguno al soltar; envolvente medida con ataque 0.2 s y decay 0.4 s: -60 dB al disparar, -22.8 dB a 0.155 s,
  -60 dB a 0.70 s; captura del indicador con el punto en la posición esperada.
- Verificado en S5: un combo de 0.9 s no guarda nada; el combo de 2 s escribe `WAV` (48 kHz estéreo 16 bits, se abre
  con `AudioStreamWAV.load_from_file`) y `JSON` (versión 1 en ese momento; hoy versión 2, con el gesto, 4 capas,
  las notas asentadas con sus parámetros, fecha);
  el cartel "guardado: nombre" aparece en el PNG; el reinicio por inactividad vacía las notas, vuelve a la capa 1,
  borra el nombre y devuelve el cutoff del bus a 12000 Hz; al simular el tope de 8 min la grabación se corta
  (`push_error`) y el guardado siguiente escribe JSON sin WAV y vuelve a grabar; el combo de los 4 botones a los 5 s
  cierra la aplicación.
- Verificado en S-FX fase 1: 6 buses (Master, 4 capas y `fx`); las 4 capas envían a `fx` y `fx` a Master, con pico
  medido en Master de -8.3 dB; el bus `fx` tiene `AudioEffectDelay` + `AudioEffectAmplify`. Rampas medidas con
  delta fijo: salto inicial del wet 0.156, wet en 1.0 a los 3 s, speed en 1.0 a los 2 s, el speed se mantiene al
  soltar la horizontal y wet/speed vuelven a 0 a los 3 s; solo horizontal 4 s deja wet y speed en 0. Mapeo del delay
  exacto en 900/400/120 ms para speed -1/0/+1 y del trémolo en 0.50/3.00/12.00 Hz. En vivo: arriba 1.3 s → wet 0.584,
  dry 0.421, tap -4.8 dB, feedback -8.0 dB; arriba + derecha 0.7 s → speed 0.409, 244 ms; 0.7 s después de soltar la
  horizontal el speed seguía en 0.409; 3.2 s después de soltar todo, wet y speed en 0. Abajo 1.5 s → wet 0.65 y el
  amplificador modulando entre -7.9 y 0 dB a 3.00 Hz medidos; 3.2 s después, wet 0. B1 en la vista general no cambió
  las 4 notas; el cursor quedó en paso 0 fila 0; B2 salió a la capa 1; el secuenciador siguió avanzando
  (fase 3.064 → 4.234 en 0.5 s); captura de los dos paneles con la barra de wet del delay y el marcador centrado.
- Verificado en S-FX fase 2: dos instancias de `FxDrive`; el vivo no mantenido sigue al grabado (wet 0.800 y speed
  0.600), el vivo mantenido manda sobre el grabado, y sin gesto vuelve a 0 en 3 s. Grabación de 3.00 s con eventos
  `[[0.0, 1], [1.1, 5]]`; el bucle devuelve la máscara correcta en 0.2, 1.5 y 3.2 s; una grabación de 0.5 s se
  cancela y conserva la anterior; al llegar a 5.00 s corta sola y deja el restante en 0. B2 solo cambia de capa al
  soltarlo; B2+B3 graba 1.31 s y no cambia de vista; B2+B4 borra a los 2 s (progreso 0.50 a 1 s); el ciclo de B2
  sigue en 2, 3, 4, todas, 1; B3+B4 sigue guardando. De punta a punta con la escena real: 6 buses (fx en el índice 5),
  capa 1 → fx → Master; arriba 1.5 s → wet 0.651, tap 400 ms, dry 0.351; 3.2 s después, wet 0. Gesto de 1.6 s con
  arriba + derecha (máscara 9): en bucle y sin joystick, wet vivo 0.495 = wet grabado 0.495, speed 0.517, tap 218 ms;
  B2+B4 lo borra y 3.2 s después wet 0 y tap 400 ms. Captura de la vista general con "REC 3.4", la barra de borrado
  al 60 % y los dos paneles.

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
- S3: después de la capa 4, `btn2` muestra la vista general (decisión de Maxi). Corta el cursor, el fantasma y B1,
  y el joystick no mueve el cursor: desde S-FX maneja los efectos globales. Solo B2 sale de esa vista, y
  `get_active_layer()` tiene un assert para que nadie edite ahí.
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
- S-FX: las cuatro capas pasan por un bus común `fx` antes de Master. El delay y el trémolo viven ahí, así afectan
  a todo por igual y el `AudioEffectRecord` de Master los graba. El envío `fx` → Master se fija explícito porque un
  bus nuevo no lo trae (bug encontrado en S5b).
- S-FX: la lógica de wet/speed vive en `scripts/fx_drive.gd` (`class_name FxDrive`), separada del audio. Es un script
  nuevo justificado: la fase 2 usa dos instancias de la misma lógica (joystick vivo y gesto grabado).
  `global_fx.gd` quedó solo como lado de audio y lee `state.live_fx`.
- S-FX: el delay se apaga bajando el wet a 0 y subiendo el dry a 1 − wet al mismo tiempo, así el instrumento no queda
  más bajo al desaparecer el efecto.
- S-FX: el tiempo del delay y la velocidad del trémolo se interpolan en forma geométrica entre los tres puntos
  (−1 / 0 / +1), porque el oído los escucha en proporción. El feedback del delay es fijo en 0.4.
- S-FX: el trémolo no existe como efecto en Godot: es una LFO de amplitud sobre un `AudioEffectAmplify` en el bus
  `fx`, calculada en `_process` a la frecuencia de frames. La fase se acumula con `delta` (no se recalcula desde el
  reloj) para que no salte al cambiar la velocidad; el costo es que a 12 Hz y 60 fps hay ~5 muestras por ciclo.
- S-FX: en la vista general el controller alimenta `FxDrive` con las cuatro direcciones; en cualquier otra vista lo
  alimenta con todo suelto. Con gesto grabado, ese "suelto" apunta a los valores grabados en vez de a 0.
- S-FX: el efecto en vivo no se guarda en el JSON (la pieza son las notas y los parámetros por capa); el WAV sí lo
  contiene tal como se tocó. La fase 2 agrega el gesto grabado al JSON (duración y eventos).
- S-FX fase 2: una sola clase `FxDrive` con dos instancias (joystick real y gesto grabado), como pedía el diseño.
  Cada una tiene su `FxSet` en el `State` (`live_fx` y `gesture_fx`).
- S-FX fase 2: la combinación se hace con un `fallback` en la instancia viva. Cuando el efecto no está mantenido,
  su wet y su speed vuelven **hacia el valor grabado** con la misma rampa de 3 s (no saltan de golpe). Así se cumple
  "mientras no esté activo en vivo, su retorno al reposo apunta al valor grabado" y se evitan clicks al cambiar
  de fuente; si no hay gesto, el destino es 0 y se comporta igual que la fase 1.
- S-FX fase 2: el gesto se guarda como una lista de eventos `[tiempo, máscara]` (1 arriba, 2 abajo, 4 izquierda,
  8 derecha) más la duración. Es compacto, se serializa tal cual al JSON y no necesita nodos.
- S-FX fase 2: la grabación se permite en cualquier vista, con el joystick crudo; el combo bloquea el cursor mientras
  dura. Los efectos en vivo siguen existiendo solo en la vista general, pero el gesto suena en todas.
- S-FX fase 2: B2 cambia de vista al soltarlo. `_b2_used_in_combo` se activa en cualquier combo que incluya B2, así
  grabar o borrar nunca cambia de vista. El ciclo de capas y la vista general no cambiaron.
- S-FX fase 2: prioridad de combos: los 4 botones (salir) > B2+B3 (grabar) > B2+B4 (borrar) > B3+B4 (guardar).
  Si alguien aprieta B3 y B4 mientras graba, gana la grabación y el guardado no se dispara.
- S-FX fase 2: el JSON pasó a versión 2. La barra de progreso del borrado va abajo al centro y el "REC" con el
  tiempo restante arriba al centro; no se agregó texto en ningún otro lado.

## Propuestas de diseño

Cambios que implican tocar `docs/DISENO.md`. El agente los anota acá; Maxi decide.
Formato: qué se propone, por qué, y qué evidencia lo sostiene (por ejemplo, la prueba con una persona de S2).

- **Actualizar la lista de scripts de `AGENTS.md`** con `scripts/global_fx.gd`, `scripts/fx_drive.gd` y
  `scripts/gesture_drive.gd`.

## Contradicciones detectadas (S-FX)

No se resolvieron en silencio; quedan para que decida Maxi:

- `DISENO.md`, tabla de Botones: "Joystick (solo): mueve el cursor". En la vista general no lo mueve: maneja los
  efectos. La sección de la vista general ya lo aclara, pero la tabla sigue diciendo lo contrario.
- `DISENO.md`, tabla de Botones: B2 es "toque". El código de la fase 2 cambia de vista **al soltarlo**, y solo si
  no se usó en un combo. La tabla sigue diciendo "toque" sin aclararlo.
- `DISENO.md`, Visual: "Nada de texto salvo el nombre de la pieza al guardar y los indicadores de B3/B4 mientras están
  apretados". La fase 2 agrega "REC" con el tiempo restante y la barra de progreso del borrado.
- `DISENO.md`, Efectos globales: la regla general dice que al soltar, wet y speed vuelven al reposo. Con el gesto
  grabado vuelven al valor grabado. La propia sección lo aclara en la fase 2, pero la regla de arriba no lo distingue.
- `DISENO.md`, Efectos globales: no dice en qué vista se puede grabar el gesto. Se implementó en cualquier vista,
  con el joystick crudo; el combo bloquea el cursor mientras dura la grabación.
- `DISENO.md`, Grabación: dice "estéreo 44.1 kHz" y "unos 85 MB". El código graba a la frecuencia del mixer
  (48 kHz) y la medición de S5 dio ~92 MB para 8 minutos.
- `AGENTS.md`: la lista de scripts no incluye `global_fx.gd`, `fx_drive.gd` ni `gesture_drive.gd`.
- `AGENTS.md`: dice que la vista de todas las capas es para mirar y que el joystick no hace nada; el diseño de S-FX
  la convierte en la vista de efectos en vivo.

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
- **S-FX fase 1 por Maxi**: llegar a la vista general (J ×4) y empujar el stick **arriba**: el delay entra con un
  salto chico y el wet sube mientras se mantiene; **arriba + izquierda/derecha** mueve el tiempo (900 ↔ 120 ms).
  Empujar **abajo**: trémolo, con la profundidad subiendo; **abajo + izquierda/derecha** mueve la velocidad
  (0.5 ↔ 12 Hz). Soltar y confirmar que todo vuelve al reposo en 3 s, y que al soltar solo la horizontal el speed se
  queda donde estaba. Confirmar que **izquierda o derecha solas no hacen nada** y que B1/B3/B4 no hacen nada ahí.
- **S-FX fase 2 por Maxi**: en cualquier vista, mantener **J + K** (B2 + B3) y mover el stick (por ejemplo arriba y
  después arriba + derecha) entre 1 y 5 s; soltar. El gesto tiene que repetirse en bucle en todas las vistas y
  seguir sonando al cambiar de capa. Probar **regrabar** (J + K otra vez) y **borrar** (J + L 2 s, con la barra de
  progreso). Confirmar que un toque corto de J (sin combo) sigue cambiando de capa, que J ×4 llega a la vista general
  y que soltar J después de un combo no cambia de vista.
- `controller.gd` pasó de ~270 a ~342 líneas. Si sigue creciendo, separar en un script propio la lógica de combos y
  gesto (sin cambiar el diseño). No se hizo en S-FX para no refactorizar lo que funciona.
- Escuchar cómo se combina el gesto en bucle con el joystick real: al mantener arriba o abajo debería mandar el vivo
  y, al soltar, volver suavemente al valor grabado. Definir si la rampa de 3 s es cómoda.
- Escuchar si el cambio entre vivo y grabado (o regrabar) produce clicks; la rampa de 3 s debería taparlos.
- Confirmar que "REC 4.9…" y la barra de borrado se leen bien desde la distancia del arcade, y si 5 s de grabación
  y 2 s de borrado son cómodos.
- Escuchar el trémolo a velocidades altas (12 Hz): la LFO se calcula en `_process` a 60 fps y puede sonar escalonada.
  No se va a resolver con complejidad; si molesta, lo más simple es bajar `TREMOLO_RATE_FAST_HZ` o limitar el rango.
- Escuchar si cambiar el tiempo del delay en vivo (sobre todo con wet alto) hace clicks o glissandos. La rampa del
  wet debería taparlos; si no, reportarlo.
- Definir si el feedback fijo en 0.4 y el rango 120–900 ms del delay quedan cómodos, y si el wet llegando a 1.0
  (dry 0) deja el instrumento muy flaco cuando el delay está al máximo.
- Definir si el rango del trémolo (0.5–12 Hz) y que la profundidad llegue a 1.0 (silencio en el mínimo del LFO)
  son cómodos.
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
