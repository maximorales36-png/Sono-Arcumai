# Datos puros del instrumento: capas, notas (conjunto de celdas) y cursor. Sin nodos.
# Depende de config.gd para los límites de la grilla.
class_name State
extends RefCounted

var layers: Array[Layer] = []
var active_layer_index: int = 0
# Vista de todas las capas a la vez: no hay capa activa y no se edita.
var show_all_layers: bool = false
# Plano que mueve el joystick ahora mismo (Config.PARAMETER_PLANE_*).
var active_plane: int = Config.PARAMETER_PLANE_NONE
var cursor_step: int = 0
var cursor_row: int = 0

# Último nombre guardado y hasta cuándo se muestra en pantalla.
var saved_piece_name: String = ""
var save_message_until_msec: int = 0

# Efectos globales de la vista general (S-FX): estado del joystick en vivo.
var live_fx: FxSet = FxSet.new()
# Mismo par de efectos, alimentado por el gesto grabado. El vivo lo usa como destino
# cuando el efecto no está mantenido con el joystick real.
var gesture_fx: FxSet = FxSet.new()

# Gesto grabado: null si no hay ninguno.
var gesture: Gesture = null

# Indicadores en pantalla del gesto.
var gesture_is_recording: bool = false
var gesture_remaining_seconds: float = 0.0
var gesture_clear_ratio: float = 0.0


class Layer:
	extends RefCounted

	# Clave Vector2i(paso, fila). Solo existen las celdas que tienen nota.
	var notes: Dictionary[Vector2i, bool] = {}

	# Parámetros de timbre y envolvente propios de la capa (S4).
	var cutoff_hz: float = Config.CUTOFF_MAX_HZ
	var reverb_wet: float = Config.REVERB_DEFAULT_WET
	var attack_seconds: float = Config.ATTACK_DEFAULT_SECONDS
	var decay_seconds: float = Config.DECAY_DEFAULT_SECONDS

	func reset() -> void:
		notes.clear()
		cutoff_hz = Config.CUTOFF_MAX_HZ
		reverb_wet = Config.REVERB_DEFAULT_WET
		attack_seconds = Config.ATTACK_DEFAULT_SECONDS
		decay_seconds = Config.DECAY_DEFAULT_SECONDS


# Un efecto global: wet (0 a 1) y speed (-1 lento, 0 centro, +1 rápido).
class FxUnit:
	extends RefCounted

	var wet: float = 0.0
	var speed: float = 0.0

	func reset() -> void:
		wet = 0.0
		speed = 0.0


# Los dos efectos globales juntos: uno en vivo y otro para el gesto grabado.
class FxSet:
	extends RefCounted

	var delay: FxUnit = FxUnit.new()
	var tremolo: FxUnit = FxUnit.new()

	func reset() -> void:
		delay.reset()
		tremolo.reset()


# Gesto grabado del joystick: duración del bucle y cambios de dirección.
# Cada evento es [tiempo_en_segundos, máscara Config.GESTURE_DIR_*].
class Gesture:
	extends RefCounted

	var duration_seconds: float = 0.0
	var events: Array[Array] = []


func _init() -> void:
	for _layer_index: int in Config.LAYER_COUNT:
		layers.append(Layer.new())


# Vuelve a una pieza vacía, con los parámetros por defecto (reinicio por inactividad).
func reset_piece() -> void:
	for layer: Layer in layers:
		layer.reset()
	active_layer_index = 0
	show_all_layers = false
	active_plane = Config.PARAMETER_PLANE_NONE
	cursor_step = 0
	cursor_row = 0
	saved_piece_name = ""
	save_message_until_msec = 0
	live_fx.reset()
	gesture_fx.reset()
	gesture = null
	gesture_is_recording = false
	gesture_remaining_seconds = 0.0
	gesture_clear_ratio = 0.0


func get_active_layer() -> Layer:
	assert(
		not show_all_layers,
		"[state] no hay capa activa: se está mostrando la vista de todas las capas"
	)
	assert(
		active_layer_index >= 0 and active_layer_index < layers.size(),
		"[state] capa activa fuera de rango: %d" % active_layer_index
	)
	return layers[active_layer_index]


func has_note(step: int, row: int) -> bool:
	return get_active_layer().notes.has(Vector2i(step, row))


# Devuelve true si la nota quedó asentada, false si se borró.
func toggle_note(step: int, row: int) -> bool:
	assert(step >= 0 and step < Config.STEPS, "[state] paso fuera de rango: %d" % step)
	assert(row >= 0 and row < Config.ROWS, "[state] fila fuera de rango: %d" % row)
	var cell := Vector2i(step, row)
	if get_active_layer().notes.has(cell):
		get_active_layer().notes.erase(cell)
		return false
	get_active_layer().notes[cell] = true
	return true
