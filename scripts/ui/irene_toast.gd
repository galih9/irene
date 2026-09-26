class_name IreneToast
extends Control

@onready var panel: PanelContainer = $Panel
@onready var avatar_rect: TextureRect = $Panel/Margin/HBox/AvatarContainer/Avatar
@onready var tag_label: Label = $Panel/Margin/HBox/TextVBox/TagLabel
@onready var message_label: Label = $Panel/Margin/HBox/TextVBox/MessageLabel

const EMOTIONS: Dictionary = {
	"greeting": preload("res://assets/characters/irene/greeting.png"),
	"explain": preload("res://assets/characters/irene/explain.png"),
	"happy": preload("res://assets/characters/irene/happy.png"),
	"thinking": preload("res://assets/characters/irene/thinking.png"),
	"shocked": preload("res://assets/characters/irene/shocked.png"),
	"admire": preload("res://assets/characters/irene/admire.png")
}

const IVAN_EMOTIONS: Dictionary = {
	"greeting": preload("res://assets/characters/ivan/greeting.png"),
	"explain": preload("res://assets/characters/ivan/explain.png"),
	"happy": preload("res://assets/characters/ivan/excited.png"),
	"thinking": preload("res://assets/characters/ivan/confused.png"),
	"shocked": preload("res://assets/characters/ivan/shocked.png"),
	"admire": preload("res://assets/characters/ivan/excited.png")
}

const IVY_EMOTIONS: Dictionary = {
	"greeting": preload("res://assets/characters/ivy/greeting.png"),
	"explain": preload("res://assets/characters/ivy/explain.png"),
	"happy": preload("res://assets/characters/ivy/congratulate.png"),
	"thinking": preload("res://assets/characters/ivy/explain.png"),
	"shocked": preload("res://assets/characters/ivy/shocked.png"),
	"admire": preload("res://assets/characters/ivy/admire.png")
}

var _anim_tween: Tween = null
var _original_y: float = 0.0

# Ambient tips pool to make game feel alive
const AMBIENT_TIPS: Array[Dictionary] = [
	{
		"text": "Merge items to higher tiers before tapping them for maximum rewards!",
		"emotion": "explain"
	},
	{
		"text": "Running low on board space? Stash valuable items in your backpack below!",
		"emotion": "thinking"
	},
	{
		"text": "Chests upgrade and recharge when merged before their charges run out!",
		"emotion": "happy"
	},
	{
		"text": "Purple chests give EXP, Green restores Energy, Yellow grants Gold, and Blue gives Diamonds!",
		"emotion": "admire"
	},
	{
		"text": "Complete customer orders at the top to earn gold, gems, and level up!",
		"emotion": "greeting"
	},
	{
		"text": "Spawners enter cooldown when exhausted. Keep an eye on the recharge timer!",
		"emotion": "explain"
	},
	{
		"text": "Drag unwanted items to the Sell Bin at the bottom right to earn quick gold!",
		"emotion": "happy"
	}
]

const FARM_AMBIENT_TIPS: Array[Dictionary] = [
	{
		"text": "Merge barn foundations to build a functioning Barn spawner!",
		"emotion": "explain"
	},
	{
		"text": "Animals need full feed before they can be merged or tapped for goods!",
		"emotion": "thinking"
	},
	{
		"text": "Collect fresh milk from cows, wool from sheep, and eggs from chickens!",
		"emotion": "happy"
	},
	{
		"text": "Boost apple and orange trees to harvest delicious orchard produce!",
		"emotion": "admire"
	}
]

