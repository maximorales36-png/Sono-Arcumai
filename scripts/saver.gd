# Graba la salida de audio de la pieza en curso y la guarda en disco junto con el estado (JSON).
# Tope de 8 minutos para no crecer sin límite. Depende de config.gd y de state.gd;
# main.gd le asigna el State antes de agregarlo.
class_name Saver
extends Node

var state: State

var _master_index: int
var _record: AudioEffectRecord
var _record_effect_index: int
var _recording_active: bool = false
var _recording_start_usec: int


func _ready() -> void:
	assert(state != null, "[saver] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")
	_master_index = AudioServer.get_bus_index("Master")
	assert(_master_index >= 0, "[saver] no existe el bus Master")
	_start_recording()


func _process(_delta: float) -> void:
	if not _recording_active:
		return
	var elapsed_sec := float(Time.get_ticks_usec() - _recording_start_usec) / 1_000_000.0
	if elapsed_sec < Config.RECORDING_MAX_SECONDS:
		return
	_stop_recording()
	push_error(
		"[saver] tope de %.0f s de grabación alcanzado: se corta la grabación y la pieza sigue sonando"
		% Config.RECORDING_MAX_SECONDS
	)


# Guarda el WAV de lo grabado y el JSON del estado. Devuelve el nombre corto,
# o "" si ni siquiera se pudo escribir el JSON.
func save_piece() -> String:
	var directory := ProjectSettings.globalize_path(Config.SAVE_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(directory)
	if dir_error != OK:
		push_error("[saver] no se pudo crear %s (error %d)" % [directory, dir_error])
		return ""

	var piece_name := _make_unique_piece_name(directory)
	var wav_error := _save_wav(directory.path_join(piece_name + ".wav"))
	var json_error := _save_json(directory.path_join(piece_name + ".json"), piece_name)
	_start_recording()

	if json_error != OK:
		push_error("[saver] no se pudo guardar la pieza %s (error %d)" % [piece_name, json_error])
		return ""
	if wav_error != OK:
		push_error("[saver] la pieza %s se guardó sin WAV (error %d)" % [piece_name, wav_error])
	else:
		print("[saver] pieza guardada: %s en %s" % [piece_name, directory])
	return piece_name


# Descartar lo grabado y empezar de cero (reinicio por inactividad).
func restart_recording() -> void:
	_stop_recording()
	_start_recording()


func _start_recording() -> void:
	# Un efecto nuevo por tanda: al liberar el anterior se libera su buffer.
	_record = AudioEffectRecord.new()
	_record.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(_master_index, _record)
	_record_effect_index = AudioServer.get_bus_effect_count(_master_index) - 1
	_record.set_recording_active(true)
	_recording_active = true
	_recording_start_usec = Time.get_ticks_usec()


func _stop_recording() -> AudioStreamWAV:
	if not _recording_active:
		return null
	_record.set_recording_active(false)
	_recording_active = false
	var stream: AudioStreamWAV = _record.get_recording()
	AudioServer.remove_bus_effect(_master_index, _record_effect_index)
	_record = null
	return stream


func _save_wav(path: String) -> int:
	var stream := _stop_recording()
	if stream == null or stream.data.is_empty():
		push_error("[saver] no hay audio grabado para el WAV")
		return ERR_UNAVAILABLE
	return stream.save_to_wav(path)


func _save_json(path: String, piece_name: String) -> int:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(_state_as_dictionary(piece_name), "\t"))
	file.close()
	return OK


func _state_as_dictionary(piece_name: String) -> Dictionary:
	var layers_data: Array = []
	for layer: State.Layer in state.layers:
		var notes: Array = []
		for cell: Vector2i in layer.notes:
			notes.append([cell.x, cell.y])
		layers_data.append({
			"notes": notes,
			"cutoff_hz": layer.cutoff_hz,
			"reverb_wet": layer.reverb_wet,
			"attack_seconds": layer.attack_seconds,
			"decay_seconds": layer.decay_seconds,
		})
	return {
		"version": Config.SAVE_FORMAT_VERSION,
		"name": piece_name,
		"saved_at": Time.get_datetime_string_from_system(),
		"steps": Config.STEPS,
		"rows": Config.ROWS,
		"scale_semitones": Config.SCALE_SEMITONES,
		"grid_bottom_midi": Config.GRID_BOTTOM_MIDI,
		"tempo_scale": Config.TEMPO_SCALE,
		"layers": layers_data,
	}


# Nombre corto de dos palabras y un número, legible en pantalla. Si ya existe
# una pieza con ese nombre, prueba otro: no se pisa una pieza anterior.
func _make_unique_piece_name(directory: String) -> String:
	for _attempt: int in Config.SAVE_NAME_ATTEMPTS:
		var candidate := _make_piece_name()
		if (
			not FileAccess.file_exists(directory.path_join(candidate + ".json"))
			and not FileAccess.file_exists(directory.path_join(candidate + ".wav"))
		):
			return candidate
	push_error("[saver] no se encontró un nombre libre en %s: se pisa la pieza" % directory)
	return _make_piece_name()


func _make_piece_name() -> String:
	var first_index := randi() % Config.PIECE_NAME_WORDS.size()
	var second_index := randi() % Config.PIECE_NAME_WORDS.size()
	if second_index == first_index:
		second_index = (second_index + 1) % Config.PIECE_NAME_WORDS.size()
	return "%s-%s-%d" % [
		Config.PIECE_NAME_WORDS[first_index],
		Config.PIECE_NAME_WORDS[second_index],
		randi_range(10, 99),
	]
