# Graba el gesto del joystick (cambios de dirección con su tiempo) y lo reproduce en bucle,
# alimentando una segunda instancia de FxDrive con su propio FxSet. Sin nodos ni audio.
# Depende de config.gd, state.gd y fx_drive.gd; main.gd le asigna el State y el FxDrive grabado.
class_name GestureDrive
extends RefCounted

var state: State
var fx_drive: FxDrive

var _recording: bool = false
var _record_start_usec: int = 0
var _record_mask: int = 0
var _record_events: Array[Array] = []

var _playback_start_usec: int = 0


func is_recording() -> bool:
	return _recording


func recorded_seconds(now_usec: int) -> float:
	if not _recording:
		return 0.0
	return float(now_usec - _record_start_usec) / 1_000_000.0


# Empieza a registrar desde este instante. El primer evento guarda la dirección actual.
func start_recording(now_usec: int, up: bool, down: bool, left: bool, right: bool) -> void:
	assert(state != null, "[gesture] falta el State: main.gd tiene que asignarlo antes de usarlo")
	assert(fx_drive != null, "[gesture] falta el FxDrive grabado")
	if _recording:
		return
	_recording = true
	_record_start_usec = now_usec
	_record_mask = _make_mask(up, down, left, right)
	_record_events = [[0.0, _record_mask]]
	state.gesture_is_recording = true
	state.gesture_remaining_seconds = Config.GESTURE_MAX_SECONDS
	print("[gesture] grabando")


# Cierra la grabación. Si no llegó al mínimo, se cancela y queda el gesto anterior.
func finish_recording(now_usec: int) -> void:
	if not _recording:
		return
	_recording = false
	state.gesture_is_recording = false
	state.gesture_remaining_seconds = 0.0

	var duration := minf(
		float(now_usec - _record_start_usec) / 1_000_000.0, Config.GESTURE_MAX_SECONDS
	)
	if duration < Config.GESTURE_MIN_SECONDS:
		print("[gesture] grabación cancelada: %.2f s" % duration)
		return

	var gesture := State.Gesture.new()
	gesture.duration_seconds = duration
	gesture.events = _record_events.duplicate(true)
	state.gesture = gesture
	# Arranca el bucle desde el principio del gesto nuevo.
	_playback_start_usec = now_usec
	print("[gesture] grabado: %.2f s, %d eventos" % [duration, gesture.events.size()])


func clear_gesture() -> void:
	state.gesture = null
	print("[gesture] gesto borrado")


# Captura los cambios de dirección y, en paralelo, sigue reproduciendo el gesto anterior.
# Se llama una vez por frame con el delta real.
func update(delta: float, now_usec: int, up: bool, down: bool, left: bool, right: bool) -> void:
	assert(state != null, "[gesture] falta el State: main.gd tiene que asignarlo antes de usarlo")
	assert(fx_drive != null, "[gesture] falta el FxDrive grabado")

	if _recording:
		_capture(now_usec, up, down, left, right)
		var elapsed := float(now_usec - _record_start_usec) / 1_000_000.0
		state.gesture_remaining_seconds = maxf(Config.GESTURE_MAX_SECONDS - elapsed, 0.0)
		if elapsed >= Config.GESTURE_MAX_SECONDS:
			finish_recording(now_usec)

	var mask := _playback_mask(now_usec)
	fx_drive.update(
		(mask & Config.GESTURE_DIR_UP) != 0,
		(mask & Config.GESTURE_DIR_DOWN) != 0,
		(mask & Config.GESTURE_DIR_LEFT) != 0,
		(mask & Config.GESTURE_DIR_RIGHT) != 0,
		delta
	)


func _capture(now_usec: int, up: bool, down: bool, left: bool, right: bool) -> void:
	var mask := _make_mask(up, down, left, right)
	if mask == _record_mask:
		return
	_record_mask = mask
	var elapsed := minf(
		float(now_usec - _record_start_usec) / 1_000_000.0, Config.GESTURE_MAX_SECONDS
	)
	_record_events.append([elapsed, mask])


# Dirección del gesto en el punto del bucle que toca ahora.
func _playback_mask(now_usec: int) -> int:
	var gesture := state.gesture
	if gesture == null or gesture.duration_seconds <= 0.0:
		return 0
	var elapsed := float(now_usec - _playback_start_usec) / 1_000_000.0
	var time := fmod(maxf(elapsed, 0.0), gesture.duration_seconds)

	var mask := 0
	for event: Array in gesture.events:
		if float(event[0]) > time:
			break
		mask = int(event[1])
	return mask


func _make_mask(up: bool, down: bool, left: bool, right: bool) -> int:
	var mask := 0
	if up:
		mask |= Config.GESTURE_DIR_UP
	if down:
		mask |= Config.GESTURE_DIR_DOWN
	if left:
		mask |= Config.GESTURE_DIR_LEFT
	if right:
		mask |= Config.GESTURE_DIR_RIGHT
	return mask
