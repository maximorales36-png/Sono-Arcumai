# Plan de sesiones

Cada sesión de opencode tiene un alcance cerrado. Se abre una sesión nueva por cada una (el contexto no se arrastra:
la memoria entre sesiones es `AGENTS.md` + `docs/ESTADO.md` + git).

## Cómo usar esto con opencode

1. Poner `AGENTS.md` en la raíz del proyecto. opencode lo lee solo al abrir la sesión.
   **No correr `/init`** sobre este proyecto: está pensado para generar un `AGENTS.md` nuevo y podría pisar este.
2. Abrir una sesión nueva por cada bloque de abajo, desde la carpeta del proyecto.
3. Pegar el mensaje de inicio (plantilla de abajo) cambiando el número de sesión.
4. Si tu versión de opencode tiene modo plan, usalo al principio para revisar el plan antes de que edite archivos.
5. Al terminar, verificar el "Listo cuando" a mano antes de abrir la sesión siguiente.
6. Opcional: definir un agente propio con el rol en `.opencode/agents/` (revisá la documentación de tu versión, el formato cambió entre versiones).
   Con `AGENTS.md` alcanza.

### Mensaje de inicio (plantilla)

```
Sesión S<N>. Leé AGENTS.md y docs/ESTADO.md. Del resto, leé solo la sección S<N> de docs/SESIONES.md
y lo que necesites de docs/DISENO.md. Resumime en 5 líneas qué vas a hacer y empezá.
```

### Mensaje de cierre (plantilla)

```
Cerrá la sesión: actualizá docs/ESTADO.md, hacé commit, y decime qué pruebas manuales tengo que hacer
y qué necesito tener listo para la próxima sesión.
```

## Regla de oro

No arrancar una sesión sin que la anterior cumpla su "Listo cuando". Después de S2 hay una prueba con una persona real
antes de seguir (ver S2). Si algo no suena bien, se corrige ahí. Ningún control nuevo arregla un sonido flojo.

---

## S0: Esqueleto y prueba en hardware real

**Objetivo**: demostrar que el proyecto corre en el arcade y que audio e input funcionan allí, antes de construir nada.

**Alcance**
- Proyecto Godot 4.x (Compatibility), `git init`, estructura de carpetas de `AGENTS.md`.
- InputMap con acciones registradas por código al arrancar (ver `AGENTS.md`): `move_left`, `move_right`, `move_up`, `move_down`, `btn1`, `btn2`, `btn3`, `btn4`.
  Cada acción mapeada a tres cosas:
  - Teclado de desarrollo: W A S D para el joystick y H J K L para los botones 1 a 4.
  - Teclado estilo arcade/MAME (flechas + Ctrl, Alt, Espacio, Shift), por si el encoder del arcumai aparece como teclado.
  - Gamepad (hat/ejes y botones 0 a 3).
- Escena mínima que muestra en pantalla qué acciones están apretadas, y reproduce un sonido al apretar `btn1`.
- Esc cierra la aplicación solo en builds de debug (`OS.is_debug_build()`).
- Pantalla completa, mouse oculto.
- Preset de exportación `Linux` y un build Linux x86_64 (comandos en `AGENTS.md`).

**Fuera de alcance**: grilla, secuenciador, capas, efectos, guardado.

**Listo cuando**
- En la computadora de desarrollo, con `godot --path . --windowed`: W A S D y H J K L se ven como acciones en pantalla y suena el sonido.
- En el arcumai (puede hacerse como S0b cuando esté ensamblado): el build corre, el joystick y los 4 botones se ven en pantalla,
  y se oye el sonido por el parlante.
- `docs/ESTADO.md` registra: cómo ve Fedora el joystick (gamepad o teclado), versión de Godot, especificaciones de la mini PC.

**Maxi necesita tener**: acceso al arcumai, y Godot con las plantillas de exportación instaladas.

---

## S1: Estado, cursor y vista (sin sonido)

**Objetivo**: poder moverse por la grilla y asentar/borrar notas viendo el resultado.

**Alcance**
- `config.gd`, `state.gd` (capas, notas como conjunto de celdas, cursor), `controller.gd`, `view.gd`.
- Grilla `STEPS` x `ROWS`. Cursor que se mueve de a un paso, con repetición al mantener (lógica propia, no `is_echo`).
- `btn1` alterna nota en la celda del cursor.
- Una sola capa por ahora.

**Fuera de alcance**: audio, barrido, capas múltiples, botones B2 a B4.

**Listo cuando**
- Con el joystick del arcade (o teclado) el cursor se mueve de forma predecible, repite al mantener y da la vuelta en X.
- B1 asienta y borra notas, y se ven.

---

## S2: Secuenciador y audio (versión mínima jugable)

**Objetivo**: que suene. Esta es la sesión que decide si el concepto funciona.

