# Diseño: Arcumai

Este documento es la fuente de verdad del diseño. Si el código y este documento se contradicen, avisá a Maxi antes de decidir.

## Intención

- Un instrumento que se pueda agarrar de forma lúdica, como cuando uno se sienta a "jugar" en un piano sin saber tocarlo.
  No premia la práctica. Tampoco es un juego con objetivos.
- Sesión típica de 2 a 5 minutos, una sola persona, mayormente estudiantes (multimedia, videojuegos).
- Los controles se descubren experimentando. No hay tutorial. Cada gesto tiene que producir un cambio que se OIGA al instante.
- Referencias de actitud: Brian Eno (*Music for Airports*, bucles de duraciones distintas), Terry Riley (*In C*, desfasaje),
  Björk (*Biophilia*, instrumentos como sistemas), Laurie Anderson.
- La música no sale de "tocar notas" sino de sembrar procesos que se desfasan. Por eso: escala bloqueada, ciclos distintos por capa.

## Modelo musical

- **Grilla**: eje X = tiempo dentro del ciclo, `STEPS` pasos (por defecto 16). Eje Y = altura, `ROWS` filas (por defecto 10).
- **Altura**: las filas son grados de una escala fija (por defecto pentatónica menor, 2 octavas). No existen notas "incorrectas".
  La escala y la nota raíz viven en `config.gd`.
- **Capas**: cada capa es un sonido (un sample). Por defecto 4 capas.
  Cada capa tiene su propio período de ciclo, asignado por el sistema y NO elegido por quien juega.
  Valores iniciales sugeridos (segundos): 7.0, 9.5, 11.3, 13.7. Que no sean múltiplos entre sí.
  Así las capas se desfasan y la pieza no se repite igual.
- **Línea de barrido**: cada capa tiene su línea que recorre la grilla de izquierda a derecha en el período de esa capa
  y vuelve a empezar. Cuando pasa por una nota de su capa, la dispara. Se dibujan todas las líneas sobre el mismo plano,
  del color de su capa, para que se vea el desfasaje.
- **Tiempo**: los pasos están cuantizados a la grilla. Sin cuantización libre en la primera versión.
- **Tempo global**: existe una variable `tempo_scale` (1.0 por defecto) que multiplica la velocidad de todas las líneas.
  No se expone a ningún control en la primera versión. Más adelante lo va a modificar un sensor externo.

## Cursor y nota fantasma

- El cursor ocupa una celda de la grilla (paso, fila) y pertenece a la capa activa.
- El joystick es digital: mueve el cursor **de a un paso**. Mantener la dirección repite el movimiento
  (retardo inicial ~250 ms, luego ~80 ms por paso). Las diagonales mueven ambos ejes.
  En X el cursor da la vuelta (el tiempo es cíclico). En Y se detiene en los bordes.
- **Nota fantasma**: el cursor SUENA cada vez que la línea de barrido de su capa pasa por su columna, aunque no haya
  nota asentada. Así se oye cada movimiento al instante. Es la pieza clave del diseño: reemplaza al tutorial.
- Al iniciar, la pieza está vacía. Sin nada precargado. Lo único que suena es la nota fantasma de la capa 1.

## Botones

Una sola regla: **mantener un botón cambia lo que mueve el joystick**.

| Control | Acción |
|---|---|
| Joystick (solo) | Mueve el cursor en tiempo (X) y altura (Y) |
| B1 (toque) | Alterna: si no hay nota en la celda del cursor, la asienta; si hay, la borra |
| B2 (toque) | Pasa a la capa siguiente (siguiente sonido). El cursor adopta el sonido de esa capa. Después de la última capa muestra la vista de todas las capas juntas; el siguiente toque vuelve a la primera |
| B3 (mantenido) | El joystick mueve el plano tímbrico de la capa activa: X = brillo (filtro pasa-bajos), Y = cantidad de reverb |
| B4 (mantenido) | El joystick mueve el plano de envolvente de la capa activa: X = ataque, Y = decay |

