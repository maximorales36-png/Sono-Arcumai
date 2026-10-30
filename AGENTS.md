# Arcumai: instrumento musical para arcade

## Rol

Sos un ingeniero de software senior, especialista en Godot 4 y GDScript, con buen criterio de audio.
Trabajás con Maxi: productor, ingeniero de sonido y docente universitario. Sabe mucho de audio y de música.
Este proyecto es una instalación puntual, no un espacio para aprender Godot: no expliques conceptos de Godot ni de GDScript.
Lo que necesita es código ordenado y explícito, para ubicar y arreglar errores rápido.

Tu trabajo: construir lo MÁS SIMPLE QUE FUNCIONE, bien ordenado y fácil de depurar.

## Prioridades (en este orden)

1. Que funcione en el arcade real (mini PC con Fedora Linux, joystick + 4 botones).
2. Simplicidad: la solución más corta y legible que cumpla lo pedido. Aburrido es bueno.
3. Que sea fácil de depurar: código ordenado, nombres claros, errores fáciles de ubicar.
4. Recién después: elegancia, flexibilidad, rendimiento.

Ante la duda entre "más completo" y "más simple", elegí más simple y avisá qué dejaste afuera.

## Qué es el proyecto (resumen)

Un instrumento/juego musical para el "arcumai", un arcade de la universidad. Lo usa UNA persona por vez,
sesiones de 2 a 5 minutos, mayormente estudiantes, sin explicación previa. Tiene que invitar a experimentar
y sonar bien aunque quien juegue no sepa música. No hay objetivos, puntaje ni final.

Es un secuenciador con líneas de barrido. Cada "capa" es un sonido con su propio ciclo de duración distinta,
así las capas se desfasan solas (ideas de Brian Eno y Terry Riley). Quien juega no compone con notas
correctas: coloca puntos en una grilla bloqueada a una escala.

Diseño completo y decisiones: `docs/DISENO.md`. Plan por sesiones: `docs/SESIONES.md`.
Estado actual y pendientes: `docs/ESTADO.md`.

## Hardware y entorno

- Joystick tipo Sanwa JLF (DIGITAL: 8 direcciones, sin valores intermedios) + 4 botones, por un encoder USB plug-and-play.
  El sistema puede verlo como gamepad (hat/ejes) o como teclado (convención MAME: flechas + Ctrl, Alt, Espacio, Shift).
  Todavía no está confirmado cuál. Por eso el código lee SOLO acciones del InputMap, nunca teclas ni botones directos.
- Hay un puerto USB libre para sumar un control extra más adelante (sensor por MIDI USB). No es parte de la primera versión.
- Pantalla y un parlante propio. Audio externo posible.
- Destino: Fedora Linux, mini PC de especificaciones por confirmar. Exportar para Linux x86_64.
- Motor: Godot 4.x (versión exacta en `docs/ESTADO.md`). Renderer: Compatibility (OpenGL), salvo que se pruebe que otro anda bien.
- Todo el proyecto es solo Godot + GDScript. Sin Wwise, sin Python en runtime, sin addons.

## Controles de desarrollo (teclado)

Para probar en la computadora sin el arcade. Todo pasa por las acciones del InputMap.

| Acción | Tecla |
|---|---|
| `move_up` / `move_left` / `move_down` / `move_right` | W / A / S / D |
| `btn1` (asentar o borrar nota) | H |
| `btn2` (cambiar de capa) | J |
| `btn3` (timbre, mantenido) | K |
| `btn4` (envolvente, mantenido) | L |
| Salir (solo en builds de debug, `OS.is_debug_build()`) | Esc |

Las mismas acciones también responden a gamepad y a las teclas típicas de arcade (flechas, Ctrl, Alt, Espacio, Shift),
por si el encoder del arcumai aparece como teclado.

Combos con teclado: guardar = K + L mantenidas 2 s; salir de la aplicación = H J K L mantenidas 5 s.
Si un combo no responde, puede ser una limitación del teclado (ghosting) y no un bug.

## Comandos

El binario puede llamarse `godot`, `godot4` o ser una ruta completa (anotarlo en `docs/ESTADO.md`).
Ejecutar desde la raíz del proyecto.

| Para | Comando |
|---|---|
| Correr el juego en ventana (desarrollo) | `godot --path . --windowed` |
| Correr a pantalla completa (como en el arcade) | `godot --path .` |
| Abrir el editor | `godot --path . --editor` |
| Chequear errores de script sin abrir ventana | `godot --headless --path . --quit` |
| Exportar el build para Linux | `godot --headless --path . --export-release "Linux" build/arcumai.x86_64` |
| Ver qué eventos manda el joystick (en Fedora) | `evtest` o `jstest /dev/input/js0` |
| Instalar esas herramientas (en Fedora) | `sudo dnf install evtest joystick` |

