# Herramienta temporal: genera los WAV de prueba (seno con decay) hasta que Maxi entregue samples.
# Dos por capa: zona grave (MIDI 57, 220 Hz) y zona aguda (MIDI 69, 440 Hz).
# Se corre con: godot --headless --path . --script res://tools/make_placeholder_wav.gd
extends SceneTree

const SAMPLE_RATE := 44100
const DURATION_SECONDS := 2.0
const ATTACK_SECONDS := 0.01
const DECAY_RATE := 4.0
const AMPLITUDE := 0.8

const OUTPUTS := [
	["res://assets/samples/layer_1_low.wav", 220.0],
	["res://assets/samples/layer_1_high.wav", 440.0],
]


func _initialize() -> void:
	for output: Array in OUTPUTS:
		var sample_path: String = output[0]
		var frequency_hz: float = output[1]
		var error := _write_sample(sample_path, frequency_hz)
		if error != OK:
			push_error("[make_placeholder_wav] no se pudo escribir %s (error %d)" % [sample_path, error])
			quit(1)
			return
		print("[make_placeholder_wav] escrito %s" % sample_path)
	quit()


func _write_sample(sample_path: String, frequency_hz: float) -> int:
	var frame_count := int(SAMPLE_RATE * DURATION_SECONDS)
	var samples := PackedByteArray()
	samples.resize(frame_count * 2)

	for frame: int in frame_count:
		var time := float(frame) / float(SAMPLE_RATE)
		var attack := minf(time / ATTACK_SECONDS, 1.0)
		var decay := exp(-DECAY_RATE * time)
		var value := sin(TAU * frequency_hz * time) * attack * decay * AMPLITUDE
		samples.encode_s16(frame * 2, int(value * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream.save_to_wav(sample_path)