**Alcance**
- `sequencer.gd`: posición de la línea de barrido desde el reloj real; señal cuando cambia de paso.
- `voice_pool.gd`: reproduce el sample con `pitch_scale` según la fila y la escala de `config.gd`. Pool de reproductores.
- Nota fantasma: el cursor suena cuando la línea pasa por su columna.
- Notas asentadas suenan al pasar la línea.
- Línea de barrido dibujada en la vista.
- Un solo sonido (usar el sample de Maxi, o placeholder).

**Fuera de alcance**: más capas, B2 a B4, efectos, guardado.

**Listo cuando**
- Moverse con el joystick cambia lo que se oye en cada vuelta.
- Hay un ciclo continuo sin cortes ni acumulación de error de tiempo (dejarlo corriendo 10 minutos).
- Se midió el jitter de tiempo y se anotó en `ESTADO.md`.

**PRUEBA CON UNA PERSONA (obligatoria antes de S3)**: darle el arcade a alguien que no sepa de música, sin explicar nada,
durante 3 minutos. Anotar en `ESTADO.md`: qué hizo en los primeros 20 segundos, si entendió qué movía qué, si sonó bien.
Si no suena bien o no se entiende, corregir ACÁ (sample, escala, rango, velocidad del ciclo) antes de agregar cosas.

---

## S3: Capas

**Objetivo**: varias capas con ciclos distintos que se desfasan.

**Alcance**
- Estado: lista de `LAYER_COUNT` capas, cada una con notas, período, color y sample propios.
- `btn2` pasa a la capa siguiente (circular). El cursor adopta color y sonido de la capa activa.
- Una línea de barrido por capa, cada una con su período (valores de `DISENO.md`), dibujadas en el mismo plano.
- `tempo_scale` global multiplicando la velocidad de las líneas (valor fijo 1.0).

**Fuera de alcance**: B3 y B4, efectos, guardado.

**Listo cuando**
- 4 capas suenan a la vez desfasándose; se ven las 4 líneas a distinta velocidad.
- Cambiar de capa con B2 es inmediato y se nota en pantalla y en el sonido.
- Cada capa conserva sus notas al cambiar.

---

## S4: Timbre y envolvente

**Objetivo**: que el joystick pueda transformar notoriamente el sonido.

**Alcance**
- Un bus de audio por capa con filtro pasa-bajos y reverb.
- `btn3` mantenido: el joystick mueve X = cutoff y Y = reverb de la capa activa.
- `btn4` mantenido: el joystick mueve X = ataque y Y = decay (envolvente por voz).
- Indicador visual simple mientras B3 o B4 están apretados.
- Cada capa guarda sus parámetros.

**Fuera de alcance**: guardado, combos, USB.

**Listo cuando**
- Los cambios se oyen claramente y al instante.
- Soltar el botón devuelve al joystick a mover el cursor.
- Los parámetros de cada capa persisten al cambiar de capa.

---

## S5: Guardar, salir y modo kiosco

**Objetivo**: que sea utilizable de forma desatendida.

**Alcance**
- Grabación de audio en curso desde el inicio de la pieza, con tope de 8 min (ver `DISENO.md`).
- Combo B3 + B4 mantenido 2 s: guardar JSON del estado y WAV de la pieza en una carpeta configurable
  (por defecto una carpeta de usuario del arcumai). Mostrar un nombre corto en pantalla.
- Combo de los 4 botones mantenido 5 s: cerrar la aplicación.
- Reinicio a pieza vacía tras 300 s de inactividad, que también reinicia la grabación (decisión de Maxi, ver `DISENO.md`).
- Arranque automático en Fedora al encender y reinicio si se cuelga (pedir a Maxi cómo se lanza hoy el arcade antes de decidir el método).

**Listo cuando**
- Se guarda una pieza y el WAV se puede abrir y escuchar.
- El combo de salida no se dispara por accidente en uso normal.
- Se enciende el arcade y entra directo a la aplicación.

---

## S6 (opcional): Entrada MIDI

**Objetivo**: preparar el software para un control externo.

**Alcance**
- `OS.open_midi_inputs()`; recibir `InputEventMIDI`.
- Un CC mapeado a `tempo_scale`, con rango sensato (por ejemplo 0.5 a 2.0) y suavizado.
- Probar con cualquier controlador MIDI USB.

**Listo cuando**: un controlador MIDI cambia la velocidad de todas las líneas en vivo sin saltos.

## S7 (opcional, otro proyecto): Firmware del sensor

Microcontrolador (Pico/Arduino/ESP32) con CircuitPython o Arduino que lee un sensor de distancia y se presenta como dispositivo
MIDI USB enviando un CC. Es una sesión aparte, con su propia carpeta `firmware/`, y no toca el código de Godot.

---

## Backlog (no hacer sin pedido)

Modulación armónica, combos ocultos, giroscopio, piezo, sensor de luz, cuantización libre, más samples por capa,
mejoras visuales.
