# Lee las acciones del InputMap, mueve el cursor (con repetición al mantener), asienta o borra notas,
# cambia de capa y, con B3 o B4 apretados, mueve el timbre o la envolvente de la capa activa. En la
# vista general (todas las capas) el joystick maneja los efectos globales a través de FxDrive, y los
# combos con B2 graban o borran el gesto. Depende de config.gd, state.gd, fx_drive.gd y gesture_drive.gd.
class_name Controller
extends Node

signal layer_changed(layer: int)
signal parameters_changed(layer: int)
signal save_requested
signal quit_requested
signal inactivity_reset

var state: State
var fx_drive: FxDrive
var gesture_drive: GestureDrive

# Próximo instante (ms) en que cada dirección vuelve a repetir.
var _repeat_at_msec: Dictionary[StringName, int] = {}

# Combo en curso y su instante de inicio.
var _combo_kind: int = Config.COMBO_NONE
var _combo_start_msec: int = 0
var _combo_fired: bool = false

# B2 solo cambia de vista al soltarlo, y solo si no se usó en un combo.
var _b2_used_in_combo: bool = false

# Última entrada del jugador, para el reinicio por inactividad.
var _last_input_msec: int = 0


func _ready() -> void:
	assert(state != null, "[controller] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")
	assert(fx_drive != null, "[controller] falta el FxDrive: main.gd tiene que asignarlo antes de agregar el nodo")
	assert(gesture_drive != null, "[controller] falta el GestureDrive: main.gd tiene que asignarlo antes de agregar el nodo")
	_last_input_msec = Time.get_ticks_msec()


func _input(_event: InputEvent) -> void:
	_last_input_msec = Time.get_ticks_msec()


func _process(delta: float) -> void:
	var now_msec := Time.get_ticks_msec()
	var now_usec := Time.get_ticks_usec()
	if Input.is_anything_pressed():
		_last_input_msec = now_msec
	_check_inactivity(now_msec)

	var up := Input.is_action_pressed(Config.ACTION_MOVE_UP)
	var down := Input.is_action_pressed(Config.ACTION_MOVE_DOWN)
	var left := Input.is_action_pressed(Config.ACTION_MOVE_LEFT)
	var right := Input.is_action_pressed(Config.ACTION_MOVE_RIGHT)

	if Input.is_action_just_pressed(Config.ACTION_BTN2):
		_b2_used_in_combo = false

	# El gesto se graba con el joystick crudo (en cualquier vista) y se reproduce siempre.
	var combo := _update_combos(now_msec, now_usec, up, down, left, right)
	if combo == Config.COMBO_NONE:
		_update_plane()
	gesture_drive.update(delta, now_usec, up, down, left, right)

	# Los efectos en vivo solo existen en la vista general; el gesto grabado se suma en todas.
	var effects_here := state.show_all_layers
	fx_drive.update(
		up and effects_here, down and effects_here, left and effects_here, right and effects_here, delta
	)

	_handle_b2_release()

	# Mientras dura un combo, nada más responde.
	if combo != Config.COMBO_NONE:
		return

	# Vista general: el joystick maneja los efectos, B1 y B3/B4 no hacen nada y B2 sale al soltarlo.
	if state.show_all_layers:
		return

	# Con B3 o B4 apretados, el joystick mueve parámetros y el cursor no se mueve.
	if state.active_plane == Config.PARAMETER_PLANE_TIMBRE:
		_handle_timbre_plane(now_msec)
		return
	if state.active_plane == Config.PARAMETER_PLANE_ENVELOPE:
		_handle_envelope_plane(now_msec)
		return

	_handle_direction(Config.ACTION_MOVE_UP, Vector2i(0, -1), now_msec)
	_handle_direction(Config.ACTION_MOVE_DOWN, Vector2i(0, 1), now_msec)
	_handle_direction(Config.ACTION_MOVE_LEFT, Vector2i(-1, 0), now_msec)
	_handle_direction(Config.ACTION_MOVE_RIGHT, Vector2i(1, 0), now_msec)

	if Input.is_action_just_pressed(Config.ACTION_BTN1):
		_toggle_note()


func _update_plane() -> void:
	var new_plane: int = Config.PARAMETER_PLANE_NONE
	if not state.show_all_layers:
		if Input.is_action_pressed(Config.ACTION_BTN3):
			new_plane = Config.PARAMETER_PLANE_TIMBRE
		elif Input.is_action_pressed(Config.ACTION_BTN4):
			new_plane = Config.PARAMETER_PLANE_ENVELOPE
	if new_plane == state.active_plane:
		return
	state.active_plane = new_plane
	print("[controller] modo %s" % _plane_name(new_plane))


