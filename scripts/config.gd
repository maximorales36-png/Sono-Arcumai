# Constantes del proyecto: acciones del InputMap y sus mapeos de teclado y gamepad.
# Se usa como Config.STEPS, sin preload ni autoload. No depende de otros scripts.
class_name Config

const ACTION_MOVE_UP := &"move_up"
const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_DOWN := &"move_down"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_BTN1 := &"btn1"
const ACTION_BTN2 := &"btn2"
const ACTION_BTN3 := &"btn3"
const ACTION_BTN4 := &"btn4"
const ACTION_QUIT_DEBUG := &"quit_debug"

# Única fuente de verdad de las acciones: el registro del InputMap y el HUD de S0 salen de acá.
const ACTIONS: Array[StringName] = [
	ACTION_MOVE_UP,
	ACTION_MOVE_LEFT,
	ACTION_MOVE_DOWN,
	ACTION_MOVE_RIGHT,
	ACTION_BTN1,
	ACTION_BTN2,
	ACTION_BTN3,
	ACTION_BTN4,
	ACTION_QUIT_DEBUG,
]

const INPUT_DEADZONE := 0.5

# -1 = cualquier dispositivo. Verificado en 4.7.2: con device = 0 el evento de un gamepad
# con otro índice no matchea. Así el encoder puede aparecer como gamepad 0, 1 o 3.
const JOYPAD_DEVICE := -1

# Teclado de desarrollo (WASD + HJKL) y teclado estilo arcade/MAME (flechas + Ctrl, Alt, Espacio, Shift).
const KEY_BINDINGS := {
	ACTION_MOVE_UP: [KEY_W, KEY_UP],
	ACTION_MOVE_LEFT: [KEY_A, KEY_LEFT],
	ACTION_MOVE_DOWN: [KEY_S, KEY_DOWN],
	ACTION_MOVE_RIGHT: [KEY_D, KEY_RIGHT],
	ACTION_BTN1: [KEY_H, KEY_CTRL],
	ACTION_BTN2: [KEY_J, KEY_ALT],
	ACTION_BTN3: [KEY_K, KEY_SPACE],
	ACTION_BTN4: [KEY_L, KEY_SHIFT],
	ACTION_QUIT_DEBUG: [KEY_ESCAPE],
}

const JOY_BUTTON_BINDINGS := {
	ACTION_MOVE_UP: [JOY_BUTTON_DPAD_UP],
	ACTION_MOVE_LEFT: [JOY_BUTTON_DPAD_LEFT],
	ACTION_MOVE_DOWN: [JOY_BUTTON_DPAD_DOWN],
	ACTION_MOVE_RIGHT: [JOY_BUTTON_DPAD_RIGHT],
	ACTION_BTN1: [JOY_BUTTON_A],
	ACTION_BTN2: [JOY_BUTTON_B],
	ACTION_BTN3: [JOY_BUTTON_X],
	ACTION_BTN4: [JOY_BUTTON_Y],
}

# Un joystick digital puede aparecer como eje analógico a fondo.
const JOY_AXIS_BINDINGS := {
	ACTION_MOVE_UP: [JOY_AXIS_LEFT_Y, -1.0],
	ACTION_MOVE_LEFT: [JOY_AXIS_LEFT_X, -1.0],
	ACTION_MOVE_DOWN: [JOY_AXIS_LEFT_Y, 1.0],
	ACTION_MOVE_RIGHT: [JOY_AXIS_LEFT_X, 1.0],
}

# --- Grilla y cursor ---

const STEPS := 16
const ROWS := 10
const LAYER_COUNT := 4

const CURSOR_REPEAT_DELAY_MSEC := 250
const CURSOR_REPEAT_INTERVAL_MSEC := 80
const CURSOR_BLINK_PERIOD_MSEC := 600
const CURSOR_OUTLINE_WIDTH := 3.0

const GRID_MARGIN := 56.0
const GRID_LINE_COLOR := Color(0.20, 0.20, 0.26)
const GRID_LINE_WIDTH := 1.0
const NOTE_FILL_RATIO := 0.72

# Un color por capa, en el orden en que se crean.
const LAYER_COLORS: Array[Color] = [
	Color(0.45, 0.85, 0.95),
	Color(0.95, 0.65, 0.45),
	Color(0.75, 0.95, 0.55),
	Color(0.85, 0.65, 0.95),
]

# --- Sonido (S2) ---

# Períodos de ciclo por capa, en segundos. Que no sean múltiplos entre sí.
const LAYER_PERIOD_SECONDS: Array[float] = [7.0, 9.5, 11.3, 13.7]

# Multiplicador global de velocidad de las líneas. 1.0 = períodos tal cual.
const TEMPO_SCALE := 1.0