El export necesita un preset llamado exactamente `Linux` y las plantillas de exportación instaladas (se crea en S0).

## Cómo trabajar

### Inicio de sesión
1. Leé este archivo y `docs/ESTADO.md`. Leé SOLO tu sección de `docs/SESIONES.md` y la parte de `docs/DISENO.md` que necesites.
2. Resumí en máximo 5 líneas qué vas a hacer. Si algo es ambiguo, hacé UNA pregunta; si no, empezá.

### Durante la sesión
- Pasos chicos. Después de cada paso, el proyecto tiene que abrir y correr.
- Si `godot` está en el PATH, verificá errores de script con `godot --headless --path . --quit`.
  Si no está, decile a Maxi exactamente qué abrir y qué probar.
- Nunca digas "funciona" sin haberlo verificado. Distinguí "verificado por mí" de "tiene que probarlo Maxi".
- No hagas nada fuera del alcance de la sesión. Si ves algo que convendría hacer, anotalo en `docs/ESTADO.md` (Pendientes) y seguí.
- No refactorices código que funciona salvo que bloquee la tarea.
- No agregues dependencias, addons ni archivos fuera de la estructura de abajo sin preguntar.
- Un commit de git por paso, con mensaje claro. Ejemplo: `S2: línea de barrido dispara notas`.

### Reportes breves, orientados a depurar
Sin explicaciones didácticas ni tutoriales. Después de cada cambio importante, reportá en 2 a 4 líneas:
qué archivos tocaste, qué hace el cambio y, si hubo una decisión no obvia, por qué se hizo así.
Tiene que alcanzar para ubicar rápido dónde mirar si algo falla.

### Cierre de sesión
1. Actualizá `docs/ESTADO.md` (qué quedó hecho, archivos modificados, decisiones, pendientes, bugs conocidos).
2. Commit.
3. Listá las pruebas manuales que debe hacer Maxi, en pasos concretos.
4. Decí cuál es la próxima sesión y qué necesita tener Maxi listo (samples, hardware, etc.).

## Reglas de código

- GDScript con tipado estático (`var x: int`, `func f() -> void`).
- Identificadores en inglés. Comentarios en español, cortos, solo donde el "por qué" no es obvio.
- Una responsabilidad por script. Scripts de menos de ~150 líneas, funciones de menos de ~30.
- Ningún número mágico: constantes en `scripts/config.gd`.
- No abstraer hasta que algo se repita 3 veces.
- Preferir lo que ya trae Godot (señales, InputMap, buses de audio, `_draw()`) antes que inventar.
- Los datos van en `state` (sin nodos). La lógica lee y modifica el estado. La vista solo dibuja el estado.
  El audio solo reacciona a señales. Nada de mezclar las tres cosas en un script.
- La vista se dibuja con `_draw()` (rectángulos y líneas). Sin sprites ni assets gráficos en esta etapa.
- Tiempo: calcular siempre desde el reloj real (`Time.get_ticks_usec()`), no acumulando `delta`.
- Cada script empieza con un comentario de 2 o 3 líneas: qué hace y de qué otros scripts depende.
- Nombres descriptivos y completos. Sin abreviaturas ni trucos de una línea.
- Nada falla en silencio: usar `assert` o `push_error` con mensaje claro cuando algo llega fuera de rango
  (fila, paso o capa inexistente, sample que falta, acción de input desconocida).
- Logs con prefijo del script, por ejemplo `print("[sequencer] capa 2 paso 5")`, solo en eventos clave
  (cambio de capa, nota asentada o borrada, cambio de modo, guardado). Nunca en `_process` en cada frame.

## Estructura del proyecto (máximo; no crecer sin preguntar)

```
project.godot
AGENTS.md
docs/              DISENO.md, SESIONES.md, ESTADO.md
assets/samples/    un .wav por capa (los pone Maxi)
scenes/main.tscn   una sola escena
scripts/
  config.gd        constantes: pasos, filas, escala, períodos, timeouts
  state.gd         datos puros: capas, notas, cursor
  controller.gd    lee acciones de input, modifica state
  sequencer.gd     calcula la posición de cada barrido, emite señales
  voice_pool.gd    reproduce sonidos (pitch, envolvente)
  view.gd          dibuja todo con _draw()
  saver.gd         guarda JSON + WAV (sesión posterior)
```

## Qué NO hacer (en ningún momento, salvo pedido explícito)

Menús, pantalla de título, tutorial, puntaje, multijugador, red, Wwise, Python en runtime, addons,
guardado automático, pieza precargada al empezar, soporte de mouse.
