class_name ItemView
extends Node2D

enum ItemState {
	NORMAL = 0,
	LOCKED = 1,
	BOXED = 2,
	HIDDEN = 3
}

enum ProducerStatus {
	NONE = 0,
	READY = 1,
	EXHAUST = 2
}

const BOX_TEXTURES: Array[Texture2D] = [
	preload("res://assets/items/extras/box/box1.png"),
	preload("res://assets/items/extras/box/box2.png"),
	preload("res://assets/items/extras/box/box3.png"),
	preload("res://assets/items/extras/box/box4.png"),
	preload("res://assets/items/extras/box/box5.png"),
]

const WEB_TEXTURES: Array[Texture2D] = [
	preload("res://assets/items/extras/box/web1.png"),
	preload("res://assets/items/extras/box/web2.png"),
	preload("res://assets/items/extras/box/web3.png"),
	preload("res://assets/items/extras/box/web4.png"),
	preload("res://assets/items/extras/box/web5.png"),
	preload("res://assets/items/extras/box/web6.png"),
]

const BUSH_TEXTURE: Texture2D = preload("res://assets/items/extras/bush/bush.png")
const DIRT_TEXTURE: Texture2D = preload("res://assets/items/extras/bush/dirt.png")

const SHEEP_ALT_TEXTURES: Dictionary = {
	"sheep_1": preload("res://assets/items/farm/sheep/1alt.png"),
	"sheep_2": preload("res://assets/items/farm/sheep/2alt.png"),
	"sheep_3": preload("res://assets/items/farm/sheep/3alt.png"),
	"sheep_4": preload("res://assets/items/farm/sheep/4alt.png")
}

const LOCKED_ITEM_MODULATE: Color = Color(0.65, 0.65, 0.65, 0.7)

@export var board_theme: String = "kitchen": # "kitchen" or "farm"
	set(val):
		board_theme = val
		if is_inside_tree():
			_update_visuals()

# Special interaction state
@export var fed_count: int = 0
@export var shear_cooldown: float = 0.0
@export var is_boosted: bool = false
@export var boost_charges: int = 0
@export var is_milked_ready: bool = false
@export var water_fed: int = 0

# Cage storage & auto-feed state
@export var cage_stored_items: Array[Dictionary] = []
@export var cage_auto_feed_timer: float = 30.0

# Witch Cauldron & Potion state
@export var cauldron_stored_items: Array[String] = []
@export var cooldown_removed: bool = false

# Auto-spawn state
@export var auto_spawn_current_stack: int = 0
@export var auto_spawn_timer: float = 0.0

@export_group("Locked Item Visuals")
@export var locked_item_modulate: Color = LOCKED_ITEM_MODULATE:
	set(val):
		locked_item_modulate = val
		if is_inside_tree() and item_state == ItemState.LOCKED:
			_update_visuals()

@export var data: ItemData:
	set(val):
		data = val
		if is_inside_tree():
			_update_visuals()

@export var item_state: ItemState = ItemState.NORMAL:
	set(val):
		item_state = val
		if is_inside_tree():
			_update_visuals()

@export var unlock_level: int = 1:
	set(val):
		unlock_level = val
		if is_inside_tree() and item_state == ItemState.BOXED:
			_update_visuals()

@export var box_variant: int = -1:
	set(val):
		box_variant = val
		if is_inside_tree() and item_state == ItemState.BOXED:
			_update_visuals()

@export var web_variant: int = -1:
	set(val):
		web_variant = val
		if is_inside_tree() and (item_state == ItemState.BOXED or item_state == ItemState.LOCKED):
			_update_visuals()

var grid_coord: Vector2i = Vector2i(-1, -1)
var is_in_inventory: bool = false
var inventory_slot_idx: int = -1

var is_dragging: bool = false
var target_slot_pos: Vector2 = Vector2.ZERO

# Producer state
var producer_status: ProducerStatus = ProducerStatus.NONE
var current_charges: int = 10
var max_charges: int = 10
var cooldown_per_charge: float = 5.0
var current_cooldown: float = 0.0
var _idle_tween: Tween = null

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite
@onready var web_sprite: Sprite2D = $Visuals.get_node_or_null("WebSprite")
@onready var shadow: Sprite2D = $Shadow
@onready var glow: Sprite2D = $Visuals/Glow
@onready var tier_badge: PanelContainer = $Visuals/TierBadge
@onready var tier_label: Label = $Visuals/TierBadge/TierLabel
@onready var spawner_badge: PanelContainer = $Visuals/SpawnerBadge
@onready var spawner_label: Label = $Visuals/SpawnerBadge/SpawnerLabel
@onready var status_badge: PanelContainer = $Visuals/StatusBadge
@onready var status_label: Label = $Visuals/StatusBadge/StatusLabel
@onready var auto_spawn_badge: PanelContainer = $Visuals.get_node_or_null("AutoSpawnBadge")
@onready var auto_spawn_label: Label = $Visuals.get_node_or_null("AutoSpawnBadge/AutoSpawnLabel")
@onready var touch_area: Control = $TouchArea

