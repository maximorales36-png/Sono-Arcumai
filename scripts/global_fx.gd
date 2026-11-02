# Efectos que afectan a las cuatro capas juntas: un delay y un trémolo sobre el bus Master.
# No usa un bus propio porque en este Godot un envío cambiado después de crear los buses de capa
# no llega al audio (medido en S-FX fase 2: los picos quedaban en Master, saltando el bus "fx").
# Lleva al audio el wet y el speed de State.live_fx; la lógica de gestos vive en fx_drive.gd.
# Depende de config.gd y de state.gd. main.gd lo agrega antes del saver, así el AudioEffectRecord
# de Master graba ya con los efectos.
class_name GlobalFx
extends Node

var state: State

var _master_index: int
var _delay: AudioEffectDelay
var _amplify: AudioEffectAmplify
# Fase del LFO del trémolo. Se acumula para que no salte cuando cambia la velocidad.
var _lfo_phase: float = 0.0

# Tiempo del delay que está puesto en el audio, y control del cambio: el tiempo solo se aplica
# cuando el speed dejó de moverse y el tap está apagado (ver _update_delay_time()).
var _applied_tap_ms: float = Config.DELAY_TIME_CENTER_MS
var _last_speed: float = 0.0
var _settle_seconds: float = 0.0
var _duck_seconds: float = 0.0
var _change_pending: bool = false
var _tap_gate: float = 1.0


func _ready() -> void:
	assert(state != null, "[global_fx] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")
	_master_index = AudioServer.get_bus_index(Config.MASTER_BUS_NAME)
	assert(_master_index >= 0, "[global_fx] no existe el bus %s" % Config.MASTER_BUS_NAME)
	_create_effects()


func _create_effects() -> void:
	_delay = AudioEffectDelay.new()
	_delay.tap1_active = true
	_delay.tap1_delay_ms = _applied_tap_ms
	_delay.tap2_active = false
	_delay.feedback_active = true
	_delay.feedback_delay_ms = _applied_tap_ms
	_delay.feedback_lowpass = Config.DELAY_FEEDBACK_LOWPASS_HZ
	_delay.feedback_level_db = linear_to_db(Config.DELAY_FEEDBACK)
	AudioServer.add_bus_effect(_master_index, _delay)

	_amplify = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(_master_index, _amplify)

	_apply(0.0)


func _process(delta: float) -> void:
	_apply(delta)


func _apply(delta: float) -> void:
	var delay: State.FxUnit = state.live_fx.delay
	var tremolo: State.FxUnit = state.live_fx.tremolo

	# Compuerta del tap: se cierra al cambiar el tiempo del delay y se vuelve a abrir sola.
	_tap_gate = move_toward(
		_tap_gate, 0.0 if _duck_seconds > 0.0 else 1.0, delta / Config.DELAY_TIME_FADE_SECONDS
	)
	_update_delay_time(
		_geometric(
			Config.DELAY_TIME_SLOW_MS, Config.DELAY_TIME_CENTER_MS, Config.DELAY_TIME_FAST_MS, delay.speed
		),
		delay.speed,
		delta,
		delay.wet
	)

	# Delay: wet 0 deja pasar la señal seca; wet 1 la reemplaza por los ecos. Con la compuerta
	# cerrada pasa solo la señal seca, así el salto de tiempo no se escucha.
	var wet := delay.wet * _tap_gate
	_delay.dry = 1.0 - wet
	_delay.tap1_level_db = linear_to_db(maxf(wet, Config.SILENT_GAIN))
	# El feedback va con el wet: en reposo no queda ninguna cola sonando.
	_delay.feedback_level_db = linear_to_db(maxf(Config.DELAY_FEEDBACK * wet, Config.SILENT_GAIN))

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


# Pone el tiempo nuevo solo cuando el speed lleva quieto un momento y el tap ya se apagó.
# Mover el tiempo en marcha salta la lectura del buffer del delay: es el click que se escuchaba.
func _update_delay_time(target_ms: float, speed: float, delta: float, wet: float) -> void:
	if not is_equal_approx(speed, _last_speed):
		# Se está moviendo: se descarta el tiempo nuevo y se sigue con el que está puesto.
		_last_speed = speed
		_settle_seconds = 0.0
	elif _settle_seconds < Config.DELAY_TIME_SETTLE_SECONDS:
		_settle_seconds += delta

	# El buffer de feedback no pasa por el nivel del tap: moverle el tiempo con el efecto sonando
	# salta la lectura. Se lo resincroniza con el tap solo en reposo, cuando ya está en silencio.
	if wet <= Config.DELAY_FEEDBACK_SYNC_WET and absf(_delay.feedback_delay_ms - _applied_tap_ms) > 1.0:
		_delay.feedback_delay_ms = _applied_tap_ms

	if _duck_seconds > 0.0:
		_duck_seconds -= delta
		if _change_pending and _tap_gate <= 0.01:
			_applied_tap_ms = target_ms
			_delay.tap1_delay_ms = _applied_tap_ms
			_change_pending = false
		return

	if _settle_seconds >= Config.DELAY_TIME_SETTLE_SECONDS and absf(target_ms - _applied_tap_ms) > 1.0:
		_duck_seconds = Config.DELAY_TIME_DUCK_SECONDS
		_change_pending = true


# Tres puntos en escala geométrica: -1 → lento, 0 → centro, +1 → rápido.
func _geometric(slow: float, center: float, fast: float, speed: float) -> float:
	if speed < 0.0:
		return center * pow(slow / center, -speed)
	return center * pow(fast / center, speed)
