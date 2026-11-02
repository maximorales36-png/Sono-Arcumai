# Efectos que afectan a las cuatro capas juntas: un delay y un trémolo sobre un bus común.
# Crea el bus "fx", manda ahí los buses de capa y lleva al audio el wet y el speed de State.live_fx
# (tiempo del delay y velocidad del trémolo). La lógica de gestos vive en fx_drive.gd.
# Depende de config.gd y de state.gd; main.gd le asigna el State y lo agrega después del voice_pool,
# porque los buses de capa ya tienen que existir.
class_name GlobalFx
extends Node

var state: State

var _fx_index: int
var _delay: AudioEffectDelay
var _amplify: AudioEffectAmplify
# Fase del LFO del trémolo. Se acumula para que no salte cuando cambia la velocidad.
var _lfo_phase: float = 0.0


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
	_delay.feedback_level_db = linear_to_db(Config.DELAY_FEEDBACK)
	AudioServer.add_bus_effect(_fx_index, _delay)

	_amplify = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(_fx_index, _amplify)

	_apply(0.0)


func _process(delta: float) -> void:
	_apply(delta)


func _apply(delta: float) -> void:
	var delay: State.FxUnit = state.live_fx.delay
	var tremolo: State.FxUnit = state.live_fx.tremolo

	# Delay: wet 0 deja pasar la señal seca; wet 1 la reemplaza por los ecos.
	_delay.dry = 1.0 - delay.wet
	_delay.tap1_delay_ms = _geometric(
		Config.DELAY_TIME_SLOW_MS, Config.DELAY_TIME_CENTER_MS, Config.DELAY_TIME_FAST_MS, delay.speed
	)
	_delay.tap1_level_db = linear_to_db(maxf(delay.wet, Config.SILENT_GAIN))
	_delay.feedback_delay_ms = _delay.tap1_delay_ms

	# Trémolo: wet es la profundidad (0 = sin cambio, 1 = corta del todo).
	var rate_hz := _geometric(
		Config.TREMOLO_RATE_SLOW_HZ,
		Config.TREMOLO_RATE_CENTER_HZ,
		Config.TREMOLO_RATE_FAST_HZ,
		tremolo.speed
	)
	_lfo_phase = fmod(_lfo_phase + delta * rate_hz, 1.0)
	var gain := 1.0 - tremolo.wet * (0.5 - 0.5 * cos(TAU * _lfo_phase))
	_amplify.volume_db = linear_to_db(maxf(gain, Config.SILENT_GAIN))


# Tres puntos en escala geométrica: -1 → lento, 0 → centro, +1 → rápido.
func _geometric(slow: float, center: float, fast: float, speed: float) -> float:
	if speed < 0.0:
		return center * pow(slow / center, -speed)
	return center * pow(fast / center, speed)