var _pulse_tween: Tween
var _scale_tween: Tween
var _base_scale: float = 0.48

func _ready() -> void:
	_ensure_auto_spawn_badge()
	if data:
		_update_visuals()
	glow.visible = false

func _ensure_auto_spawn_badge() -> void:
	if not visuals:
		return
	if not auto_spawn_badge:
		auto_spawn_badge = visuals.get_node_or_null("AutoSpawnBadge")
	if not auto_spawn_badge:
		auto_spawn_badge = PanelContainer.new()
		auto_spawn_badge.name = "AutoSpawnBadge"
		auto_spawn_badge.offset_left = 10.0
		auto_spawn_badge.offset_top = -34.0
		auto_spawn_badge.offset_right = 34.0
		auto_spawn_badge.offset_bottom = -10.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.72, 0.45, 0.95)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		auto_spawn_badge.add_theme_stylebox_override("panel", sb)
		auto_spawn_label = Label.new()
		auto_spawn_label.name = "AutoSpawnLabel"
		auto_spawn_label.add_theme_color_override("font_color", Color.WHITE)
		auto_spawn_label.add_theme_color_override("font_outline_color", Color(0.1, 0.3, 0.15, 0.9))
		auto_spawn_label.add_theme_constant_override("outline_size", 2)
		auto_spawn_label.add_theme_font_size_override("font_size", 13)
		auto_spawn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		auto_spawn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		auto_spawn_label.text = "🐾"
		auto_spawn_badge.add_child(auto_spawn_label)
		visuals.add_child(auto_spawn_badge)
	elif not auto_spawn_label:
		auto_spawn_label = auto_spawn_badge.get_node_or_null("AutoSpawnLabel")

func get_board() -> Board:
	if get_parent() is Board:
		return get_parent() as Board
	if get_parent() and get_parent().get_parent() is Board:
		return get_parent().get_parent() as Board
	if is_instance_valid(SaveManager) and is_instance_valid(SaveManager.board_ref):
		return SaveManager.board_ref
	return null

func _process(delta: float) -> void:
	if shear_cooldown > 0.0:
		shear_cooldown = maxf(0.0, shear_cooldown - delta)
		if shear_cooldown <= 0.0:
			_update_visuals()

	# 1. Tap Spawner cooldown processing
	if data and data.is_spawner and item_state == ItemState.NORMAL:
		if cooldown_removed:
			current_cooldown = 0.0
			current_charges = max_charges
			if producer_status == ProducerStatus.EXHAUST:
				producer_status = ProducerStatus.READY
				_update_visuals()
		elif current_cooldown > 0.0:
			current_cooldown = maxf(0.0, current_cooldown - delta)
			var missing_charges: int = int(ceil(current_cooldown / cooldown_per_charge))
			var target_charges: int = clampi(max_charges - missing_charges, 0, max_charges)
			if current_cooldown <= 0.0:
				target_charges = max_charges

			if target_charges > current_charges:
				current_charges = target_charges
				if current_charges > 0 and producer_status == ProducerStatus.EXHAUST:
					producer_status = ProducerStatus.READY
					_update_visuals()

			if producer_status == ProducerStatus.EXHAUST and status_label and status_badge and status_badge.visible:
				status_label.text = "%ds" % int(ceil(current_cooldown))

	# 2. Auto Spawn processing (can be on spawner or normal item)
	if data and data.has_auto_spawn and item_state == ItemState.NORMAL and not is_in_inventory and not is_dragging:
		var has_stack := tick_auto_spawn(delta)
		if has_stack:
			var b := get_board()
			if is_instance_valid(b):
				b.try_auto_spawn(self)

	# 3. Cage processing (shear cooldown of stored sheep & Lv.6 auto-feed)
	if is_cage() and item_state == ItemState.NORMAL:
		for dict in cage_stored_items:
			if dict.has("shear_cooldown"):
				var scd: float = float(dict.get("shear_cooldown", 0.0))
				if scd > 0.0:
					dict["shear_cooldown"] = maxf(0.0, scd - delta)
		if data.tier == 6 and not cage_stored_items.is_empty() and not is_in_inventory and not is_dragging:
			cage_auto_feed_timer = maxf(0.0, cage_auto_feed_timer - delta)
			if cage_auto_feed_timer <= 0.0:
				cage_auto_feed_timer = 30.0
				var b := get_board()
				if is_instance_valid(b):
					b.try_cage_auto_feed(self)

func get_box_texture() -> Texture2D:
	if BOX_TEXTURES.is_empty():
		return null
	var idx: int = 0
	if box_variant >= 0:
		idx = box_variant % BOX_TEXTURES.size()
	else:
		var seed_val: int = unlock_level * 7
		if grid_coord != Vector2i(-1, -1):
			seed_val += grid_coord.x * 13 + grid_coord.y * 7
		elif data:
			seed_val += abs(data.id.hash())
		idx = abs(seed_val) % BOX_TEXTURES.size()
	return BOX_TEXTURES[idx]

