# Estado del proyecto

Este archivo es la memoria entre sesiones. Cada sesión lo lee al empezar y lo actualiza al terminar.
Mantenerlo corto: reemplazar lo viejo, no acumular.

## Dónde estamos

- Sesión completada más reciente: ninguna
- Próxima sesión: S0 (esqueleto y prueba en hardware real)
- Antes de S0 se revisaron y actualizaron `AGENTS.md` y `DISENO.md`: arquitectura y cableado, escenas e InputMap por código,
  grabación atada al reinicio con tope, reinicio por inactividad a 5 minutos.

## Datos a confirmar (Maxi)

| Dato | Valor |
|---|---|
| Versión de Godot | 4.7.2 stable oficial (`ed1daf0bf`), verificado con `--version` |
| Ruta del binario en la máquina de desarrollo | `C:\Users\maxim\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe` (esa carpeta se llama `...exe`; adentro está también el `_console.exe`, que es el que imprime en la terminal) |
| Especificaciones de la mini PC del arcumai (CPU, RAM, gráficos) | por confirmar |
| Cómo ve Fedora el joystick (gamepad o teclado) | por confirmar (probar con `evtest` o `jstest`) |
| Índice de gamepad que asigna el encoder (`InputEventJoypadButton.device`) | por confirmar en S0 |
| Salida de audio (parlante interno, jack, HDMI, parlante externo) | por confirmar |
| Cómo se lanza hoy el arcade (frontend, launcher, escritorio) | por confirmar |
| Quién administra el arcade y conoce el combo de salida (4 botones, 5 s) | por confirmar |
| Samples de las capas (`layer_1.wav` … `layer_4.wav` y nota raíz MIDI de cada uno) | por entregar, antes de S2 |
| Carpeta donde se guardan las piezas | por decidir (S5) |
| ¿La mini PC tiene internet? | por confirmar |

## Hecho

(vacío)

## Decisiones tomadas durante el desarrollo

Las decisiones de diseño previas a S0 están en la tabla de `docs/DISENO.md`.
Acá van solo las que se toman durante una sesión.

## Propuestas de diseño

Cambios que implican tocar `docs/DISENO.md`. El agente los anota acá; Maxi decide.
Formato: qué se propone, por qué, y qué evidencia lo sostiene (por ejemplo, la prueba con una persona de S2).

(vacío)

## Pendientes

- S0: confirmar el índice de gamepad que asigna el encoder y si registrar la acción con `device = -1`
  matchea cualquier dispositivo en 4.7.2.
- S0b (arcade): medir FPS con las 4 líneas y las notas. Optimizar la vista solo si hay problema.
- S0b (arcade): medir el pico de RAM al guardar una grabación de 8 minutos.

## Bugs conocidos

(vacío)

## Resultado de la prueba con persona (S2)

(vacío)
