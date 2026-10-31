# Reproduce el sample de la capa activa con la altura de cada fila y la nota fantasma del cursor.
# Escucha step_entered del sequencer y lee el State. Depende de config.gd y de state.gd.
class_name VoicePool
extends Node

var state: State

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _stream: AudioStream


func _ready() -> void:
	assert(state != null, "[voice_pool] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")
	assert(
		Config.SCALE_SEMITONES.size() == Config.ROWS,
		"[voice_pool] SCALE_SEMITONES tiene %d notas y la grilla %d filas" % [Config.SCALE_SEMITONES.size(), Config.ROWS]
	)
	_load_sample()
	_create_players()


# Las notas asentadas de la capa activa y la nota fantasma del cursor suenan al entrar el paso.
func play_step(layer: int, step: int) -> void:
	if layer != state.active_layer_index:
		return
	for cell: Vector2i in state.get_active_layer().notes:
		if cell.x == step:
			play_row(cell.y)
	if step == state.cursor_step:
		play_row(state.cursor_row)


func play_row(row: int) -> void:
	assert(row >= 0 and row < Config.ROWS, "[voice_pool] fila fuera de rango: %d" % row)
	if _stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.pitch_scale = _pitch_scale_for_row(row)
	player.play()


func _pitch_scale_for_row(row: int) -> float:
	var scale_index := Config.ROWS - 1 - row
	var semitones := Config.GRID_BOTTOM_MIDI + Config.SCALE_SEMITONES[scale_index] - Config.SAMPLE_ROOT_MIDI
	return pow(2.0, float(semitones) / 12.0)


func _load_sample() -> void:
	var sample_path: String = Config.LAYER_SAMPLE_PATHS[state.active_layer_index]
	if not ResourceLoader.exists(sample_path):
		push_error("[voice_pool] falta el sample %s: esa capa queda muda" % sample_path)
		return
	_stream = load(sample_path) as AudioStream
	if _stream == null:
		push_error("[voice_pool] %s existe pero no se pudo cargar como AudioStream" % sample_path)


func _create_players() -> void:
	for _voice: int in Config.VOICE_COUNT:
		var player := AudioStreamPlayer.new()
		player.stream = _stream
		player.volume_db = Config.NOTE_VOLUME_DB
		add_child(player)
		_players.append(player)