func get_web_texture() -> Texture2D:
	if WEB_TEXTURES.is_empty():
		return null
	var idx: int = 0
	if web_variant >= 0:
		idx = web_variant % WEB_TEXTURES.size()
	else:
		var seed_val: int = (unlock_level + 3) * 11
		if grid_coord != Vector2i(-1, -1):
			seed_val += grid_coord.x * 17 + grid_coord.y * 19
		elif data:
			seed_val += abs(data.id.hash())
		idx = abs(seed_val) % WEB_TEXTURES.size()
	return WEB_TEXTURES[idx]

func setup(item_data: ItemData, state: ItemState = ItemState.NORMAL, req_level: int = 1, b_var: int = -1, w_var: int = -1) -> void:
	data = item_data
	item_state = state
	unlock_level = req_level
	if b_var >= 0:
		box_variant = b_var
	if w_var >= 0:
		web_variant = w_var
	if data and data.is_spawner:
		max_charges = data.max_charges
		cooldown_per_charge = data.cooldown_per_charge
		current_charges = max_charges
		current_cooldown = 0.0
		producer_status = ProducerStatus.READY
	else:
		producer_status = ProducerStatus.NONE
		current_charges = 0
		current_cooldown = 0.0

	if data and data.has_auto_spawn:
		auto_spawn_current_stack = 0
		auto_spawn_timer = data.auto_spawn_interval
	else:
		auto_spawn_current_stack = 0
		auto_spawn_timer = 0.0

	cage_stored_items.clear()
	cage_auto_feed_timer = 30.0

	_update_visuals()

func restore_auto_spawn_state(stack: int, timer: float) -> void:
	if not data or not data.has_auto_spawn:
		return
	auto_spawn_current_stack = clampi(stack, 0, data.auto_spawn_max_stack)
	auto_spawn_timer = maxf(0.0, timer)
	_update_visuals()

func is_auto_spawn_ready() -> bool:
	if not data or not data.has_auto_spawn or item_state != ItemState.NORMAL:
		return false
	if is_in_inventory or is_dragging:
		return false
	return auto_spawn_current_stack > 0

func tick_auto_spawn(delta: float) -> bool:
	if not data or not data.has_auto_spawn:
		return false
	if auto_spawn_current_stack < data.auto_spawn_max_stack:
		auto_spawn_timer = maxf(0.0, auto_spawn_timer - delta)
		if auto_spawn_timer <= 0.0:
			auto_spawn_current_stack = mini(auto_spawn_current_stack + 1, data.auto_spawn_max_stack)
			if auto_spawn_current_stack < data.auto_spawn_max_stack:
				auto_spawn_timer = data.auto_spawn_interval
			else:
				auto_spawn_timer = 0.0
			_update_visuals()
	return auto_spawn_current_stack > 0

func restore_spawner_state(charges: int, cooldown: float, status_val: int = -1) -> void:
	if not data or not data.is_spawner:
		return
	max_charges = data.max_charges
	cooldown_per_charge = data.cooldown_per_charge
	current_charges = charges
	current_cooldown = cooldown
	if status_val >= 0:
		producer_status = status_val as ProducerStatus
	else:
		producer_status = ProducerStatus.READY if current_charges > 0 else ProducerStatus.EXHAUST
	_update_visuals()

func restore_interaction_state(fed: int, s_cd: float, boosted: bool, b_charges: int = 0, milk_ready: bool = false, w_fed: int = 0, cd_removed: bool = false) -> void:
	fed_count = fed
	shear_cooldown = s_cd
	is_boosted = boosted
	boost_charges = b_charges
	is_milked_ready = milk_ready
	water_fed = w_fed
	cooldown_removed = cd_removed
	if cooldown_removed and data and data.is_spawner:
		current_cooldown = 0.0
		current_charges = max_charges
		producer_status = ProducerStatus.READY
	_update_visuals()

func get_required_feed_item_id() -> String:
	if not data:
		return ""
	match data.id:
		"bird_1", "bird_2":
			return "hay_1"
		"bird_3":
			return "hay_2"
		"bird_4":
			return "hay_2"
		"cow_1":
			return "hay_3"
		"cow_2":
			return "hay_4"
		"cow_3":
			return "hay_6" if is_milked_ready else "hay_5"
		"sheep_1":
			return "hay_3"
		"sheep_2":
			return "hay_4"
		"sheep_3":
			return "hay_5"
		"pig_1", "pig_2", "pig_3", "pig_4":
			return "hay" # Any hay level!
		_:
			return ""

func get_required_feed_count() -> int:
	if not data:
		return 0
	match data.id:
		"bird_1", "bird_2", "bird_3", "bird_4":
			return 1
		"cow_1", "cow_2":
			return 1
		"cow_3":
			return 1 # hay_6 1 time to upgrade
		"sheep_1", "sheep_2", "sheep_3":
			return 1
		"pig_1", "pig_2", "pig_3", "pig_4":
			return 1
		_:
			return 0

func needs_feeding_to_upgrade() -> bool:
	var req_cnt := get_required_feed_count()
	return req_cnt > 0 and fed_count < req_cnt