# Devuelve el combo en curso (o COMBO_NONE). Los de B2 se marcan para que B2 no cambie de vista.
func _update_combos(
	now_msec: int, now_usec: int, up: bool, down: bool, left: bool, right: bool
) -> int:
	var kind := _current_combo()
	if kind != _combo_kind:
		_end_combo(_combo_kind, now_usec)
		_combo_kind = kind
		_combo_start_msec = now_msec
		_combo_fired = false
		_start_combo(kind, now_usec, up, down, left, right)

	if kind == Config.COMBO_NONE:
		state.gesture_clear_ratio = 0.0
		return Config.COMBO_NONE

	# Mientras se mantiene el combo no se mueve nada más ni se muestra el indicador de B3/B4.
	state.active_plane = Config.PARAMETER_PLANE_NONE
	if Input.is_action_pressed(Config.ACTION_BTN2):
		_b2_used_in_combo = true

	if kind == Config.COMBO_GESTURE_CLEAR and not _combo_fired:
		state.gesture_clear_ratio = minf(
			float(now_msec - _combo_start_msec) / float(Config.GESTURE_CLEAR_MSEC), 1.0
		)

	# La grabación la cierra GestureDrive (al soltar o al llegar al máximo); acá no se dispara nada.
	if kind == Config.COMBO_GESTURE_RECORD:
		return kind

	var needed_msec := _combo_needed_msec(kind)
	if _combo_fired or now_msec - _combo_start_msec < needed_msec:
		return kind

	_combo_fired = true
	match kind:
		Config.COMBO_SAVE:
			print("[controller] combo de guardado")
			save_requested.emit()
		Config.COMBO_QUIT:
			print("[controller] combo de salida")
			quit_requested.emit()
		Config.COMBO_GESTURE_CLEAR:
			gesture_drive.clear_gesture()
			state.gesture_clear_ratio = 0.0
	return kind


# Los cuatro botones mandan sobre el resto: así el combo de salida no guarda de paso.
# B2+B3 graba y B2+B4 borra; si se aprietan B3 y B4 a la vez gana la grabación.
func _current_combo() -> int:
	var btn1 := Input.is_action_pressed(Config.ACTION_BTN1)
	var btn2 := Input.is_action_pressed(Config.ACTION_BTN2)
	var btn3 := Input.is_action_pressed(Config.ACTION_BTN3)
	var btn4 := Input.is_action_pressed(Config.ACTION_BTN4)
	if btn1 and btn2 and btn3 and btn4:
		return Config.COMBO_QUIT
	if btn2 and btn3:
		return Config.COMBO_GESTURE_RECORD
	if btn2 and btn4:
		return Config.COMBO_GESTURE_CLEAR
	if btn3 and btn4:
		return Config.COMBO_SAVE
	return Config.COMBO_NONE


func _combo_needed_msec(kind: int) -> int:
	match kind:
		Config.COMBO_SAVE:
			return Config.SAVE_COMBO_MSEC
		Config.COMBO_QUIT:
			return Config.QUIT_COMBO_MSEC
		Config.COMBO_GESTURE_CLEAR:
			return Config.GESTURE_CLEAR_MSEC
		_:
			return 0


func _start_combo(
	kind: int, now_usec: int, up: bool, down: bool, left: bool, right: bool
) -> void:
	if kind == Config.COMBO_GESTURE_RECORD:
		gesture_drive.start_recording(now_usec, up, down, left, right)


func _end_combo(kind: int, now_usec: int) -> void:
	if kind == Config.COMBO_GESTURE_RECORD:
		gesture_drive.finish_recording(now_usec)
	if kind == Config.COMBO_GESTURE_CLEAR:
		state.gesture_clear_ratio = 0.0


func _handle_b2_release() -> void:
	if not Input.is_action_just_released(Config.ACTION_BTN2):
		return
	var used_in_combo := _b2_used_in_combo
	_b2_used_in_combo = false
	# Si B2 se usó en un combo, soltarlo no cambia de vista.
	if used_in_combo:
		return
	_select_next_layer()


func _check_inactivity(now_msec: int) -> void:
	if now_msec - _last_input_msec < Config.INACTIVITY_RESET_MSEC:
		return
	_last_input_msec = now_msec
	print("[controller] reinicio por inactividad")
	inactivity_reset.emit()


func _plane_name(plane: int) -> String:
	match plane:
		Config.PARAMETER_PLANE_TIMBRE:
			return "timbre (B3)"
		Config.PARAMETER_PLANE_ENVELOPE:
			return "envolvente (B4)"
		_:
			return "ninguno"