Mientras B3 o B4 están apretados, el cursor no se mueve y la pantalla muestra un cuadrado con un punto
(X = parámetro horizontal, Y = parámetro vertical). Cada paso del joystick hace sonar la nota del cursor con el
parámetro nuevo, para escuchar el cambio sin esperar a que pase la línea de barrido.
Cada capa guarda sus propios parámetros de timbre y envolvente.

## Guardar y salir

- **Grabación**: la captura de audio arranca al iniciar y en cada reinicio por inactividad, y se descarta al reiniciar.
  Tope de 8 minutos por pieza (unos 85 MB en RAM: estéreo 44.1 kHz 16 bits). Al llegar al tope se corta la grabación
  con un `push_error` y la pieza sigue sonando. El tope existe porque sin reinicio ni límite la grabación crecería sin fin.
- **Guardar**: mantener B3 + B4 durante 2 segundos. Escribe un JSON con el estado y un WAV con el audio grabado
  de la pieza. Muestra en pantalla un nombre corto de la pieza (palabra + número, ejemplo: `mar-lento-17`).
- **Salir (administrador)**: mantener los cuatro botones durante 5 segundos. Cierra la aplicación.
  Es la única salida del build del arcade: quien lo administra tiene que conocer el combo. Si la aplicación se cuelga,
  el recurso es el sistema operativo.
- Si la persona se va sin guardar, la pieza se pierde. Es una decisión consciente.
- **Reinicio por inactividad**: tras 300 segundos (5 minutos, constante en `config.gd`) sin ninguna entrada,
  volver a una pieza vacía sin guardar y reiniciar la grabación, para que la próxima persona empiece de cero.
  El umbral es el máximo de la sesión típica (2 a 5 minutos), así nadie pierde trabajo mientras piensa.

## Sonido

- Dos samples `.wav` por capa en `assets/samples/`, con nombres fijos `layer_1_low.wav` / `layer_1_high.wav`
  … `layer_4_low.wav` / `layer_4_high.wav`. Los pone Maxi (grabaciones propias de guitarras, mandolinas,
  golpes de madera, etc.). Preferir sonidos con carácter y envolventes lentas.
- La grilla se parte en dos zonas en la fila `ZONE_SPLIT_ROW` (5): filas 5–9 usan el sample grave y filas 0–4
  el agudo. Cada zona cubre 5 filas y se transpone como máximo 10 semitonos, en vez de 22.
- La nota raíz MIDI de cada sample se declara en `config.gd` (`LAYER_SAMPLE_ROOT_MIDI`).
  Si falta un archivo, `push_error` con su nombre y esa zona queda muda sin cerrar la aplicación.
- La altura se logra con `pitch_scale` = 2^(semitonos/12) relativo a la raíz del sample de la zona.
- Cada capa tiene su propio bus de audio (`layer_1` … `layer_4`) con un `AudioEffectLowPassFilter` y un
  `AudioEffectReverb`. B3 mueve el cutoff (200–12000 Hz, en saltos proporcionales) y el wet de la reverb (0–1).
  Los buses se crean por código al arrancar (ver `AGENTS.md`), no hay `default_bus_layout.tres`.
- La envolvente (ataque/decay) se hace con un `Tween` de volumen por voz, sobre el pool de reproductores.
  B4 mueve ataque (0.005–1 s) y decay (0.1–4 s) de la capa activa.
- Un bus de grabación (`AudioEffectRecord`) captura la salida para guardar el WAV.
- Hasta que Maxi entregue samples, usar un WAV placeholder simple (un seno con decay) generado una vez con
  `tools/make_placeholder_wav.gd`. Es temporal.

## Visual

- Todo con `_draw()`. Fondo oscuro, grilla sobria, cada capa de un color, líneas de barrido finas, notas como cuadrados,
  cursor como contorno parpadeante del color de la capa activa.
- Mientras B3 o B4 están apretados, abajo a la derecha aparece un cuadrado oscuro con un punto del color de la capa
  activa: X = parámetro horizontal, Y = parámetro vertical (arriba = más). Desaparece al soltar el botón.