func is_fully_fed() -> bool:
	var req_cnt := get_required_feed_count()
	if req_cnt <= 0:
		return true
	return fed_count >= req_cnt

func can_merge_with(other: ItemView) -> bool:
	if not other or not other.data or not data:
		return false
	if other == self:
		return false
	if data.id != other.data.id:
		return false
	if not is_normal() or not other.is_normal():
		return false
	if is_cage() and not cage_stored_items.is_empty():
		return false
	if other.is_cage() and not other.cage_stored_items.is_empty():
		return false
	if needs_feeding_to_upgrade() and not is_fully_fed():
		return false
	if other.needs_feeding_to_upgrade() and not other.is_fully_fed():
		return false
	return true

func can_accept_feed(feed_item: ItemView) -> bool:
	if not feed_item or not feed_item.data or not data:
		return false
	if not is_normal() or not feed_item.is_normal():
		return false
	var feed_id := feed_item.data.id

	# Pig: any level of hay, up to required feed count (1)
	if data.id in ["pig_1", "pig_2", "pig_3", "pig_4"]:
		return feed_id.begins_with("hay_") and fed_count < get_required_feed_count()

	# Cow Level 3 special:
	# can be fed hay_5 to be milked (if not already milk ready)
	# can be fed hay_6 (1 time) to upgrade
	if data.id == "cow_3":
		if feed_id == "hay_5" and not is_milked_ready:
			return true
		if feed_id == "hay_6" and fed_count < 1:
			return true
		return false

	# Tree Level 3 and 4: can be fed with hay_7 one time to boost fruit drop
	if data.id in ["tree_3", "tree_4"] and feed_id == "hay_7":
		return not is_boosted

	# Regular animal feeds
	var req_id := get_required_feed_item_id()
	if req_id.is_empty():
		return false
	return feed_id == req_id and fed_count < get_required_feed_count()

func can_be_sheared(tool_item: ItemView = null) -> bool:
	if not data or not data.chain_id == "sheep":
		return false
	if not is_normal():
		return false
	if shear_cooldown > 0.0:
		return false
	if tool_item == null:
		return true
	return tool_item.data != null and tool_item.data.id == "tool_4"

func can_be_boosted_by_tool(tool_item: ItemView) -> bool:
	if not data or not data.chain_id == "barn":
		return false
	if not is_normal():
		return false
	if not tool_item or not tool_item.data or not tool_item.data.chain_id == "tool":
		return false
	return tool_item.data.tier >= 3

func can_be_watered(watering_item: ItemView) -> bool:
	if not data or not (data.chain_id in ["hay", "tree", "pine"]):
		return false
	if not is_normal():
		return false
	if not watering_item or not watering_item.data:
		return false
	return watering_item.data.chain_id in ["watering", "water"]

func is_cage() -> bool:
	return data != null and data.chain_id == "cage"

func get_cage_capacity() -> int:
	if not is_cage():
		return 0
	match data.tier:
		3: return 2
		4: return 4
		5: return 10
		6: return 15
		_: return 0

func get_cage_stored_count() -> int:
	return cage_stored_items.size()

func get_cage_stored_animal_id() -> String:
	if cage_stored_items.is_empty():
		return ""
	return str(cage_stored_items[0].get("id", ""))

func get_cage_stored_animal_name() -> String:
	var a_id := get_cage_stored_animal_id()
	if a_id.is_empty():
		return ""
	var item := ItemDatabase.get_item(a_id)
	return item.display_name if item else a_id

func can_accept_animal_into_cage(animal_or_data: Variant) -> bool:
	if not is_cage() or data.tier < 3:
		return false
	var a_data: ItemData = null
	if animal_or_data is ItemView:
		if not animal_or_data.is_normal():
			return false
		a_data = animal_or_data.data
	elif animal_or_data is ItemData:
		a_data = animal_or_data
	elif animal_or_data is String:
		a_data = ItemDatabase.get_item(animal_or_data)
	if not a_data:
		return false
	if not (a_data.chain_id in ["bird", "cow", "sheep", "pig"]):
		return false
	if cage_stored_items.size() >= get_cage_capacity():
		return false
	if not cage_stored_items.is_empty():
		if a_data.id != get_cage_stored_animal_id():
			return false
	return true

func add_animal_to_cage(animal_or_data: Variant) -> bool:
	if not can_accept_animal_into_cage(animal_or_data):
		return false
	var dict: Dictionary = {}
	if animal_or_data is ItemView:
		dict = {
			"id": animal_or_data.data.id,
			"fed_count": animal_or_data.fed_count,
			"shear_cooldown": animal_or_data.shear_cooldown,
			"is_milked_ready": animal_or_data.is_milked_ready
		}
	elif animal_or_data is ItemData:
		dict = {
			"id": animal_or_data.id,
			"fed_count": 0,
			"shear_cooldown": 0.0,
			"is_milked_ready": false
		}
	elif animal_or_data is String:
		dict = {
			"id": animal_or_data,
			"fed_count": 0,
			"shear_cooldown": 0.0,
			"is_milked_ready": false
		}
	cage_stored_items.append(dict)
	_update_visuals()
	return true

