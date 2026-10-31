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
