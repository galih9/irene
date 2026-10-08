extends Node

# --- Audio Settings ---
var bgm_enabled: bool = true
var sfx_enabled: bool = false

var bgm_volume_db: float = -12.0
var sfx_volume_db: float = -2.0

# --- Audio Players ---
var _bgm_player: AudioStreamPlayer
const SFX_POOL_SIZE: int = 8
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

# --- Preloaded & Configured Audio Assets ---
const BGM_MENU: String = "res://assets/background/ambient.mp3"
const BGM_KITCHEN: String = "res://assets/background/kitchen.mp3"
const BGM_FARM: String = "res://assets/background/farm.mp3"
const BGM_WITCH: String = "res://assets/background/witch.mp3"

var current_bgm_track: String = ""
var _cached_bgm_streams: Dictionary = {}

const STREAM_CLICK: AudioStream = preload("res://assets/sfx/click.mp3")
const STREAM_OPEN: AudioStream = preload("res://assets/sfx/popup_open.mp3")
const STREAM_CLOSE: AudioStream = preload("res://assets/sfx/popup_close.mp3")
const STREAM_SPAWN: AudioStream = preload("res://assets/sfx/spawn.mp3")
const STREAM_SPAWN_SPRAY: AudioStream = preload("res://assets/sfx/spawnspray.mp3")
const STREAM_TOAST: AudioStream = preload("res://assets/sfx/toast.mp3")
const STREAM_BUBBLE: AudioStream = preload("res://assets/sfx/bubble.mp3")
const STREAM_ATTENTION: AudioStream = preload("res://assets/sfx/attention.mp3")
const STREAM_POURING: AudioStream = preload("res://assets/sfx/pouring.mp3")
const STREAM_FABRIC_ROLL: AudioStream = preload("res://assets/sfx/fabric_roll.mp3")
const STREAM_CONSTRUCTION: AudioStream = preload("res://assets/sfx/construction.mp3")
const STREAM_INTRO: AudioStream = preload("res://assets/sfx/intro.mp3")

const STREAM_PICKUP: AudioStream = STREAM_BUBBLE
const STREAM_DROP: AudioStream = STREAM_BUBBLE
const STREAM_MERGE: AudioStream = STREAM_BUBBLE
const STREAM_CONSUME: AudioStream = STREAM_BUBBLE
const STREAM_QUEST: AudioStream = STREAM_ATTENTION
const STREAM_ERROR: AudioStream = STREAM_ATTENTION
const STREAM_BUY: AudioStream = STREAM_CLICK
const STREAM_COIN_TICK: AudioStream = STREAM_CLICK

# Distinct merge sounds mapped by chain ID
const CHAIN_MERGE_SOUNDS: Dictionary = {}

func _ready() -> void:
	# 1. Initialize BGM Player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.volume_db = bgm_volume_db
	var initial_stream := get_bgm_stream(BGM_MENU)
	_bgm_player.stream = initial_stream
	current_bgm_track = BGM_MENU
	add_child(_bgm_player)

	# 2. Initialize SFX Voice Pool
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.volume_db = sfx_volume_db
		add_child(player)
		_sfx_players.append(player)

	# 3. Start BGM if enabled and not booting to splash screen
	var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if bgm_enabled and not main_scene_path.ends_with("splash_screen.tscn"):
		play_bgm(BGM_MENU)

# ==============================================================================
# BGM Management
# ==============================================================================

func get_bgm_stream(track_path: String) -> AudioStream:
	if _cached_bgm_streams.has(track_path):
		return _cached_bgm_streams[track_path]
	if ResourceLoader.exists(track_path):
		var stream := load(track_path)
		if stream is AudioStreamMP3:
			stream.loop = true
		_cached_bgm_streams[track_path] = stream
		return stream
	return null

func resolve_bgm_track(track_identifier: String) -> String:
	match track_identifier.to_lower():
		"menu", "ambient", "main_menu":
			return BGM_MENU
		"kitchen", "kitchen_board":
			return BGM_KITCHEN
		"farm", "farm_board":
			return BGM_FARM
		"witch", "witch_board":
			return BGM_WITCH
		"":
			return current_bgm_track if not current_bgm_track.is_empty() else BGM_MENU
		_:
			return track_identifier

func play_bgm(track: String = "") -> void:
	if not is_instance_valid(_bgm_player):
		return

	var resolved_path := resolve_bgm_track(track)
	if resolved_path.is_empty():
		resolved_path = BGM_MENU

	var stream := get_bgm_stream(resolved_path)
	if stream == null:
		push_warning("SoundManager: Failed to load BGM track: %s" % resolved_path)
		return

	if _bgm_player.stream == stream and _bgm_player.playing:
		return

	_bgm_player.stream = stream
	current_bgm_track = resolved_path

	if bgm_enabled:
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
		play_bgm(current_bgm_track)
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

func play_sfx(stream: AudioStream, volume_offset_db: float = 0.0, pitch_variance: float = 0.0, base_pitch: float = 1.0) -> void:
	if not sfx_enabled or stream == null or _sfx_players.is_empty():
		return

	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()

	player.stream = stream
	player.volume_db = sfx_volume_db + volume_offset_db
	if pitch_variance > 0.0:
		player.pitch_scale = base_pitch * randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	else:
		player.pitch_scale = base_pitch
	player.play()

# Specific Gameplay Sound Events
func play_pickup() -> void:
	play_sfx(STREAM_PICKUP, 0.0, 0.04)

func play_drop() -> void:
	play_sfx(STREAM_DROP, 0.0, 0.04)

func play_merge(item_data: ItemData = null) -> void:
	var stream: AudioStream = STREAM_MERGE
	var tier: int = 1
	if item_data != null:
		tier = item_data.tier
		if item_data.merge_sound != null:
			stream = item_data.merge_sound
		elif CHAIN_MERGE_SOUNDS.has(item_data.chain_id):
			stream = CHAIN_MERGE_SOUNDS[item_data.chain_id]

	# Higher tiers produce higher pitch for a delightful progression feel
	var pitch: float = 1.0 + float(tier - 1) * 0.06
	play_sfx(stream, 1.5, 0.03, pitch)

func play_merge_tier(tier: int = 1) -> void:
	var pitch: float = 1.0 + float(tier - 1) * 0.06
	play_sfx(STREAM_MERGE, 1.5, 0.03, pitch)

func play_merge_high() -> void:
	play_merge_tier(6)

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

func play_dialogue_blip() -> void:
	play_sfx(STREAM_CLICK, -7.0, 0.12, 1.4)

func play_buy() -> void:
	play_sfx(STREAM_BUY, 1.0, 0.03)

func play_token_arrival(pitch: float = 1.0) -> void:
	play_sfx(STREAM_COIN_TICK, -2.0, 0.0, pitch)

func play_spawnspray() -> void:
	play_sfx(STREAM_SPAWN_SPRAY, 0.0, 0.03)

func play_toast() -> void:
	play_sfx(STREAM_TOAST, 0.0, 0.0)

func play_pouring() -> void:
	play_sfx(STREAM_POURING, 0.0, 0.02)

func play_fabric_roll() -> void:
	play_sfx(STREAM_FABRIC_ROLL, 0.0, 0.02)

func play_attention() -> void:
	play_sfx(STREAM_ATTENTION, 0.0, 0.0)
