extends Node

# --- Audio Settings ---
var bgm_enabled: bool = true
var sfx_enabled: bool = true

var bgm_volume_db: float = -12.0
var sfx_volume_db: float = -2.0

# --- Audio Players ---
var _bgm_player: AudioStreamPlayer
const SFX_POOL_SIZE: int = 8
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

# --- Preloaded Audio Assets ---
const BGM_PATH: String = "res://assets/bgm/bgm.mp3"

const STREAM_PICKUP: AudioStream = preload("res://assets/bgm/click3.ogg")
const STREAM_DROP: AudioStream = preload("res://assets/bgm/drop_001.ogg")
const STREAM_MERGE: AudioStream = preload("res://assets/bgm/glass_001.ogg")
const STREAM_SPAWN: AudioStream = preload("res://assets/bgm/drop_002.ogg")
const STREAM_CONSUME: AudioStream = preload("res://assets/bgm/confirmation_001.ogg")
const STREAM_QUEST: AudioStream = preload("res://assets/bgm/confirmation_002.ogg")
const STREAM_ERROR: AudioStream = preload("res://assets/bgm/error_004.ogg")
const STREAM_CLICK: AudioStream = preload("res://assets/bgm/click1.ogg")
const STREAM_OPEN: AudioStream = preload("res://assets/bgm/open_001.ogg")
const STREAM_CLOSE: AudioStream = preload("res://assets/bgm/close_001.ogg")

func _ready() -> void:
	# 1. Initialize BGM Player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	var bgm_stream := load(BGM_PATH)
	if bgm_stream is AudioStreamMP3:
		bgm_stream.loop = true
	_bgm_player.stream = bgm_stream
	_bgm_player.volume_db = bgm_volume_db
	add_child(_bgm_player)

	# 2. Initialize SFX Voice Pool
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.volume_db = sfx_volume_db
		add_child(player)
		_sfx_players.append(player)

	# 3. Start BGM if enabled
	if bgm_enabled:
		play_bgm()

# ==============================================================================
# BGM Management
# ==============================================================================

func play_bgm() -> void:
	if not _bgm_player or not bgm_enabled:
		return
	if not _bgm_player.playing:
		_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player and _bgm_player.playing:
		_bgm_player.stop()

func toggle_bgm() -> bool:
	set_bgm_enabled(not bgm_enabled)
	return bgm_enabled

func set_bgm_enabled(enabled: bool) -> void:
	bgm_enabled = enabled
	if not is_instance_valid(_bgm_player):
		return
	if bgm_enabled:
		play_bgm()
	else:
		stop_bgm()

func set_bgm_volume(vol_db: float) -> void:
	bgm_volume_db = vol_db
	if is_instance_valid(_bgm_player):
		_bgm_player.volume_db = bgm_volume_db

# ==============================================================================
# SFX Management
# ==============================================================================

func toggle_sfx() -> bool:
	sfx_enabled = not sfx_enabled
	return sfx_enabled

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled

func play_sfx(stream: AudioStream, volume_offset_db: float = 0.0, pitch_variance: float = 0.0) -> void:
	if not sfx_enabled or stream == null or _sfx_players.is_empty():
		return

	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()

	player.stream = stream
	player.volume_db = sfx_volume_db + volume_offset_db
	if pitch_variance > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	else:
		player.pitch_scale = 1.0
	player.play()

# Specific Gameplay Sound Events
func play_pickup() -> void:
	play_sfx(STREAM_PICKUP, 0.0, 0.04)

func play_drop() -> void:
	play_sfx(STREAM_DROP, 0.0, 0.04)

func play_merge() -> void:
	play_sfx(STREAM_MERGE, 1.5, 0.04)

func play_spawn() -> void:
	play_sfx(STREAM_SPAWN, 0.0, 0.03)

func play_consume() -> void:
	play_sfx(STREAM_CONSUME, 1.0, 0.03)

func play_quest() -> void:
	play_sfx(STREAM_QUEST, 2.0, 0.0)

func play_error() -> void:
	play_sfx(STREAM_ERROR, -1.0, 0.0)

func play_click() -> void:
	play_sfx(STREAM_CLICK, -2.0, 0.04)

func play_open() -> void:
	play_sfx(STREAM_OPEN, -1.0, 0.02)

func play_close() -> void:
	play_sfx(STREAM_CLOSE, -1.0, 0.02)
