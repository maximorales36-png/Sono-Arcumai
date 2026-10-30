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
| B2 (toque) | Pasa a la capa siguiente (siguiente sonido). El cursor adopta el sonido de esa capa |
| B3 (mantenido) | El joystick mueve el plano tímbrico de la capa activa: X = brillo (filtro pasa-bajos), Y = cantidad de reverb |
| B4 (mantenido) | El joystick mueve el plano de envolvente de la capa activa: X = ataque, Y = decay |

Mientras B3 o B4 están apretados, el cursor no se mueve y la pantalla muestra una barra o punto con el valor del parámetro.
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

- Un sample `.wav` por capa en `assets/samples/`, con nombres fijos `layer_1.wav` … `layer_4.wav`.
  Los pone Maxi (grabaciones propias de guitarras, mandolinas, golpes de madera, etc.).
  Preferir sonidos con carácter y envolventes lentas. La nota raíz del sample (MIDI) se declara en `config.gd`.
  Si falta un archivo, `push_error` con su nombre y esa capa queda muda sin cerrar la aplicación.
- La altura se logra con `pitch_scale` = 2^(semitonos/12). Sirve para un rango de unas 2 octavas.
- Cada capa tiene su propio bus de audio con un filtro pasa-bajos y un reverb. B3 modifica esos efectos.
  Los buses se crean por código al arrancar (ver `AGENTS.md`), no hay `default_bus_layout.tres`.
- La envolvente (ataque/decay) se hace con volumen en cada voz (por ejemplo con un `Tween`), sobre un pool de reproductores.
- Un bus de grabación (`AudioEffectRecord`) captura la salida para guardar el WAV.
- Hasta que Maxi entregue samples, usar un WAV placeholder simple (un seno con decay) generado una vez con
  `tools/make_placeholder_wav.gd`. Es temporal.

## Visual

- Todo con `_draw()`. Fondo oscuro, grilla sobria, cada capa de un color, líneas de barrido finas, notas como cuadrados,
  cursor como contorno parpadeante del color de la capa activa.
- Nada de texto salvo el nombre de la pieza al guardar y los indicadores de B3/B4 mientras están apretados.
- Mouse oculto. Pantalla completa.

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
- **Rango de pitch**: estirar un solo sample más de ±1 octava cambia mucho su carácter. Si suena mal, usar dos samples por capa.
- **Rendimiento**: especificaciones de la mini PC desconocidas. Probar en el arcade real lo antes posible.
- **RAM de la grabación**: 8 minutos son unos 85 MB, y al guardar se duplica transitoriamente al codificar el WAV.
  Medir el pico en el arcade (S0b).
- **Input**: el encoder puede aparecer como gamepad o teclado. Verificar con `evtest` o `jstest` en Fedora.
