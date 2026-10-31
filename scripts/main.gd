# S0: esqueleto. Registra las acciones del InputMap, muestra en pantalla qué acciones
# están apretadas y dispara un sonido con btn1. Este HUD es temporal: en S1 lo reemplaza view.gd.
# Depende de config.gd.
extends Node2D

const SAMPLE_PATH := "res://assets/samples/layer_1.wav"

const DEBUG_FONT_SIZE := 28
const DEBUG_MARGIN := Vector2(48.0, 80.0)
const DEBUG_LINE_HEIGHT := 34.0
const DEBUG_COLOR_IDLE := Color(0.45, 0.45, 0.45)
const DEBUG_COLOR_PRESSED := Color(1.0, 0.9, 0.4)

var _audio_player: AudioStreamPlayer
var _play_count: int = 0


func _enter_tree() -> void:
	# Antes de que cualquier script lea input.
	_register_input_actions()
	print("[main] InputMap listo: %d acciones" % Config.ACTIONS.size())


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_setup_audio()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(Config.ACTION_BTN1):
		_play_sample()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Esc cierra solo en builds de debug: en el arcade no existe esa salida.
	if not OS.is_debug_build():
		return
	if event.is_action_pressed(Config.ACTION_QUIT_DEBUG):
		get_tree().quit()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text_position := DEBUG_MARGIN
	for action: StringName in Config.ACTIONS:
		if action == Config.ACTION_QUIT_DEBUG:
			continue
		var pressed := Input.is_action_pressed(action)
		var marker := "APRETADA" if pressed else "-"
		var color := DEBUG_COLOR_PRESSED if pressed else DEBUG_COLOR_IDLE
		var text := "%s  %s" % [String(action), marker]
		draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, DEBUG_FONT_SIZE, color)
		text_position.y += DEBUG_LINE_HEIGHT
	var counter_text := "btn1 sonó %d veces" % _play_count
	draw_string(font, text_position, counter_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, DEBUG_FONT_SIZE, DEBUG_COLOR_IDLE)


func _setup_audio() -> void:
	if not ResourceLoader.exists(SAMPLE_PATH):
		push_error("[main] falta el sample %s: btn1 no va a sonar. Corré tools/make_placeholder_wav.gd" % SAMPLE_PATH)
		return
	var stream := load(SAMPLE_PATH) as AudioStream
	if stream == null:
		push_error("[main] %s existe pero no se pudo cargar como AudioStream" % SAMPLE_PATH)
		return
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = stream
	add_child(_audio_player)


func _play_sample() -> void:
	if _audio_player == null:
		return
	_audio_player.play()
	_play_count += 1


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