func _handle_timbre_plane(now_msec: int) -> void:
	var layer: State.Layer = state.get_active_layer()
	var changed := false

	if _repeat_now(Config.ACTION_MOVE_LEFT, now_msec):
		layer.cutoff_hz = clampf(
			layer.cutoff_hz / Config.CUTOFF_STEP_RATIO, Config.CUTOFF_MIN_HZ, Config.CUTOFF_MAX_HZ
		)
		changed = true
	if _repeat_now(Config.ACTION_MOVE_RIGHT, now_msec):
		layer.cutoff_hz = clampf(
			layer.cutoff_hz * Config.CUTOFF_STEP_RATIO, Config.CUTOFF_MIN_HZ, Config.CUTOFF_MAX_HZ
		)
		changed = true
	if _repeat_now(Config.ACTION_MOVE_UP, now_msec):
		layer.reverb_wet = clampf(
			layer.reverb_wet + Config.REVERB_STEP, Config.REVERB_MIN_WET, Config.REVERB_MAX_WET
		)
		changed = true
	if _repeat_now(Config.ACTION_MOVE_DOWN, now_msec):
		layer.reverb_wet = clampf(
			layer.reverb_wet - Config.REVERB_STEP, Config.REVERB_MIN_WET, Config.REVERB_MAX_WET
		)
		changed = true

	if changed:
		parameters_changed.emit(state.active_layer_index)


func _handle_envelope_plane(now_msec: int) -> void:
	var layer: State.Layer = state.get_active_layer()
	var changed := false

	if _repeat_now(Config.ACTION_MOVE_LEFT, now_msec):
		layer.attack_seconds = clampf(
			layer.attack_seconds - Config.ATTACK_STEP_SECONDS, Config.ATTACK_MIN_SECONDS, Config.ATTACK_MAX_SECONDS
		)
		changed = true
	if _repeat_now(Config.ACTION_MOVE_RIGHT, now_msec):
		layer.attack_seconds = clampf(
			layer.attack_seconds + Config.ATTACK_STEP_SECONDS, Config.ATTACK_MIN_SECONDS, Config.ATTACK_MAX_SECONDS
		)
		changed = true
	if _repeat_now(Config.ACTION_MOVE_DOWN, now_msec):
		layer.decay_seconds = clampf(
			layer.decay_seconds - Config.DECAY_STEP_SECONDS, Config.DECAY_MIN_SECONDS, Config.DECAY_MAX_SECONDS
		)
		changed = true
	if _repeat_now(Config.ACTION_MOVE_UP, now_msec):
		layer.decay_seconds = clampf(
			layer.decay_seconds + Config.DECAY_STEP_SECONDS, Config.DECAY_MIN_SECONDS, Config.DECAY_MAX_SECONDS
		)
		changed = true

	if changed:
		parameters_changed.emit(state.active_layer_index)


func _handle_direction(action: StringName, delta_step: Vector2i, now_msec: int) -> void:
	if _repeat_now(action, now_msec):
		move_cursor(delta_step)


# Una pulsación dispara enseguida y, si se mantiene, repite a ritmo fijo.
func _repeat_now(action: StringName, now_msec: int) -> bool:
	# is_action_just_pressed y no is_echo: el teclado repite solo y no queremos dos lógicas a la vez.
	if Input.is_action_just_pressed(action):
		_repeat_at_msec[action] = now_msec + Config.CURSOR_REPEAT_DELAY_MSEC
		return true

	if not Input.is_action_pressed(action):
		_repeat_at_msec.erase(action)
		return false

	if now_msec >= _repeat_at_msec.get(action, 0):
		_repeat_at_msec[action] = now_msec + Config.CURSOR_REPEAT_INTERVAL_MSEC
		return true
	return false


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


# Circular: capa 1 → 2 → 3 → 4 → vista de todas → capa 1.
func _select_next_layer() -> void:
	if state.show_all_layers:
		state.show_all_layers = false
		state.active_layer_index = 0
		print("[controller] capa 1 de %d" % Config.LAYER_COUNT)
		layer_changed.emit(state.active_layer_index)
		return

	if state.active_layer_index == Config.LAYER_COUNT - 1:
		state.show_all_layers = true
		print("[controller] vista de todas las capas (%d)" % Config.LAYER_COUNT)
		return

	state.active_layer_index += 1
	print("[controller] capa %d de %d" % [state.active_layer_index + 1, Config.LAYER_COUNT])
	layer_changed.emit(state.active_layer_index)
