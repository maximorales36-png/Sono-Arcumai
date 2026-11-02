# Efectos que afectan a las cuatro capas juntas: un delay con feedback y un tremolo.
# Crea el bus común "fx", hace que las capas pasen por él antes de Master y aplica
# lo que pide el State cada frame (incluidos los desvanecidos).
# Depende de config.gd y de state.gd; main.gd le asigna el State y lo agrega
# después del voice_pool, porque los buses de capa ya tienen que existir.
class_name GlobalFx
extends Node

var state: State

var _fx_index: int
var _delay: AudioEffectDelay
var _amplify: AudioEffectAmplify


func _ready() -> void:
	assert(state != null, "[global_fx] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")
	_create_bus()
	_create_effects()


# Cada capa deja de ir directo a Master y pasa por "fx".
func _create_bus() -> void:
	assert(
		AudioServer.get_bus_index(Config.FX_BUS_NAME) == -1,
		"[global_fx] ya existe el bus %s: no se agrega dos veces" % Config.FX_BUS_NAME
	)
	_fx_index = AudioServer.bus_count
	AudioServer.add_bus(_fx_index)
	AudioServer.set_bus_name(_fx_index, Config.FX_BUS_NAME)
	# Explícito: un bus nuevo no queda enviando a Master solo.
	AudioServer.set_bus_send(_fx_index, Config.MASTER_BUS_NAME)

	for layer: int in Config.LAYER_COUNT:
		var bus_name := Config.BUS_NAME_PREFIX + str(layer + 1)
		var bus_index := AudioServer.get_bus_index(bus_name)
		assert(
			bus_index >= 0,
			"[global_fx] no existe el bus %s: global_fx tiene que ir después del voice_pool" % bus_name
		)
		AudioServer.set_bus_send(bus_index, Config.FX_BUS_NAME)


func _create_effects() -> void:
	_delay = AudioEffectDelay.new()
	_delay.tap1_active = true
	_delay.tap2_active = false
	_delay.feedback_active = true
	_delay.feedback_lowpass = Config.DELAY_FEEDBACK_LOWPASS_HZ
	AudioServer.add_bus_effect(_fx_index, _delay)

	_amplify = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(_fx_index, _amplify)

	_apply()


func _process(delta: float) -> void:
	_fade(delta)
	_apply()


# Cada efecto entra rápido y se va lento, por separado.
func _fade(delta: float) -> void:
	var target_wet := Config.DELAY_WET if state.fx_mode == Config.GLOBAL_FX_DELAY else 0.0
	var target_depth := (
		state.tremolo_depth_setting if state.fx_mode == Config.GLOBAL_FX_TREMOLO else 0.0
	)
	state.delay_wet = move_toward(
		state.delay_wet, target_wet, delta / _fade_seconds(state.delay_wet, target_wet)
	)
	state.tremolo_depth = move_toward(
		state.tremolo_depth, target_depth, delta / _fade_seconds(state.tremolo_depth, target_depth)
	)


func _fade_seconds(current: float, target: float) -> float:
	return Config.GLOBAL_FX_FADE_OUT_SECONDS if target < current else Config.GLOBAL_FX_FADE_IN_SECONDS


# Lleva el State a los efectos del bus. El delay se apaga bajando el wet y subiendo el dry.
func _apply() -> void:
	_delay.dry = 1.0 - state.delay_wet
	_delay.tap1_delay_ms = state.delay_time_seconds * 1000.0
	_delay.tap1_level_db = linear_to_db(maxf(state.delay_wet, Config.SILENT_GAIN))
	_delay.feedback_delay_ms = _delay.tap1_delay_ms
	_delay.feedback_level_db = linear_to_db(maxf(state.delay_feedback, Config.SILENT_GAIN))

	# Tremolo: LFO libre, para que no dependa de cuándo se encendió.
	var phase := fmod(float(Time.get_ticks_usec()) / 1_000_000.0 * Config.TREMOLO_RATE_HZ, 1.0)
	var gain := 1.0 - state.tremolo_depth * (0.5 - 0.5 * cos(TAU * phase))
	_amplify.volume_db = linear_to_db(gain)
