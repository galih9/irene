extends Node

var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback

const SAMPLE_RATE: float = 22050.0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = SAMPLE_RATE
	_generator.buffer_length = 0.2
	_player.stream = _generator
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

func play_pickup() -> void:
	_play_chirp(400.0, 650.0, 0.06, 0.25)

func play_drop() -> void:
	_play_tone(220.0, 0.06, 0.2, 0.8)

func play_merge() -> void:
	_play_chord([523.25, 659.25, 783.99], 0.22, 0.3)

func play_spawn() -> void:
	_play_chirp(300.0, 580.0, 0.08, 0.25)

func play_consume() -> void:
	_play_chirp(600.0, 950.0, 0.12, 0.3)

func play_quest() -> void:
	_play_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.08, 0.3)

func play_error() -> void:
	_play_buzz(130.0, 0.14, 0.25)

func _play_tone(freq: float, duration: float, volume: float = 0.3, decay: float = 1.0) -> void:
	if not _playback:
		return
	var frames := int(duration * SAMPLE_RATE)
	var available := _playback.get_frames_available()
	frames = mini(frames, available)
	var phase := 0.0
	var phase_step := TAU * freq / SAMPLE_RATE
	for i in range(frames):
		var env := pow(1.0 - float(i) / float(frames), decay) * volume
		var sample := sin(phase) * env
		_playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + phase_step, TAU)

func _play_chirp(start_freq: float, end_freq: float, duration: float, volume: float = 0.3) -> void:
	if not _playback:
		return
	var frames := int(duration * SAMPLE_RATE)
	var available := _playback.get_frames_available()
	frames = mini(frames, available)
	var phase := 0.0
	for i in range(frames):
		var t := float(i) / float(frames)
		var freq := lerpf(start_freq, end_freq, t)
		var env := (1.0 - t) * volume
		var sample := sin(phase) * env
		_playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + TAU * freq / SAMPLE_RATE, TAU)

func _play_buzz(freq: float, duration: float, volume: float = 0.3) -> void:
	if not _playback:
		return
	var frames := int(duration * SAMPLE_RATE)
	var available := _playback.get_frames_available()
	frames = mini(frames, available)
	var phase := 0.0
	var phase_step := TAU * freq / SAMPLE_RATE
	for i in range(frames):
		var env := (1.0 - float(i) / float(frames)) * volume
		# Square wave
		var sample := (1.0 if sin(phase) > 0.0 else -1.0) * env
		_playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + phase_step, TAU)

func _play_chord(frequencies: Array, duration: float, volume: float = 0.3) -> void:
	if not _playback:
		return
	var frames := int(duration * SAMPLE_RATE)
	var available := _playback.get_frames_available()
	frames = mini(frames, available)
	var phases: Array[float] = []
	phases.resize(frequencies.size())
	phases.fill(0.0)
	var vol_per_voice := volume / float(frequencies.size())

	for i in range(frames):
		var env := pow(1.0 - float(i) / float(frames), 0.7)
		var sample := 0.0
		for idx in range(frequencies.size()):
			var f: float = frequencies[idx]
			sample += sin(phases[idx]) * vol_per_voice * env
			phases[idx] = fmod(phases[idx] + TAU * f / SAMPLE_RATE, TAU)
		_playback.push_frame(Vector2(sample, sample))

func _play_arpeggio(frequencies: Array, note_duration: float, volume: float = 0.3) -> void:
	if not _playback:
		return
	for f in frequencies:
		_play_tone(f, note_duration, volume, 0.8)
