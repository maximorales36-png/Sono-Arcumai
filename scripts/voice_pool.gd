# Reproduce los samples de la capa activa, uno grave y uno agudo según la fila,
# y la nota fantasma del cursor. Escucha step_entered y lee el State.
# Depende de config.gd y de state.gd.
class_name VoicePool
extends Node

const ZONE_LOW := 0
const ZONE_HIGH := 1
const ZONE_COUNT := 2

var state: State

var _streams: Array[AudioStream] = []
var _players: Array[Array] = []
var _next_player: Array[int] = []


func _ready() -> void:
	assert(state != null, "[voice_pool] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")
	assert(
		Config.SCALE_SEMITONES.size() == Config.ROWS,
		"[voice_pool] SCALE_SEMITONES tiene %d notas y la grilla %d filas" % [Config.SCALE_SEMITONES.size(), Config.ROWS]
	)
	for _zone: int in ZONE_COUNT:
		_streams.append(null)
		_players.append([])
		_next_player.append(0)
	_load_samples()
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
	var zone := zone_for_row(row)
	if _streams[zone] == null:
		return
	var players: Array = _players[zone]
	var player: AudioStreamPlayer = players[_next_player[zone]]
	_next_player[zone] = (_next_player[zone] + 1) % players.size()
	player.pitch_scale = pitch_scale_for_row(row)
	player.play()


# Filas de abajo: sample grave. Filas de arriba: sample agudo.
func zone_for_row(row: int) -> int:
	return ZONE_LOW if row >= Config.ZONE_SPLIT_ROW else ZONE_HIGH


# Transpone dentro de la zona: cada sample cubre como máximo diez semitonos.
func pitch_scale_for_row(row: int) -> float:
	var target_midi := Config.GRID_BOTTOM_MIDI + Config.SCALE_SEMITONES[Config.ROWS - 1 - row]
	var root_midi: int = Config.LAYER_SAMPLE_ROOT_MIDI[state.active_layer_index][zone_for_row(row)]
	return pow(2.0, float(target_midi - root_midi) / 12.0)


func _load_samples() -> void:
	var layer_paths: Array = Config.LAYER_SAMPLE_PATHS[state.active_layer_index]
	for zone: int in ZONE_COUNT:
		var sample_path: String = layer_paths[zone]
		if not ResourceLoader.exists(sample_path):
			push_error("[voice_pool] falta el sample %s: esa zona queda muda" % sample_path)
			continue
		_streams[zone] = load(sample_path) as AudioStream
		if _streams[zone] == null:
			push_error("[voice_pool] %s existe pero no se pudo cargar como AudioStream" % sample_path)


func _create_players() -> void:
	var voices_per_zone := Config.VOICE_COUNT / ZONE_COUNT
	for zone: int in ZONE_COUNT:
		for _voice: int in voices_per_zone:
			var player := AudioStreamPlayer.new()
			player.stream = _streams[zone]
			player.volume_db = Config.NOTE_VOLUME_DB
			add_child(player)
			_players[zone].append(player)