func remove_animal_from_cage(idx: int) -> Dictionary:
	if idx < 0 or idx >= cage_stored_items.size():
		return {}
	var entry: Dictionary = cage_stored_items[idx].duplicate(true)
	cage_stored_items.remove_at(idx)
	_update_visuals()
	return entry

func can_cage_accept_feed(feed_item: ItemView) -> bool:
	if not is_cage() or data.tier < 3:
		return false
	if cage_stored_items.is_empty():
		return false
	if not feed_item or not feed_item.data or not feed_item.is_normal():
		return false
	return feed_item.data.id in ["hay_3", "hay_4", "hay_5", "hay_6"]

func can_cage_be_sheared(tool_item: ItemView = null) -> bool:
	if not is_cage() or data.tier < 3:
		return false
	if cage_stored_items.is_empty():
		return false
	var stored_id := get_cage_stored_animal_id()
	var stored_data := ItemDatabase.get_item(stored_id)
	if not stored_data or stored_data.chain_id != "sheep":
		return false
	if tool_item != null:
		if not tool_item.data or tool_item.data.id != "tool_4" or not tool_item.is_normal():
			return false
	for entry in cage_stored_items:
		if float(entry.get("shear_cooldown", 0.0)) <= 0.0:
			return true
	return false

func get_first_shearable_sheep_idx() -> int:
	for i in range(cage_stored_items.size()):
		if float(cage_stored_items[i].get("shear_cooldown", 0.0)) <= 0.0:
			return i
	return -1

func restore_cage_state(stored: Array, timer: float = 30.0) -> void:
	cage_stored_items.clear()
	for s in stored:
		if s is Dictionary:
			cage_stored_items.append((s as Dictionary).duplicate(true))
		elif s is String and not (s as String).is_empty():
			cage_stored_items.append({"id": s as String, "fed_count": 0, "shear_cooldown": 0.0, "is_milked_ready": false})
	cage_auto_feed_timer = timer
	_update_visuals()

func is_cauldron() -> bool:
	return data != null and data.chain_id == "cauldron"

func get_cauldron_capacity() -> int:
	if not is_cauldron():
		return 0
	match data.tier:
		4, 5:
			return 1
		6, 7:
			return 2
		8:
			return 3
		_:
			return 0

func is_potion() -> bool:
	return data != null and (data.chain_id == "potions" or data.is_potion)

func is_familiar() -> bool:
	return data != null and (data.chain_id == "familiars" or data.is_familiar)

func restore_cauldron_state(stored: Array) -> void:
	cauldron_stored_items.clear()
	for it in stored:
		var s := str(it).strip_edges()
		if not s.is_empty():
			cauldron_stored_items.append(s)
	_update_visuals()

func is_normal() -> bool:
	return item_state == ItemState.NORMAL

func is_locked() -> bool:
	return item_state == ItemState.LOCKED

func is_boxed() -> bool:
	return item_state == ItemState.BOXED

func is_hidden() -> bool:
	return item_state == ItemState.HIDDEN

func set_state(new_state: ItemState, req_level: int = 1) -> void:
	item_state = new_state
	unlock_level = req_level
	_update_visuals()

func unbox_to_locked() -> void:
	item_state = ItemState.LOCKED
	_update_visuals()
	animate_unbox()

func unlock_to_normal() -> void:
	item_state = ItemState.NORMAL
	_update_visuals()

func reveal(animate: bool = true) -> void:
	if item_state != ItemState.HIDDEN:
		return
	if unlock_level > 1:
		item_state = ItemState.BOXED
	else:
		item_state = ItemState.LOCKED
	visible = true
	if visuals:
		visuals.visible = true
	if shadow:
		shadow.visible = true
	if touch_area:
		touch_area.visible = true
	_update_visuals()
	if animate:
		animate_reveal()

func animate_reveal() -> void:
	if not visuals:
		return
	visuals.scale = Vector2(0.1, 0.1)
	var orig_mod: Color = sprite.modulate if sprite else Color.WHITE
	if sprite:
		sprite.modulate = Color.WHITE * 2.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.35)
	if sprite:
		var flash_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash_tween.tween_property(sprite, "modulate", orig_mod, 0.3)
	SoundManager.play_spawn()

