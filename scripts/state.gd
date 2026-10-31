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


class Layer:
	extends RefCounted

	# Clave Vector2i(paso, fila). Solo existen las celdas que tienen nota.
	var notes: Dictionary[Vector2i, bool] = {}

	# Parámetros de timbre y envolvente propios de la capa (S4).
	var cutoff_hz: float = Config.CUTOFF_MAX_HZ
	var reverb_wet: float = Config.REVERB_DEFAULT_WET
	var attack_seconds: float = Config.ATTACK_DEFAULT_SECONDS
	var decay_seconds: float = Config.DECAY_DEFAULT_SECONDS


func _init() -> void:
	for _layer_index: int in Config.LAYER_COUNT:
		layers.append(Layer.new())


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