- **Vista general**: después de la última capa, B2 muestra las notas de las cuatro capas superpuestas,
  cada una en su color. Si varias capas tienen nota en la misma celda, el cuadrado se parte en franjas horizontales,
  una por capa, en orden de capa. No hay cursor, no suena la nota fantasma, B1 no hace nada, B3 y B4 solos no hacen
  nada, y las cuatro líneas de barrido valen lo mismo. El joystick no mueve el cursor: maneja los efectos globales.
  El secuenciador sigue corriendo. El siguiente B2 vuelve a la capa 1.
- **Indicadores de efectos**: en la vista general, abajo a la derecha, dos paneles: delay arriba y trémolo abajo.
  Cada uno tiene una barra de wet (vacía en reposo) y un marcador de speed (centro = 0, izquierda = lento,
  derecha = rápido). Se dibujan con `_draw()`.
- **Indicadores del gesto**: mientras se graba, "REC" con el tiempo restante arriba al centro. Al mantener B2 + B4,
  una barra de progreso del borrado abajo al centro. Se dibujan con `_draw()` y valen en cualquier vista.
- Nada de texto salvo el nombre de la pieza al guardar y los indicadores de B3/B4 mientras están apretados.
- Mouse oculto. Pantalla completa.

### Efectos globales (S-FX)

Afectan a todos los sonidos por igual: el delay y el trémolo van sobre el bus Master, donde ya está mezclada
la salida de las cuatro capas, y la grabación del WAV los captura ya con los efectos. (No hay bus `fx`: en
Godot 4.7 un envío cambiado después de crear los buses no llega al audio; ver `docs/ESTADO.md`.) Cada efecto
tiene dos valores: `wet` (0 a 1, reposo 0) y `speed` (−1 lento, 0 centro, +1 rápido, reposo 0).

| Entrada (mantenida) | Efecto |
|---|---|
| Arriba, solo o en diagonal | Delay activo; su wet sube mientras se mantiene |
| Arriba + izquierda / derecha | Speed del delay hacia −1 (tiempo largo) / +1 (tiempo corto) |
| Abajo, solo o en diagonal | Trémolo activo; su wet (profundidad) sube mientras se mantiene |
| Abajo + izquierda / derecha | Speed del trémolo hacia −1 (lento) / +1 (rápido) |
| Izquierda o derecha solas | No hacen nada |

Reglas: un efecto está activo mientras se mantiene su dirección vertical y los dos son independientes. Al soltarla,
wet y speed vuelven lentamente al reposo. Si se suelta la parte horizontal pero se sigue manteniendo la vertical,
el speed se queda donde está. Al empezar a mantener, el wet da un salto inicial chico (~0.15) para que se oiga
enseguida. Valores en `config.gd`: wet 0 a 1 en 3 s, speed de centro a extremo en 2 s, vuelta al reposo en 3 s.
Delay: −1 = 900 ms, 0 = 400 ms, +1 = 120 ms (interpolación geométrica), feedback fijo ~40 %. Trémolo:
−1 = 0.5 Hz, 0 = 3 Hz, +1 = 12 Hz.

**Fase 1 (implementada):** efectos en vivo con el joystick, tal como describe la tabla.

**Fase 2 (implementada):** grabar el gesto.

- **Grabar**: B2 + B3 mantenidos. Se registran los cambios de dirección del joystick con su tiempo desde que se
  aprietan los dos botones, en cualquier vista. La grabación dura lo que se mantienen los botones, con máximo
  `GESTURE_MAX_SECONDS` (5 s): al llegar al máximo corta sola. Mínimo `GESTURE_MIN_SECONDS` (1 s): si se suelta
  antes, se cancela y no reemplaza el gesto anterior. Mientras se graba, "REC" con el tiempo restante arriba al centro.