func _update_visuals() -> void:
	if not data or not is_inside_tree() or not sprite:
		return

	if item_state == ItemState.HIDDEN:
		visible = false
		if visuals:
			visuals.visible = false
		if shadow:
			shadow.visible = false
		if touch_area:
			touch_area.visible = false
		if web_sprite:
			web_sprite.visible = false
		if tier_badge:
			tier_badge.visible = false
		if spawner_badge:
			spawner_badge.visible = false
		if status_badge:
			status_badge.visible = false
		if auto_spawn_badge:
			auto_spawn_badge.visible = false
		stop_idle_animation()
		return
	else:
		visible = true
		if visuals:
			visuals.visible = true
		if shadow:
			shadow.visible = true
		if touch_area:
			touch_area.visible = true

	if not web_sprite and visuals:
		web_sprite = visuals.get_node_or_null("WebSprite")
		if not web_sprite:
			web_sprite = Sprite2D.new()
			web_sprite.name = "WebSprite"
			visuals.add_child(web_sprite)
			if sprite:
				visuals.move_child(web_sprite, sprite.get_index() + 1)

	if item_state == ItemState.BOXED:
		if board_theme == "farm":
			sprite.texture = BUSH_TEXTURE
			shadow.texture = BUSH_TEXTURE
			sprite.modulate = Color.WHITE
			var tex_size := BUSH_TEXTURE.get_size()
			var max_dim := maxf(tex_size.x, tex_size.y)
			_base_scale = (74.0 / max_dim) if max_dim > 0.0 else 0.48
			sprite.scale = Vector2(_base_scale, _base_scale)
			shadow.scale = Vector2(_base_scale * 0.9, _base_scale * 0.9)
			glow.scale = Vector2(_base_scale * 1.18, _base_scale * 1.18)

			if web_sprite:
				web_sprite.visible = false # Bush only, no web, no dirt
		else:
			# Boxed status: use box texture variants, hide tier, hide spawner
			var box_tex: Texture2D = get_box_texture()
			sprite.texture = box_tex
			shadow.texture = box_tex
			# Subtle tint toward data.color for visual chain recognition
			if data:
				sprite.modulate = Color.WHITE.lerp(data.color, 0.3)
			else:
				sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var tex_size := box_tex.get_size() if box_tex else Vector2(432, 432)
			var max_dim := maxf(tex_size.x, tex_size.y)
			_base_scale = (74.0 / max_dim) if max_dim > 0.0 else 0.48

			sprite.scale = Vector2(_base_scale, _base_scale)
			shadow.scale = Vector2(_base_scale * 0.9, _base_scale * 0.9)
			glow.scale = Vector2(_base_scale * 1.18, _base_scale * 1.18)

			# Stacked web on top of boxed item
			if web_sprite:
				var web_tex: Texture2D = get_web_texture()
				web_sprite.texture = web_tex
				var web_dim := maxf(web_tex.get_width(), web_tex.get_height()) if web_tex else 94.0
				var web_scale := (78.0 / web_dim) if web_dim > 0.0 else 0.8
				web_sprite.scale = Vector2(web_scale, web_scale)
				web_sprite.modulate = Color(1.0, 1.0, 1.0, 0.95)
				web_sprite.visible = true

		tier_badge.visible = false
		spawner_badge.visible = false
		if auto_spawn_badge:
			auto_spawn_badge.visible = false
		if status_badge and status_label:
			status_badge.visible = true
			status_label.text = "Lv.%d" % unlock_level
		return

	# Determine texture and scale for revealed items (NORMAL or LOCKED)
	var active_tex: Texture2D = data.icon_texture
	if data.chain_id == "sheep" and shear_cooldown > 0.0:
		active_tex = SHEEP_ALT_TEXTURES.get(data.id, data.icon_texture)

	if active_tex:
		sprite.texture = active_tex
		shadow.texture = active_tex
		glow.texture = active_tex
		var tex_size := active_tex.get_size()
		var max_dim := maxf(tex_size.x, tex_size.y)
		_base_scale = (70.0 / max_dim) * data.icon_scale if max_dim > 0.0 else 0.48
	else:
		var def_tex: Texture2D = preload("res://icon.jpg")
		sprite.texture = def_tex
		shadow.texture = def_tex
		glow.texture = def_tex
		_base_scale = 0.48 * data.icon_scale

	sprite.scale = Vector2(_base_scale, _base_scale)
	shadow.scale = Vector2(_base_scale * 0.9, _base_scale * 0.9)
	glow.scale = Vector2(_base_scale * 1.18, _base_scale * 1.18)

	if item_state == ItemState.LOCKED:
		# Locked status: disabled dark gray filter (more grayish and more transparent)
		sprite.modulate = locked_item_modulate
		if web_sprite:
			if board_theme == "farm":
				# Farm theme: dirt effect on locked item, no web
				web_sprite.texture = DIRT_TEXTURE
				var dirt_dim := maxf(DIRT_TEXTURE.get_width(), DIRT_TEXTURE.get_height()) if DIRT_TEXTURE else 94.0
				var dirt_scale := (76.0 / dirt_dim) if dirt_dim > 0.0 else 0.8
				web_sprite.scale = Vector2(dirt_scale, dirt_scale)
				web_sprite.modulate = Color(1.0, 1.0, 1.0, 0.95)
				web_sprite.visible = true
			else:
				# Kitchen theme: web texture
				var web_tex: Texture2D = get_web_texture()
				web_sprite.texture = web_tex
				var web_dim := maxf(web_tex.get_width(), web_tex.get_height()) if web_tex else 94.0
				var web_scale := (76.0 / web_dim) if web_dim > 0.0 else 0.8
				web_sprite.scale = Vector2(web_scale, web_scale)
				web_sprite.modulate = Color(1.0, 1.0, 1.0, 0.95)
				web_sprite.visible = true

		if tier_badge:
			tier_badge.visible = false
		spawner_badge.visible = false
		if status_badge:
			status_badge.visible = false
		if auto_spawn_badge:
			auto_spawn_badge.visible = false
		stop_idle_animation()
	else:
		# Normal status: active coloring and badges, hide web/dirt
		if web_sprite:
			web_sprite.visible = false

		if tier_badge:
			tier_badge.visible = false

		glow.visible = is_boosted
		if is_boosted:
			glow.modulate = Color(1.0, 0.85, 0.2, 0.6)

		if data.is_spawner:
			if data.chain_id == "tree":
				spawner_badge.visible = true
				if is_instance_valid(spawner_label):
					spawner_label.text = ("🍎%d" % water_fed) if water_fed > 0 else "💧0"
				if status_badge:
					status_badge.visible = false
				sprite.modulate = Color.WHITE if data.icon_texture else data.color
				if water_fed > 0:
					start_idle_animation()
				else:
					stop_idle_animation()
			elif data.disappears_when_exhausted:
				spawner_badge.visible = (current_charges > 0)
				if is_instance_valid(spawner_label):
					spawner_label.text = str(current_charges)
				if status_badge:
					status_badge.visible = false
				sprite.modulate = Color.WHITE if data.icon_texture else data.color
				if current_charges > 0:
					start_idle_animation()
				else:
					stop_idle_animation()
			elif producer_status == ProducerStatus.EXHAUST or current_charges <= 0:
				spawner_badge.visible = false
				if is_instance_valid(spawner_label):
					spawner_label.text = "⚡"
				if status_badge and status_label:
					status_badge.visible = true
					status_label.text = "%ds" % int(ceil(current_cooldown))
				sprite.modulate = Color(0.65, 0.65, 0.7, 1.0)
				stop_idle_animation()
			else:
				spawner_badge.visible = true
				if is_instance_valid(spawner_label):
					spawner_label.text = "⚡"
				if status_badge:
					status_badge.visible = false
				sprite.modulate = Color.WHITE if data.icon_texture else data.color
				start_idle_animation()
		else:
			spawner_badge.visible = false
			if is_cage() and data.tier >= 3:
				if status_badge and status_label:
					status_badge.visible = true
					if cage_stored_items.is_empty():
						status_label.text = "0/%d" % get_cage_capacity()
					else:
						status_label.text = "🐾%d/%d" % [cage_stored_items.size(), get_cage_capacity()]
			elif shear_cooldown > 0.0:
				if status_badge and status_label:
					status_badge.visible = true
					status_label.text = "%ds" % int(ceil(shear_cooldown))
			elif needs_feeding_to_upgrade():
				if status_badge and status_label:
					status_badge.visible = true
					status_label.text = "%d/%d" % [fed_count, get_required_feed_count()]
			elif status_badge:
				status_badge.visible = false
			sprite.modulate = Color.WHITE if data.icon_texture else data.color
			stop_idle_animation()

		if data.has_auto_spawn:
			_ensure_auto_spawn_badge()
			if auto_spawn_badge:
				if auto_spawn_current_stack > 0:
					auto_spawn_badge.visible = true
					if is_instance_valid(auto_spawn_label):
						if auto_spawn_current_stack > 1:
							auto_spawn_label.text = "🐾%d" % auto_spawn_current_stack
						else:
							auto_spawn_label.text = "🐾"
				else:
					auto_spawn_badge.visible = false
		elif auto_spawn_badge:
			auto_spawn_badge.visible = false

