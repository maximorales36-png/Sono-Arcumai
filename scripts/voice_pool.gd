# Reproduce las notas de todas las capas con el sample grave o agudo según la fila,
# y la nota fantasma del cursor en la capa activa. Escucha step_entered y lee el State.
# Depende de config.gd y de state.gd.
class_name VoicePool
extends Node

const ZONE_LOW := 0
const ZONE_HIGH := 1
const ZONE_COUNT := 2

var state: State

# Índices: [capa][zona]. Cada zona tiene su stream y su lista de voces en round-robin.
var _streams: Array = []
var _players: Array = []
var _next_player: Array = []


func _ready() -> void:
	assert(state != null, "[voice_pool] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")
	assert(
		Config.SCALE_SEMITONES.size() == Config.ROWS,
		"[voice_pool] SCALE_SEMITONES tiene %d notas y la grilla %d filas" % [Config.SCALE_SEMITONES.size(), Config.ROWS]
	)
	assert(
		Config.LAYER_SAMPLE_PATHS.size() == Config.LAYER_COUNT,
		"[voice_pool] LAYER_SAMPLE_PATHS tiene %d capas y LAYER_COUNT es %d" % [Config.LAYER_SAMPLE_PATHS.size(), Config.LAYER_COUNT]
	)
	assert(
		Config.LAYER_SAMPLE_ROOT_MIDI.size() == Config.LAYER_COUNT,
		"[voice_pool] LAYER_SAMPLE_ROOT_MIDI tiene %d capas y LAYER_COUNT es %d" % [Config.LAYER_SAMPLE_ROOT_MIDI.size(), Config.LAYER_COUNT]
	)
	_load_samples()
	_create_players()


# Suenan las notas de la capa que entra al paso; la nota fantasma, solo en la capa activa.
func play_step(layer: int, step: int) -> void:
	assert(layer >= 0 and layer < Config.LAYER_COUNT, "[voice_pool] capa fuera de rango: %d" % layer)
	for cell: Vector2i in state.layers[layer].notes:
		if cell.x == step:
			play_row(layer, cell.y)
	# La nota fantasma no suena en la vista de todas las capas: no hay capa activa.
	if not state.show_all_layers and layer == state.active_layer_index and step == state.cursor_step:
		play_row(layer, state.cursor_row)


func play_row(layer: int, row: int) -> void:
	assert(layer >= 0 and layer < Config.LAYER_COUNT, "[voice_pool] capa fuera de rango: %d" % layer)
	assert(row >= 0 and row < Config.ROWS, "[voice_pool] fila fuera de rango: %d" % row)
	var zone := zone_for_row(row)
	if _streams[layer][zone] == null:
		return
	var players: Array = _players[layer][zone]
	var voice_index: int = _next_player[layer][zone]
	_next_player[layer][zone] = (voice_index + 1) % players.size()
	var player: AudioStreamPlayer = players[voice_index]
	player.pitch_scale = pitch_scale_for_row(layer, row)
	player.play()


# Al cambiar de capa, la fila del cursor suena enseguida con el timbre nuevo.
func play_cursor_preview(layer: int) -> void:
	play_row(layer, state.cursor_row)


# Filas de abajo: sample grave. Filas de arriba: sample agudo.
func zone_for_row(row: int) -> int:
	return ZONE_LOW if row >= Config.ZONE_SPLIT_ROW else ZONE_HIGH


# Transpone dentro de la zona: cada sample cubre como máximo diez semitonos.
func pitch_scale_for_row(layer: int, row: int) -> float:
	var target_midi := Config.GRID_BOTTOM_MIDI + Config.SCALE_SEMITONES[Config.ROWS - 1 - row]
	var root_midi: int = Config.LAYER_SAMPLE_ROOT_MIDI[layer][zone_for_row(row)]
	return pow(2.0, float(target_midi - root_midi) / 12.0)


func _load_samples() -> void:
	for layer: int in Config.LAYER_COUNT:
		_streams.append([])
		var layer_paths: Array = Config.LAYER_SAMPLE_PATHS[layer]
		for zone: int in ZONE_COUNT:
			var sample_path: String = layer_paths[zone]
			var stream: AudioStream = null
			if not ResourceLoader.exists(sample_path):
				push_error("[voice_pool] falta el sample %s: esa zona queda muda" % sample_path)
			else:
				stream = load(sample_path) as AudioStream
				if stream == null:
					push_error("[voice_pool] %s existe pero no se pudo cargar como AudioStream" % sample_path)
			_streams[layer].append(stream)


func _create_players() -> void:
	var voices_per_zone := Config.VOICE_COUNT / ZONE_COUNT
	for layer: int in Config.LAYER_COUNT:
		_players.append([])
		_next_player.append([])
		for zone: int in ZONE_COUNT:
			var zone_players: Array[AudioStreamPlayer] = []
			for _voice: int in voices_per_zone:
				var player := AudioStreamPlayer.new()
				player.stream = _streams[layer][zone]
				player.volume_db = Config.NOTE_VOLUME_DB
				add_child(player)
				zone_players.append(player)
			_players[layer].append(zone_players)
			_next_player[layer].append(0)