# Dos samples por capa: [0] grave (filas de abajo), [1] agudo (filas de arriba).
const LAYER_SAMPLE_PATHS: Array[Array] = [
	["res://assets/samples/layer_1_low.wav", "res://assets/samples/layer_1_high.wav"],
	["res://assets/samples/layer_2_low.wav", "res://assets/samples/layer_2_high.wav"],
	["res://assets/samples/layer_3_low.wav", "res://assets/samples/layer_3_high.wav"],
	["res://assets/samples/layer_4_low.wav", "res://assets/samples/layer_4_high.wav"],
]

# Nota MIDI de cada sample, en el mismo orden que LAYER_SAMPLE_PATHS.
# Por ahora todos iguales (placeholder); Maxi define la raíz de cada uno.
const LAYER_SAMPLE_ROOT_MIDI: Array[Array] = [
	[57, 69],
	[57, 69],
	[57, 69],
	[57, 69],
]

# Fila donde cambia la zona: de esta fila para abajo suena el sample grave.
const ZONE_SPLIT_ROW := 5

# Pentatónica menor, dos octavas: una entrada por fila, de grave a agudo.
const SCALE_SEMITONES: Array[int] = [0, 3, 5, 7, 10, 12, 15, 17, 19, 22]

# Nota MIDI que suena en la fila de abajo.
const GRID_BOTTOM_MIDI := 57

const VOICE_COUNT := 16
const NOTE_VOLUME_DB := -6.0
const SWEEP_LINE_WIDTH := 2.0
const SWEEP_LINE_WIDTH_ACTIVE := 3.0

# --- Timbre y envolvente (S4) ---

# Un bus por capa, nombrado layer_1 … layer_4.
const BUS_NAME_PREFIX := "layer_"

const CUTOFF_MIN_HZ := 200.0
const CUTOFF_MAX_HZ := 12000.0
# El cutoff se mueve en proporción (saltos de un 15 %), no en pasos fijos de Hz.
const CUTOFF_STEP_RATIO := 1.15

const REVERB_MIN_WET := 0.0
const REVERB_MAX_WET := 1.0
const REVERB_STEP := 0.05

const ATTACK_MIN_SECONDS := 0.005
const ATTACK_MAX_SECONDS := 1.0
const ATTACK_STEP_SECONDS := 0.02

const DECAY_MIN_SECONDS := 0.1
const DECAY_MAX_SECONDS := 4.0
const DECAY_STEP_SECONDS := 0.1

# Valores al arrancar: filtro abierto, sin reverb, ataque corto y cola de 2 s.
const REVERB_DEFAULT_WET := 0.0
const ATTACK_DEFAULT_SECONDS := 0.01
const DECAY_DEFAULT_SECONDS := 2.0

# La voz arranca desde acá para que el ataque se escuche, y termina acá.
const SILENT_VOLUME_DB := -60.0

# Qué plano mueve el joystick: ninguno, timbre (B3) o envolvente (B4).
const PARAMETER_PLANE_NONE := 0
const PARAMETER_PLANE_TIMBRE := 1
const PARAMETER_PLANE_ENVELOPE := 2

# Indicador en pantalla mientras B3 o B4 están apretados: un cuadrado con un punto,
# X = parámetro horizontal, Y = parámetro vertical.
const PARAMETER_PAD_SIZE := 72.0
const PARAMETER_PAD_DOT_SIZE := 9.0
const PARAMETER_PAD_MARGIN := 32.0
const PARAMETER_TRACK_COLOR := Color(0.20, 0.20, 0.26)

# --- Guardado y sesión (S5) ---

# Carpeta de las piezas. Con el directorio de usuario propio, en Linux queda en
# ~/.local/share/arcumai/piezas y en Windows en %APPDATA%\arcumai\piezas.
const SAVE_DIR := "user://piezas"
# Versión 2: agrega el gesto grabado al JSON.
const SAVE_FORMAT_VERSION := 2

# Tope de grabación por pieza: 8 minutos, unos 92 MB en RAM (48 kHz estéreo 16 bits).
const RECORDING_MAX_SECONDS := 480.0

# Combos: B3 + B4 guardan, los cuatro botones salen, B2 + B3 graba el gesto y B2 + B4 lo borra.
const COMBO_NONE := 0
const COMBO_SAVE := 1
const COMBO_QUIT := 2
const COMBO_GESTURE_RECORD := 3
const COMBO_GESTURE_CLEAR := 4
const SAVE_COMBO_MSEC := 2000
const QUIT_COMBO_MSEC := 5000

# Sin entrada durante este tiempo, la pieza se vacía y la grabación se reinicia.
const INACTIVITY_RESET_MSEC := 300000

# Nombre corto de la pieza: dos palabras de esta lista y un número.
const PIECE_NAME_WORDS: Array[String] = [
	"mar", "luna", "rio", "piedra", "aire", "lento", "alto", "suave", "tarde", "noche",
	"verde", "luz", "polvo", "campo", "viento", "frio", "calma", "sal", "barro", "sol",
]

