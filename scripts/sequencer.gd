# Calcula la posición de la línea de barrido de cada capa desde el reloj real.
# Emite step_entered(layer, step) cuando la línea entra en un paso nuevo.
# Depende de config.gd. No conoce el estado ni el audio.
class_name Sequencer
extends Node

signal step_entered(layer: int, step: int)

var _origin_usec: int
var _last_step: Array[int] = []


func _ready() -> void:
	assert(
		Config.LAYER_PERIOD_SECONDS.size() == Config.LAYER_COUNT,
		"[sequencer] LAYER_PERIOD_SECONDS tiene %d períodos y hay %d capas" % [Config.LAYER_PERIOD_SECONDS.size(), Config.LAYER_COUNT]
	)
	assert(Config.TEMPO_SCALE > 0.0, "[sequencer] TEMPO_SCALE tiene que ser mayor que cero")
	_origin_usec = Time.get_ticks_usec()
	for _layer: int in Config.LAYER_COUNT:
		_last_step.append(-1)


func _process(_delta: float) -> void:
	for layer: int in Config.LAYER_COUNT:
		var step := int(get_phase(layer))
		if step == _last_step[layer]:
			continue
		_last_step[layer] = step
		step_entered.emit(layer, step)


# Posición de la línea en pasos (0 a STEPS, con decimales). Se calcula siempre desde
# el instante de origen, así no se acumula error por frame.
func get_phase(layer: int) -> float:
	assert(layer >= 0 and layer < Config.LAYER_COUNT, "[sequencer] capa fuera de rango: %d" % layer)
	var elapsed_sec := float(Time.get_ticks_usec() - _origin_usec) / 1_000_000.0
	var period_sec: float = Config.LAYER_PERIOD_SECONDS[layer] / Config.TEMPO_SCALE
	return fposmod(elapsed_sec / period_sec, 1.0) * float(Config.STEPS)
