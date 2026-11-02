# Convierte las direcciones de un joystick en los valores de un par de efectos globales:
# el wet sube mientras se mantiene la dirección vertical y el speed se mueve con la horizontal;
# al soltar, los dos vuelven al reposo. No toca audio ni nodos: solo datos.
# Depende de config.gd y de state.gd. La fase 2 va a usar una segunda instancia para el gesto grabado.
class_name FxDrive
extends RefCounted

var fx: State.FxSet

# Si cada efecto estaba mantenido en el frame anterior: sirve para el salto inicial del wet.
var _delay_was_held: bool = false
var _tremolo_was_held: bool = false


# Arriba/abajo encienden cada efecto; izquierda/derecha mueven su speed si están mantenidos.
# El delta es el tiempo real de este frame.
func update(up: bool, down: bool, left: bool, right: bool, delta: float) -> void:
	assert(fx != null, "[fx_drive] falta el FxSet: main.gd tiene que asignarlo antes de usarlo")
	var horizontal := 0
	if left and not right:
		horizontal = -1
	elif right and not left:
		horizontal = 1

	_delay_was_held = _step(fx.delay, up, horizontal, _delay_was_held, delta)
	_tremolo_was_held = _step(fx.tremolo, down, horizontal, _tremolo_was_held, delta)


# Devuelve si el efecto quedó mantenido, para detectar el comienzo en el frame siguiente.
func _step(unit: State.FxUnit, held: bool, horizontal: int, was_held: bool, delta: float) -> bool:
	if held:
		if not was_held:
			unit.wet = maxf(unit.wet, Config.FX_WET_START_JUMP)
		unit.wet = minf(unit.wet + delta / Config.FX_WET_RISE_SECONDS, 1.0)
		# Sin horizontal, el speed se queda donde está.
		if horizontal != 0:
			unit.speed = clampf(
				unit.speed + float(horizontal) * delta / Config.FX_SPEED_TO_EXTREME_SECONDS, -1.0, 1.0
			)
		return true

	unit.wet = maxf(unit.wet - delta / Config.FX_REST_SECONDS, 0.0)
	unit.speed = move_toward(unit.speed, 0.0, delta / Config.FX_REST_SECONDS)
	return false
