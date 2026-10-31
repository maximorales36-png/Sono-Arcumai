# Lee las acciones del InputMap, mueve el cursor (con repetición al mantener) y asienta o borra notas.
# Depende de config.gd y de state.gd: main.gd le asigna el State antes de agregarlo al árbol.
class_name Controller
extends Node

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
	print("[controller] nota %s: paso %d fila %d" % [action_word, state.cursor_step, state.cursor_row])