const WITCH_AMBIENT_TIPS: Array[Dictionary] = [
	{
		"text": "Feed ingredients into Cauldrons to brew magical potions and summon familiars!",
		"emotion": "explain"
	},
	{
		"text": "Familiars cannot be merged or sold, but you can sacrifice them to Candles or Mystic Trees!",
		"emotion": "admire"
	},
	{
		"text": "Drag Nature, Water, or Wind potions onto spawner trees or cauldrons to remove their cooldowns!",
		"emotion": "happy"
	},
	{
		"text": "Tap Candle Lv.6 to summon Brooms and uncover ancient Spellbooks!",
		"emotion": "greeting"
	},
	{
		"text": "Mystic Trees level 3 and above awaken magical essence to produce Shrooms and Wands!",
		"emotion": "explain"
	}
]

var _ambient_timer: float = 0.0
var _ambient_interval: float = 80.0
var enable_ambient_tips: bool = true

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	_original_y = position.y

	GameEvents.irene_toast_requested.connect(show_toast)

func set_landscape(is_landscape: bool) -> void:
	if is_landscape:
		var vp_width := get_viewport_rect().size.x if is_inside_tree() else 1600.0
		vp_width = maxf(vp_width, 1600.0)
		offset_left = (vp_width - 664.0) * 0.5
		offset_right = offset_left + 664.0
		offset_top = 88.0
		offset_bottom = 156.0
	else:
		offset_left = 28.0
		offset_right = 692.0
		offset_top = 104.0
		offset_bottom = 172.0
	_original_y = offset_top
	if not visible:
		position.y = _original_y - 20.0

func _process(delta: float) -> void:
	if not enable_ambient_tips:
		return

	_ambient_timer += delta
	if _ambient_timer >= _ambient_interval:
		_ambient_timer = 0.0
		show_random_tip()

func show_random_tip() -> void:
	var tips := AMBIENT_TIPS
	var current_board := SaveManager.current_board_id
	if current_board == "witch":
		tips = WITCH_AMBIENT_TIPS
	elif current_board == "farm":
		tips = FARM_AMBIENT_TIPS

	if tips.is_empty():
		return
	var tip: Dictionary = tips[randi() % tips.size()]
	show_toast(tip.text, tip.get("emotion", "greeting"), 5.5)

func show_toast(text: String, emotion: String = "greeting", duration: float = 5.0) -> void:
	if not is_inside_tree():
		return

	var current_board := SaveManager.current_board_id
	var tex_dict := EMOTIONS
	if tag_label:
		if current_board == "witch":
			tag_label.text = "IVY'S TIP"
			tex_dict = IVY_EMOTIONS
		elif current_board == "farm":
			tag_label.text = "IVAN'S TIP"
			tex_dict = IVAN_EMOTIONS
		else:
			tag_label.text = "IRENE'S TIP"
			tex_dict = EMOTIONS

	var default_tex: Texture2D = tex_dict.get("explain", tex_dict.get("greeting", EMOTIONS["greeting"]))
	var tex: Texture2D = tex_dict.get(emotion, default_tex)
	if avatar_rect:
		avatar_rect.texture = tex

	message_label.text = text
	visible = true

	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween().set_parallel(false)

	# Initial position & opacity
	position.y = _original_y - 20.0
	modulate.a = 0.0

	# Slide in and fade in
	var in_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(self, "position:y", _original_y, 0.28)
	in_tween.tween_property(self, "modulate:a", 1.0, 0.22)

	# Sound cue
	SoundManager.play_dialogue_blip()

	# Hold on screen
	_anim_tween.tween_interval(duration)

	# Slide out and fade out
	_anim_tween.tween_property(self, "position:y", _original_y - 20.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_anim_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	_anim_tween.finished.connect(func():
		visible = false
	)

func _gui_input(event: InputEvent) -> void:
	# Tap to dismiss toaster early
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		dismiss_animated()
		accept_event()

func dismiss_immediately() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	visible = false
	modulate.a = 0.0
	position.y = _original_y - 20.0

func dismiss_animated() -> void:
	if not visible:
		return
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	var out_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(self, "position:y", _original_y - 20.0, 0.15)
	out_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	out_tween.finished.connect(func():
		visible = false
	)