- **Reproducir**: al terminar la grabación, el gesto se repite en bucle con su propia duración (la que duró la
  grabación) y suena en todas las vistas. Alimenta una segunda instancia de la misma lógica de efectos
  (`FxDrive`), con su propio `FxSet`.
- **Combinar**: por efecto, si el joystick real mantiene activa su dirección vertical mandan los valores en vivo;
  si no, wet y speed vuelven suavemente (en `FX_REST_SECONDS`) hacia el valor grabado. Sin gesto, el destino es el
  reposo de siempre.
- **Regrabar** reemplaza el gesto anterior. **Borrar**: B2 + B4 mantenidos `GESTURE_CLEAR_MSEC` (2 s), con una barra
  de progreso abajo al centro. B2 cambia de vista al soltarlo, y solo si no se usó en un combo.
- El gesto se guarda en el JSON como `{"duration": ..., "events": [[tiempo, máscara], ...]}` (máscara: 1 arriba,
  2 abajo, 4 izquierda, 8 derecha) y se pierde con el reinicio por inactividad.
- Prioridad de combos: los cuatro botones (salir) > B2 + B3 (grabar) > B2 + B4 (borrar) > B3 + B4 (guardar).

## Después (NO implementar sin pedido explícito)

- Control por USB: un microcontrolador que aparece como dispositivo MIDI (Godot lee `InputEventMIDI`).
  Primer candidato: sensor de distancia que controla `tempo_scale`. Después: giroscopio, piezo (golpes), luz.
- Modulación armónica global (cambiar de modo la escala de todas las capas) como truco con combinación de joystick + botón.
- Combos ocultos tipo arcade.
- Cuantización libre del tiempo (cursor con inercia).

## Decisiones tomadas y por qué

| Decisión | Motivo |
|---|---|
| Cursor por pasos | El joystick es digital; un eje de posición no existe |
| Ciclo distinto por capa, asignado por el sistema | No limita a quien juega y produce desfasaje (Eno/Riley) sin explicar nada |
| Escala bloqueada | Evita notas "malas" y permite que cualquiera suene bien |
| Nota fantasma | Feedback inmediato; reemplaza al tutorial |
| Una regla para los botones (mantener = cambia qué mueve el joystick) | Poca carga cognitiva; se aprende probando |
| Arrancar de cero | Decisión de Maxi: lo único que suena al inicio es la nota fantasma |
| No guardar automáticamente | Decisión de Maxi: si se van sin guardar, la pieza se pierde |
| Solo Godot | Evitar dependencias en una máquina de uso público; la lógica elegida no necesita sincronía a la muestra |
| Grabación desde el inicio de la pieza, con tope de 8 min | Sin tope crece sin límite en RAM; 85 MB es un pico acotado y medible |
| Reinicio por inactividad a los 5 min | Coincide con el máximo de la sesión típica: nadie pierde la pieza mientras piensa |
| Salida solo por el combo de 4 botones | Si la aplicación se cuelga queda el sistema operativo; el combo lo conoce quien administra el arcade |
| Escenas, buses e InputMap creados por código | Un `.tscn` escrito a mano es el error más difícil de depurar; el InputMap serializado en `project.godot` es un formato frágil |

## Riesgos conocidos

- **Jitter de tiempo**: calcular pasos desde el reloj real en `_process` implica un error máximo de ~1 frame (16 ms a 60 fps).
  Es aceptable con sonidos de ataque lento. Con ataques percusivos puede notarse. Medirlo pronto.
- **Rango de pitch**: resuelto con dos samples por capa (grave/agudo, split en la fila 5): cada zona se estira
  como máximo 10 semitonos. Falta escucharlo con los samples reales.
- **Rendimiento**: especificaciones de la mini PC desconocidas. Probar en el arcade real lo antes posible.
- **RAM de la grabación**: 8 minutos son unos 85 MB, y al guardar se duplica transitoriamente al codificar el WAV.
  Medir el pico en el arcade (S0b).
- **Input**: el encoder puede aparecer como gamepad o teclado. Verificar con `evtest` o `jstest` en Fedora.
