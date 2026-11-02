# Registra el InputMap, crea el estado y los módulos, y conecta el cableado.
# Depende de config.gd, state.gd, controller.gd, sequencer.gd, voice_pool.gd, global_fx.gd,
# saver.gd y view.gd.
extends Node2D

var _state: State
var _fx_drive: FxDrive
var _recorded_fx_drive: FxDrive
var _gesture_drive: GestureDrive
var _sequencer: Sequencer
var _voice_pool: VoicePool
var _global_fx: GlobalFx
var _controller: Controller
var _saver: Saver
var _view: View


func _enter_tree() -> void:
	# Antes de que cualquier script lea input.
	_register_input_actions()
	print("[main] InputMap listo: %d acciones" % Config.ACTIONS.size())


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	_state = State.new()

	# Dos instancias de la misma lógica: el joystick real y el gesto grabado.
	# La del joystick real apunta al set grabado cuando el efecto no está mantenido.
	_fx_drive = FxDrive.new()
	_fx_drive.fx = _state.live_fx
	_fx_drive.fallback = _state.gesture_fx

	_recorded_fx_drive = FxDrive.new()
	_recorded_fx_drive.fx = _state.gesture_fx

	_gesture_drive = GestureDrive.new()
	_gesture_drive.state = _state
	_gesture_drive.fx_drive = _recorded_fx_drive

	_sequencer = Sequencer.new()
	add_child(_sequencer)

	_voice_pool = VoicePool.new()
	_voice_pool.state = _state
	add_child(_voice_pool)
	_sequencer.step_entered.connect(_voice_pool.play_step)

	# Antes del saver: el delay y el trémolo van sobre el bus Master, así el WAV los graba.
	_global_fx = GlobalFx.new()
	_global_fx.state = _state
	add_child(_global_fx)

	_controller = Controller.new()
	_controller.state = _state
	_controller.fx_drive = _fx_drive
	_controller.gesture_drive = _gesture_drive
	add_child(_controller)
	_controller.layer_changed.connect(_voice_pool.play_cursor_preview)
	# Primero el bus, después la nota: la vista previa suena ya con el parámetro nuevo.
	_controller.parameters_changed.connect(_voice_pool.apply_layer_parameters)
	_controller.parameters_changed.connect(_voice_pool.play_cursor_preview)

	# Después del voice_pool: la grabación toma la salida ya mezclada del bus Master.
	_saver = Saver.new()
	_saver.state = _state
	add_child(_saver)
	_controller.save_requested.connect(_on_save_requested)
	_controller.quit_requested.connect(_on_quit_requested)
	_controller.inactivity_reset.connect(_on_inactivity_reset)

	_view = View.new()
	_view.state = _state
	_view.sequencer = _sequencer
	add_child(_view)


func _on_save_requested() -> void:
	var piece_name := _saver.save_piece()
	if piece_name.is_empty():
		return
	_state.saved_piece_name = piece_name
	_state.save_message_until_msec = Time.get_ticks_msec() + int(Config.SAVE_MESSAGE_SECONDS * 1000.0)


func _on_quit_requested() -> void:
	print("[main] salida pedida con el combo de los cuatro botones")
	get_tree().quit()


func _on_inactivity_reset() -> void:
	_state.reset_piece()
	# Los buses siguen con los parámetros viejos hasta que se los vuelve a aplicar.
	for layer: int in Config.LAYER_COUNT:
		_voice_pool.apply_layer_parameters(layer)
	_saver.restart_recording()
	print("[main] pieza vacía: se reinicia la grabación")


func _unhandled_input(event: InputEvent) -> void:
	# Esc cierra solo en builds de debug: en el arcade no existe esa salida.
	if not OS.is_debug_build():
		return
	if event.is_action_pressed(Config.ACTION_QUIT_DEBUG):
		get_tree().quit()


func _register_input_actions() -> void:
	for action: StringName in Config.ACTIONS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, Config.INPUT_DEADZONE)

	for action: StringName in Config.KEY_BINDINGS:
		for keycode: int in Config.KEY_BINDINGS[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action, key_event)

	for action: StringName in Config.JOY_BUTTON_BINDINGS:
		for button_index: int in Config.JOY_BUTTON_BINDINGS[action]:
			var button_event := InputEventJoypadButton.new()
			button_event.device = Config.JOYPAD_DEVICE
			button_event.button_index = button_index
			InputMap.action_add_event(action, button_event)

	for action: StringName in Config.JOY_AXIS_BINDINGS:
		var axis_binding: Array = Config.JOY_AXIS_BINDINGS[action]
		var motion_event := InputEventJoypadMotion.new()
		motion_event.device = Config.JOYPAD_DEVICE
		motion_event.axis = axis_binding[0]
		motion_event.axis_value = axis_binding[1]
		InputMap.action_add_event(action, motion_event)
