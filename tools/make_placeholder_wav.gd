# Herramienta temporal: genera un WAV de prueba (seno con decay) hasta que Maxi entregue samples.
# Se corre con: godot --headless --path . --script res://tools/make_placeholder_wav.gd
extends SceneTree

const OUTPUT_PATH := "res://assets/samples/layer_1.wav"
const SAMPLE_RATE := 44100
const DURATION_SECONDS := 2.0
const FREQUENCY_HZ := 220.0
const ATTACK_SECONDS := 0.01
const DECAY_RATE := 4.0
const AMPLITUDE := 0.8


func _initialize() -> void:
	var frame_count := int(SAMPLE_RATE * DURATION_SECONDS)
	var samples := PackedByteArray()
	samples.resize(frame_count * 2)

	for frame: int in frame_count:
		var time := float(frame) / float(SAMPLE_RATE)
		var attack := minf(time / ATTACK_SECONDS, 1.0)
		var decay := exp(-DECAY_RATE * time)
		var value := sin(TAU * FREQUENCY_HZ * time) * attack * decay * AMPLITUDE
		samples.encode_s16(frame * 2, int(value * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples

	var error := stream.save_to_wav(OUTPUT_PATH)
	if error != OK:
		push_error("[make_placeholder_wav] no se pudo escribir %s (error %d)" % [OUTPUT_PATH, error])
		quit(1)
		return

	print("[make_placeholder_wav] escrito %s" % OUTPUT_PATH)
	quit()
