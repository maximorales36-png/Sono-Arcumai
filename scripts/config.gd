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