func consume_spawn_charge() -> bool:
	if not data or not data.is_spawner:
		return false
	if cooldown_removed:
		current_charges = max_charges
		current_cooldown = 0.0
		producer_status = ProducerStatus.READY
		_update_visuals()
		return true
	if current_charges <= 0:
		return false
	current_charges -= 1
	current_cooldown = minf(current_cooldown + cooldown_per_charge, float(max_charges) * cooldown_per_charge)
	if current_charges <= 0:
		current_charges = 0
		producer_status = ProducerStatus.EXHAUST
		stop_idle_animation()
	else:
		producer_status = ProducerStatus.READY
	_update_visuals()
	return true

func is_spawner_ready() -> bool:
	if not data or not data.is_spawner or item_state != ItemState.NORMAL:
		return false
	if data.chain_id == "tree":
		return water_fed > 0
	return producer_status == ProducerStatus.READY and current_charges > 0

func is_spawner_exhausted() -> bool:
	return data != null and data.is_spawner and (producer_status == ProducerStatus.EXHAUST or current_charges <= 0)

func get_spawner_status_string() -> String:
	if not data or not data.is_spawner:
		return "none"
	match producer_status:
		ProducerStatus.READY:
			return "ready"
		ProducerStatus.EXHAUST:
			return "Exhaust"
		_:
			return "none"

