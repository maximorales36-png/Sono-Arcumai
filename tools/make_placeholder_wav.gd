# Herramienta temporal: genera los WAV de prueba (seno con decay) hasta que Maxi entregue samples.
# Dos por capa, con la misma raíz MIDI que config.gd: grave (filas de abajo) y agudo una octava arriba.
# Cada capa suma armónicos distintos para poder distinguirlas de oído.
# Se corre con: godot --headless --path . --script res://tools/make_placeholder_wav.gd
extends SceneTree

const SAMPLE_RATE := 44100
const DURATION_SECONDS := 2.0
const ATTACK_SECONDS := 0.01
const DECAY_RATE := 4.0
const AMPLITUDE := 0.8

# [nota raíz MIDI del sample grave, amplitudes de los armónicos 1..4]
const LAYERS := [
	[57, [1.0, 0.0, 0.0, 0.0]],
	[57, [1.0, 0.5, 0.0, 0.0]],
	[57, [1.0, 0.0, 0.35, 0.0]],
	[57, [1.0, 0.3, 0.2, 0.15]],
]


func _initialize() -> void:
	for layer_index: int in LAYERS.size():
		var root_midi: int = LAYERS[layer_index][0]
		var partials: Array = LAYERS[layer_index][1]
		var outputs := [
			["res://assets/samples/layer_%d_low.wav" % (layer_index + 1), root_midi],
			["res://assets/samples/layer_%d_high.wav" % (layer_index + 1), root_midi + 12],
		]
		for output: Array in outputs:
			var error := _write_sample(output[0], output[1], partials)
			if error != OK:
				push_error("[make_placeholder_wav] no se pudo escribir %s (error %d)" % [output[0], error])
				quit(1)
				return
			print("[make_placeholder_wav] escrito %s" % output[0])
	quit()


func _write_sample(sample_path: String, root_midi: int, partials: Array) -> int:
	var frame_count := int(SAMPLE_RATE * DURATION_SECONDS)
	var samples := PackedByteArray()
	samples.resize(frame_count * 2)

	var base_frequency_hz := _midi_to_hz(root_midi)
	var partial_total := 0.0
	for amplitude: float in partials:
		partial_total += amplitude

	for frame: int in frame_count:
		var time := float(frame) / float(SAMPLE_RATE)
		var attack := minf(time / ATTACK_SECONDS, 1.0)
		var decay := exp(-DECAY_RATE * time)
		var value := 0.0
		for partial_index: int in partials.size():
			var partial_frequency_hz := base_frequency_hz * float(partial_index + 1)
			var partial_amplitude: float = partials[partial_index]
			value += sin(TAU * partial_frequency_hz * time) * partial_amplitude
		value = value / partial_total * attack * decay * AMPLITUDE
		samples.encode_s16(frame * 2, int(value * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream.save_to_wav(sample_path)


func _midi_to_hz(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - 69) / 12.0)
