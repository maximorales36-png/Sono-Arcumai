# S1: registra el InputMap, crea el estado y los módulos, y conecta el cableado.
# Depende de config.gd, state.gd, controller.gd y view.gd.
extends Node2D

var _state: State
var _controller: Controller
var _view: View


func _enter_tree() -> void:
	# Antes de que cualquier script lea input.
	_register_input_actions()
	print("[main] InputMap listo: %d acciones" % Config.ACTIONS.size())


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	_state = State.new()

	_controller = Controller.new()
	_controller.state = _state
	add_child(_controller)

	_view = View.new()
	_view.state = _state
	add_child(_view)


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