func start_idle_animation() -> void:
	if _idle_tween and _idle_tween.is_valid():
		return
	if is_dragging or (glow and glow.visible):
		return
	if not data or not data.is_spawner or item_state != ItemState.NORMAL or producer_status != ProducerStatus.READY or current_charges <= 0:
		return

	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(visuals, "scale", Vector2(1.07, 0.94), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(visuals, "scale", Vector2(0.95, 1.05), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(visuals, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func stop_idle_animation() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null
	if not is_dragging and visuals:
		visuals.scale = Vector2.ONE

func animate_unbox() -> void:
	# Juicy squash, stretch, and pop when opening a box into a locked item
	visuals.scale = Vector2(0.6, 1.35)
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.45)

	# Flash effect
	var target_col := sprite.modulate
	var flash_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(sprite, "modulate", target_col, 0.3).from(Color.WHITE * 2.0)
	SoundManager.play_spawn()

func animate_pickup() -> void:
	stop_idle_animation()
	is_dragging = true
	z_index = 100
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(visuals, "scale", Vector2(1.2, 1.2), 0.15)
	_scale_tween.tween_property(shadow, "position", Vector2(0, 16), 0.15)
	_scale_tween.tween_property(shadow, "scale", Vector2(_base_scale * 1.05, _base_scale * 1.05), 0.15)
	_scale_tween.tween_property(shadow, "modulate:a", 0.45, 0.15)
	SoundManager.play_drop()

func animate_drop(on_complete: Callable = Callable()) -> void:
	is_dragging = false
	z_index = 10
	set_merge_highlight(false)
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(visuals, "scale", Vector2.ONE, 0.2)
	_scale_tween.tween_property(shadow, "position", Vector2(0, 6), 0.2)
	_scale_tween.tween_property(shadow, "scale", Vector2(_base_scale * 0.9, _base_scale * 0.9), 0.2)
	_scale_tween.tween_property(shadow, "modulate:a", 0.25, 0.2)
	_scale_tween.finished.connect(func():
		if is_spawner_ready():
			start_idle_animation()
		if on_complete.is_valid():
			on_complete.call()
	)
	SoundManager.play_drop()

func animate_snap_to(target_pos: Vector2, on_complete: Callable = Callable()) -> void:
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_pos, 0.12)
	tween.finished.connect(func():
		if is_spawner_ready():
			start_idle_animation()
		if on_complete.is_valid():
			on_complete.call()
	)

func animate_bounce_back(origin_pos: Vector2) -> void:
	is_dragging = false
	z_index = 10
	set_merge_highlight(false)
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", origin_pos, 0.35)
	var sc_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sc_tween.tween_property(visuals, "scale", Vector2.ONE, 0.2)
	sc_tween.tween_property(shadow, "position", Vector2(0, 6), 0.2)
	sc_tween.tween_property(shadow, "scale", Vector2(_base_scale * 0.9, _base_scale * 0.9), 0.2)
	sc_tween.tween_property(shadow, "modulate:a", 0.25, 0.2)
	sc_tween.finished.connect(func():
		if is_spawner_ready():
			start_idle_animation()
	)

func animate_merge_pop() -> void:
	# Juicy squash and stretch
	visuals.scale = Vector2(1.4, 0.6)
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.4)

	# Flash effect
	var orig_color := sprite.modulate
	sprite.modulate = Color.WHITE * 1.8
	var flash_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(sprite, "modulate", orig_color, 0.25)
	SoundManager.play_merge(data)

func animate_spawner_tap() -> void:
	# Mechanical button press
	visuals.scale = Vector2(0.85, 0.85)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.25)

func animate_click() -> void:
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()
	visuals.rotation_degrees = 0.0
	_scale_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(visuals, "scale", Vector2(0.85, 0.85), 0.08)
	_scale_tween.tween_property(visuals, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(visuals, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func animate_wobble() -> void:
	animate_click()

func animate_spawn_flight(from_pos: Vector2, to_pos: Vector2, on_complete: Callable = Callable()) -> void:
	global_position = from_pos
	visuals.scale = Vector2(0.2, 0.2)
	z_index = 80

	var duration := 0.38
	var tween := create_tween().set_parallel(true)
	# Parabolic height arc
	var mid_y := minf(from_pos.y, to_pos.y) - 90.0

	var pos_tween := create_tween()
	pos_tween.tween_method(func(t: float):
		var p_start := from_pos
		var p_mid := Vector2(lerpf(from_pos.x, to_pos.x, 0.5), mid_y)
		var p_end := to_pos
		# Quadratic bezier
		var q0 := p_start.lerp(p_mid, t)
		var q1 := p_mid.lerp(p_end, t)
		global_position = q0.lerp(q1, t)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(visuals, "scale", Vector2(1.2, 1.2), duration * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(visuals, "scale", Vector2.ONE, duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	pos_tween.finished.connect(func():
		z_index = 10
		SoundManager.play_drop()
		if on_complete.is_valid():
			on_complete.call()
	)

func set_merge_highlight(active: bool) -> void:
	glow.visible = active
	if active:
		stop_idle_animation()
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(visuals, "scale", Vector2(1.12, 1.12), 0.25).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_SINE)
	else:
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		if not is_dragging:
			visuals.scale = Vector2.ONE
			if is_spawner_ready():
				start_idle_animation()
