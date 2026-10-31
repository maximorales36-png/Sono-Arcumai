# Lee las acciones del InputMap, mueve el cursor (con repetición al mantener), asienta o borra notas
# y cambia de capa. Depende de config.gd y de state.gd: main.gd le asigna el State antes de agregarlo.
class_name Controller
extends Node

signal layer_changed(layer: int)

var state: State

# Próximo instante (ms) en que cada dirección vuelve a mover el cursor.
var _repeat_at_msec: Dictionary[StringName, int] = {}


func _ready() -> void:
	assert(state != null, "[controller] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")


func _process(_delta: float) -> void:
	var now_msec := Time.get_ticks_msec()
	_handle_direction(Config.ACTION_MOVE_UP, Vector2i(0, -1), now_msec)
	_handle_direction(Config.ACTION_MOVE_DOWN, Vector2i(0, 1), now_msec)
	_handle_direction(Config.ACTION_MOVE_LEFT, Vector2i(-1, 0), now_msec)
	_handle_direction(Config.ACTION_MOVE_RIGHT, Vector2i(1, 0), now_msec)

	if Input.is_action_just_pressed(Config.ACTION_BTN1):
		_toggle_note()

	if Input.is_action_just_pressed(Config.ACTION_BTN2):
		_select_next_layer()


func _handle_direction(action: StringName, delta_step: Vector2i, now_msec: int) -> void:
	# is_action_just_pressed y no is_echo: el teclado repite solo y no queremos dos lógicas a la vez.
	if Input.is_action_just_pressed(action):
		move_cursor(delta_step)
		_repeat_at_msec[action] = now_msec + Config.CURSOR_REPEAT_DELAY_MSEC
		return

	if not Input.is_action_pressed(action):
		_repeat_at_msec.erase(action)
		return

	if now_msec >= _repeat_at_msec.get(action, 0):
		move_cursor(delta_step)
		_repeat_at_msec[action] = now_msec + Config.CURSOR_REPEAT_INTERVAL_MSEC


# En X da la vuelta (el tiempo es cíclico); en Y se detiene en los bordes.
func move_cursor(delta_step: Vector2i) -> void:
	state.cursor_step = posmod(state.cursor_step + delta_step.x, Config.STEPS)
	state.cursor_row = clampi(state.cursor_row + delta_step.y, 0, Config.ROWS - 1)


func _toggle_note() -> void:
	var placed := state.toggle_note(state.cursor_step, state.cursor_row)
	var action_word := "asentada" if placed else "borrada"
	print("[controller] nota %s: capa %d paso %d fila %d" % [
		action_word, state.active_layer_index + 1, state.cursor_step, state.cursor_row
	])


# Circular: después de la última capa vuelve a la primera.
func _select_next_layer() -> void:
	state.active_layer_index = (state.active_layer_index + 1) % Config.LAYER_COUNT
	print("[controller] capa %d de %d" % [state.active_layer_index + 1, Config.LAYER_COUNT])
	layer_changed.emit(state.active_layer_index)