# Cartel con el nombre de la pieza al guardar.
const SAVE_MESSAGE_SECONDS := 4.0
const SAVE_MESSAGE_FONT_SIZE := 24
const SAVE_MESSAGE_COLOR := Color(0.85, 0.85, 0.90)

# Intentos para encontrar un nombre de pieza que no exista ya en la carpeta.
const SAVE_NAME_ATTEMPTS := 20

# --- Efectos globales de la vista general (S-FX) ---

# Los efectos globales viven en el bus Master: la señal de las cuatro capas ya está mezclada ahí,
# así afectan a todo y el WAV los graba. (Un bus propio no sirve: el envío de capa a "fx" cambiado
# después de crear los buses no llega al audio en este Godot. Ver docs/ESTADO.md.)
const MASTER_BUS_NAME := "Master"

# Cada efecto tiene wet (0 a 1, reposo 0) y speed (-1 lento, 0 centro, +1 rápido, reposo 0).
# Con la dirección vertical mantenida el wet sube en este tiempo; al soltarla, todo vuelve al reposo.
const FX_WET_RISE_SECONDS := 3.0
const FX_SPEED_TO_EXTREME_SECONDS := 2.0
const FX_REST_SECONDS := 3.0
# Salto inicial del wet al empezar a mantener, para que el efecto se oiga enseguida.
const FX_WET_START_JUMP := 0.15

# Delay: el tiempo se interpola en forma geométrica entre los tres puntos.
const DELAY_TIME_SLOW_MS := 900.0
const DELAY_TIME_CENTER_MS := 400.0
const DELAY_TIME_FAST_MS := 120.0
# Feedback del delay, como porcentaje de la señal que vuelve, escalado por el wet: en reposo no
# queda ninguna cola sonando (el feedback de Godot suma su propio tap, aparte del nivel del delay).
const DELAY_FEEDBACK := 0.4
const DELAY_FEEDBACK_LOWPASS_HZ := 4000.0

# El tiempo del delay no se puede mover en marcha: AudioEffectDelay lee el buffer sin interpolar y
# cada salto del tiempo suena como un click. Se cambia solo cuando el speed se quedó quieto, con el
# tap apagado por una compuerta suave (pasa la señal seca) y después vuelve a entrar.
const DELAY_TIME_SETTLE_SECONDS := 0.15
const DELAY_TIME_DUCK_SECONDS := 0.2
const DELAY_TIME_FADE_SECONDS := 0.08

# El feedback tiene su propio buffer y su propio puntero, que no pasan por el nivel del tap: cambiar
# su tiempo salta la lectura. Se lo mueve solo con el efecto apagado (wet casi 0), cuando el buffer
# ya está en silencio.
const DELAY_FEEDBACK_SYNC_WET := 0.001

# Trémolo: velocidad del LFO en Hz, también geométrica. El wet es la profundidad.
const TREMOLO_RATE_SLOW_HZ := 0.5
const TREMOLO_RATE_CENTER_HZ := 3.0
const TREMOLO_RATE_FAST_HZ := 12.0

# Ganancia lineal que se usa como silencio al pasar niveles a dB.
const SILENT_GAIN := 0.0001

# --- Gesto grabado (S-FX fase 2) ---

# Máscara de direcciones de un evento del gesto. Se guarda como [tiempo, máscara].
const GESTURE_DIR_UP := 1
const GESTURE_DIR_DOWN := 2
const GESTURE_DIR_LEFT := 4
const GESTURE_DIR_RIGHT := 8

# La grabación dura lo que se mantiene el combo, entre estos dos valores.
const GESTURE_MAX_SECONDS := 20.0
const GESTURE_MIN_SECONDS := 1.0
# B2 + B4 mantenidos este tiempo borran el gesto guardado.
const GESTURE_CLEAR_MSEC := 2000

# Indicador de grabación (arriba al centro) y barra de progreso del borrado (abajo al centro).
const GESTURE_REC_COLOR := Color(0.95, 0.35, 0.35)
const GESTURE_REC_FONT_SIZE := 22
const GESTURE_CLEAR_BAR_WIDTH := 160.0
const GESTURE_CLEAR_BAR_HEIGHT := 8.0
const GESTURE_CLEAR_BAR_MARGIN := 40.0

# Indicadores de la vista general: un panel por efecto, con barra de wet y marcador de speed.
const FX_PANEL_WIDTH := 150.0
const FX_PANEL_HEIGHT := 34.0
const FX_PANEL_GAP := 10.0
const FX_PANEL_MARGIN := 32.0
const FX_SPEED_MARKER_WIDTH := 3.0
const FX_WET_BAR_ALPHA := 0.55
const FX_DELAY_COLOR := Color(0.90, 0.90, 0.95)
const FX_TREMOLO_COLOR := Color(0.95, 0.70, 0.30)
