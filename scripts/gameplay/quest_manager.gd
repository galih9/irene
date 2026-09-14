class_name QuestManager
extends Control

@export var quest_card_scene: PackedScene = preload("res://scenes/quest_card.tscn")
@onready var cards_container: BoxContainer = $CardsContainer

var board_ref: Board = null
var is_vertical: bool = false

var active_quests: Array[Variant] = [null, null, null]
var _cards: Array[QuestCard] = []
var _slot_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var _slot_total_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var _pending_starter_quests: Array[QuestData] = []

var ultimate_quest_active: bool = false
var ultimate_quest_completed: bool = false

const MAX_QUESTS: int = 3

var current_board_theme: String = "kitchen"
var _boards_data: Dictionary = {} # theme_id -> Dictionary of state

const KITCHEN_CUSTOMERS: Array[String] = [
	"Mayor Bob", "Florist Lily", "Mechanic Rex", "Grandma Rose",
	"Chef Luigi", "Artist Chloe", "Explorer Sam", "Professor Oak"
]

const KITCHEN_CUSTOMER_COLORS: Array[Color] = [
	Color(0.2, 0.6, 0.9), Color(0.9, 0.4, 0.6), Color(0.9, 0.6, 0.2),
	Color(0.4, 0.8, 0.4), Color(0.8, 0.3, 0.3), Color(0.7, 0.3, 0.8)
]

const FARM_CUSTOMERS: Array[String] = [
	"Ivan the Farmer", "Daisy the Cowherd", "Old MacDonald", "Shepherd Dan",
	"Orchard Jack", "Farmer Jill", "Silvia the Weaver", "Ranger Pete"
]

const FARM_CUSTOMER_COLORS: Array[Color] = [
	Color(0.25, 0.7, 0.35), Color(0.85, 0.6, 0.2), Color(0.9, 0.45, 0.25),
	Color(0.3, 0.65, 0.8), Color(0.65, 0.4, 0.25), Color(0.8, 0.75, 0.2)
]

var _customer_names: Array[String]:
	get:
		return FARM_CUSTOMERS if current_board_theme == "farm" else KITCHEN_CUSTOMERS

var _customer_colors: Array[Color]:
	get:
		return FARM_CUSTOMER_COLORS if current_board_theme == "farm" else KITCHEN_CUSTOMER_COLORS

const MILESTONE_BACKPACK: int = 5
const MILESTONE_SHOP: int = 5

var completed_quest_count: int = 0
static var instance: QuestManager = null

static func get_completed_count() -> int:
	if instance:
		return instance.completed_quest_count
	return 0

func is_backpack_unlocked() -> bool:
	return completed_quest_count >= MILESTONE_BACKPACK

func is_shop_unlocked() -> bool:
	return completed_quest_count >= MILESTONE_SHOP

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	instance = self
	GameEvents.board_changed.connect(_on_board_changed)
	GameEvents.inventory_changed.connect(update_quest_status)

func _process(delta: float) -> void:
	for i in range(MAX_QUESTS):
		if active_quests[i] == null and _slot_cooldowns[i] > 0.0:
			_slot_cooldowns[i] -= delta
			if _slot_cooldowns[i] <= 0.0:
				_slot_cooldowns[i] = 0.0
				_arrive_quest_for_slot(i)

func _on_board_changed() -> void:
	update_quest_status()
	check_ultimate_quest_trigger()

func set_layout_vertical(vertical: bool) -> void:
	is_vertical = vertical
	if is_instance_valid(cards_container):
		cards_container.vertical = vertical
	if vertical:
		custom_minimum_size = Vector2(270, 520)
	else:
		custom_minimum_size = Vector2(664, 172)
	_apply_card_sizes()

func _apply_card_sizes() -> void:
	for card in _cards:
		if is_instance_valid(card):
			if is_vertical:
				card.custom_minimum_size = Vector2(270, 160)
				card.size_flags_horizontal = Control.SIZE_FILL
				card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			else:
				card.custom_minimum_size = Vector2(212, 172)
				card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				card.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func setup(board: Board, _inventory = null) -> void:
	board_ref = board
	if is_instance_valid(board) and not board.board_theme.is_empty():
		current_board_theme = board.board_theme
	if _boards_data.has(current_board_theme):
		_restore_board_state(_boards_data[current_board_theme])
	else:
		_init_starter_quests()
		_save_current_board_state()
	_rebuild_cards()
	update_quest_status()

func switch_board(theme_id: String) -> void:
	if current_board_theme == theme_id:
		return

	# 1. Save current board quest state
	_save_current_board_state()

	# 2. Switch theme
	current_board_theme = theme_id

	# 3. Restore or initialize target board state
	if _boards_data.has(theme_id):
		_restore_board_state(_boards_data[theme_id])
	else:
		_init_starter_quests()
		_save_current_board_state()

	_rebuild_cards()
	update_quest_status()

func _save_current_board_state() -> void:
	_boards_data[current_board_theme] = {
		"active_quests": _serialize_quest_array(active_quests),
		"slot_cooldowns": _slot_cooldowns.duplicate(),
		"slot_total_cooldowns": _slot_total_cooldowns.duplicate(),
		"pending_starter_quests": _serialize_quest_array(_pending_starter_quests),
		"completed_quest_count": completed_quest_count,
		"ultimate_quest_active": ultimate_quest_active,
		"ultimate_quest_completed": ultimate_quest_completed
	}

func _restore_board_state(data: Dictionary) -> void:
	completed_quest_count = int(data.get("completed_quest_count", 0))
	ultimate_quest_active = data.get("ultimate_quest_active", false)
	ultimate_quest_completed = data.get("ultimate_quest_completed", false)
	var sc = data.get("slot_cooldowns", [])
	var stc = data.get("slot_total_cooldowns", [])
	if sc is Array and sc.size() == MAX_QUESTS:
		for i in range(MAX_QUESTS):
			_slot_cooldowns[i] = float(sc[i])
			_slot_total_cooldowns[i] = float(stc[i]) if (stc is Array and stc.size() == MAX_QUESTS) else float(sc[i])
	
	active_quests = _deserialize_quest_array(data.get("active_quests", []))
	_pending_starter_quests = _deserialize_quest_list(data.get("pending_starter_quests", []))
	GameEvents.quest_count_changed.emit(completed_quest_count)

func get_first_card() -> QuestCard:
	if not _cards.is_empty() and is_instance_valid(_cards[0]):
		return _cards[0]
	return null

func _init_starter_quests() -> void:
	if current_board_theme == "farm":
		_init_farm_starter_quests()
	else:
		_init_kitchen_starter_quests()

func _init_kitchen_starter_quests() -> void:
	active_quests.clear()
	active_quests.resize(MAX_QUESTS)
	active_quests.fill(null)
	_slot_cooldowns = [0.0, 6.0, 14.0]
	_slot_total_cooldowns = [0.0, 6.0, 14.0]
	_pending_starter_quests.clear()

	# Quest 1: Farm Breakfast (Egg + Fresh Herb)
	var q1 := QuestData.new()
	q1.id = "quest_1"
	q1.customer_name = "Chef Luigi"
	q1.customer_color = Color(0.85, 0.35, 0.3)
	q1.required_item_ids = ["egg_1", "leaf_1"]
	q1.reward_coins = 35
	q1.reward_gems = 0
	q1.reward_exp = 15
	active_quests[0] = q1

	# Quest 2: Boiled Snack (Boiled Egg)
	var q2 := QuestData.new()
	q2.id = "quest_2"
	q2.customer_name = "Grandma Rose"
	q2.customer_color = Color(0.9, 0.55, 0.2)
	q2.required_item_ids = ["egg_2"]
	q2.reward_coins = 40
	q2.reward_gems = 1
	q2.reward_exp = 20
	_pending_starter_quests.append(q2)

	# Quest 3: Garden Omelet (Boiled Egg + Herb Bunch)
	var q3 := QuestData.new()
	q3.id = "quest_3"
	q3.customer_name = "Mayor Bob"
	q3.customer_color = Color(0.25, 0.6, 0.9)
	q3.required_item_ids = ["egg_2", "leaf_2"]
	q3.reward_coins = 55
	q3.reward_gems = 1
	q3.reward_exp = 25
	_pending_starter_quests.append(q3)

func _init_farm_starter_quests() -> void:
	active_quests.clear()
	active_quests.resize(MAX_QUESTS)
	active_quests.fill(null)
	_slot_cooldowns = [0.0, 6.0, 14.0]
	_slot_total_cooldowns = [0.0, 6.0, 14.0]
	_pending_starter_quests.clear()

	# Farm Quest 1: Morning Grazing
	var q1 := QuestData.new()
	q1.id = "farm_quest_1"
	q1.customer_name = "Ivan the Farmer"
	q1.customer_color = Color(0.25, 0.7, 0.35)
	q1.required_item_ids = ["hay_1"]
	q1.reward_coins = 35
	q1.reward_gems = 1
	q1.reward_exp = 15
	active_quests[0] = q1

	# Farm Quest 2: Fresh Bales
	var q2 := QuestData.new()
	q2.id = "farm_quest_2"
	q2.customer_name = "Daisy the Cowherd"
	q2.customer_color = Color(0.85, 0.6, 0.2)
	q2.required_item_ids = ["hay_2"]
	q2.reward_coins = 45
	q2.reward_gems = 1
	q2.reward_exp = 20
	_pending_starter_quests.append(q2)

	# Farm Quest 3: Livestock Feed
	var q3 := QuestData.new()
	q3.id = "farm_quest_3"
	q3.customer_name = "Old MacDonald"
	q3.customer_color = Color(0.9, 0.45, 0.25)
	q3.required_item_ids = ["hay_2", "hay_1"]
	q3.reward_coins = 60
	q3.reward_gems = 2
	q3.reward_exp = 25
	_pending_starter_quests.append(q3)

func _rebuild_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	_cards.clear()

	for i in range(MAX_QUESTS):
		var card: QuestCard = quest_card_scene.instantiate()
		card.deliver_pressed.connect(_on_deliver_pressed)
		cards_container.add_child(card)
		_cards.append(card)
	_apply_card_sizes()

func _get_all_available_item_ids() -> Array[String]:
	var result: Array[String] = []
	if board_ref:
		for item in board_ref.get_all_items_on_board(true):
			if item and item.data:
				result.append(item.data.id)
	result.append_array(InventoryManager.get_all_item_ids())
	return result

func _check_can_deliver(q: QuestData, available: Array[String]) -> bool:
	if not q:
		return false
	var temp_avail := available.duplicate()
	for req_id in q.required_item_ids:
		if temp_avail.has(req_id):
			temp_avail.erase(req_id)
		else:
			return false
	return true

func update_quest_status() -> void:
	var available := _get_all_available_item_ids()

	for i in range(mini(active_quests.size(), _cards.size())):
		var q = active_quests[i]
		var card: QuestCard = _cards[i]
		if not is_instance_valid(card):
			continue

		if q == null:
			card.setup_cooldown(_slot_cooldowns[i], _slot_total_cooldowns[i])
		else:
			var can_deliver := _check_can_deliver(q as QuestData, available)
			card.setup(q as QuestData, can_deliver, available)

func _arrive_quest_for_slot(slot_idx: int) -> void:
	var q: QuestData = null
	if not _pending_starter_quests.is_empty():
		q = _pending_starter_quests.pop_front()
	else:
		q = _generate_new_quest()

	active_quests[slot_idx] = q
	if slot_idx < _cards.size() and is_instance_valid(_cards[slot_idx]):
		var available := _get_all_available_item_ids()
		var can_deliver := _check_can_deliver(q, available)
		_cards[slot_idx].setup(q, can_deliver, available)
		_cards[slot_idx].slide_in_from_top()
	else:
		_rebuild_cards()
		update_quest_status()

func _on_deliver_pressed(quest: QuestData) -> void:
	# Consume items from board/inventory
	for req_id in quest.required_item_ids:
		_consume_single_item(req_id)

	# Award rewards
	EconomyManager.add_coins(quest.reward_coins)
	if quest.reward_gems > 0:
		EconomyManager.add_gems(quest.reward_gems)
	if quest.reward_energy > 0:
		EconomyManager.add_energy(quest.reward_energy)
	if quest.reward_exp > 0:
		ProgressionManager.add_exp(quest.reward_exp)

	completed_quest_count += 1
	GameEvents.quest_count_changed.emit(completed_quest_count)
	if completed_quest_count == MILESTONE_BACKPACK:
		GameEvents.quest_milestone_unlocked.emit("backpack")
	if completed_quest_count == MILESTONE_SHOP:
		GameEvents.quest_milestone_unlocked.emit("shop")

	SoundManager.play_quest()

	# Floating celebration
	var reward_str: String = "+%d Gold!" % quest.reward_coins
	if quest.reward_gems > 0:
		reward_str += " +%d Gems!" % quest.reward_gems
	if quest.reward_exp > 0:
		reward_str += " +%d EXP!" % quest.reward_exp
	GameEvents.show_floating_text.emit("Order Complete!\n" + reward_str, global_position + Vector2(332, 100), Color(0.3, 1.0, 0.4))

	# Handle Ultimate Quest completion
	if quest.id.begins_with("ultimate_quest"):
		ultimate_quest_active = false
		ultimate_quest_completed = true
		var completion_text := "🏆 FARM MASTERED! GRAND HARVEST COMPLETE! 🏆" if current_board_theme == "farm" else "🏆 KITCHEN MASTERED! ULTIMATE FEAST COMPLETE! 🏆"
		GameEvents.show_floating_text.emit(completion_text, global_position + Vector2(332, 50), Color(1.0, 0.85, 0.2))

	# Replace with cooldown timer before next customer arrives
	var idx := active_quests.find(quest)
	if idx >= 0:
		active_quests[idx] = null
		# 4s during early onboarding tutorial, 14s for regular play
		var cd: float = 4.0 if completed_quest_count < 2 else 14.0
		_slot_cooldowns[idx] = cd
		_slot_total_cooldowns[idx] = cd
		if idx < _cards.size() and is_instance_valid(_cards[idx]):
			_cards[idx].setup_cooldown(cd, cd)

	update_quest_status()
	GameEvents.quest_completed.emit(quest)
	GameEvents.board_changed.emit()

func _consume_single_item(item_id: String) -> bool:
	if board_ref:
		for item in board_ref.get_all_items_on_board(true):
			if item and item.data and item.data.id == item_id:
				board_ref.remove_item(item)
				item.queue_free()
				return true

	if InventoryManager.remove_item_by_id(item_id):
		return true

	return false

func check_ultimate_quest_trigger() -> void:
	if ultimate_quest_active or ultimate_quest_completed:
		return
	if not is_instance_valid(board_ref):
		return
	# Must have active items on the board (cannot trigger on empty or uninitialized board)
	var items: Array[ItemView] = board_ref.get_all_items_on_board(false)
	if items.is_empty():
		return
	if board_ref.has_locked_or_boxed_items():
		return

	# Trigger Ultimate Quest
	ultimate_quest_active = true
	var uq := QuestData.new()
	var arrival_msg := ""
	if current_board_theme == "farm":
		uq.id = "ultimate_quest_farm"
		uq.customer_name = "👑 County Fair Judge Ivan"
		uq.customer_color = Color(1.0, 0.84, 0.0)
		uq.required_item_ids = [
			"hay_6",
			"fruit_5",
			"milk_4",
			"wool_4",
			"pine_5",
			"tool_4"
		]
		arrival_msg = "👑 GRAND HARVEST FESTIVAL QUEST ARRIVED! 👑"
	else:
		uq.id = "ultimate_quest_kitchen"
		uq.customer_name = "👑 Royal Food Critic Irene"
		uq.customer_color = Color(1.0, 0.84, 0.0)
		uq.required_item_ids = [
			"egg_6",       # Foodbox max normal
			"leaf_5",      # Foodbox max normal
			"beef_7",      # Oven max normal
			"cake_6",      # Oven max normal
			"sandwich_6",  # Oven max normal
			"drink_5",     # Fridge max normal
			"util_12"      # Rack max normal
		]
		arrival_msg = "👑 ULTIMATE FEAST QUEST ARRIVED! 👑"

	uq.reward_coins = 5000
	uq.reward_gems = 200
	uq.reward_energy = 100
	uq.reward_exp = 1000

	active_quests[0] = uq
	_slot_cooldowns[0] = 0.0
	_rebuild_cards()
	update_quest_status()
	if not _cards.is_empty() and is_instance_valid(_cards[0]):
		_cards[0].slide_in_from_top()

	GameEvents.show_floating_text.emit(arrival_msg, global_position + Vector2(330, 80), Color(1.0, 0.85, 0.2))
	SoundManager.play_quest()

func _generate_new_quest() -> QuestData:
	var q := QuestData.new()
	q.id = "quest_%d" % randi()
	var is_farm := (current_board_theme == "farm")
	var names_pool: Array[String] = FARM_CUSTOMERS if is_farm else KITCHEN_CUSTOMERS
	var colors_pool: Array[Color] = FARM_CUSTOMER_COLORS if is_farm else KITCHEN_CUSTOMER_COLORS
	q.customer_name = names_pool[randi() % names_pool.size()]
	q.customer_color = colors_pool[randi() % colors_pool.size()]

	# Randomly choose between 1 or 2 items
	var count := 1 if randf() < 0.4 else 2
	var reqs: Array[String] = []
	var total_tier := 0

	var possible_pools: Array[Array] = []
	if is_farm:
		possible_pools = [
			["hay_1", "hay_2", "hay_3", "hay_4"],
			["fruit_1", "fruit_2", "fruit_3", "fruit_4"],
			["pine_1", "pine_2", "pine_3", "pine_4"],
			["milk_1", "milk_2", "milk_3", "milk_4"],
			["wool_1", "wool_2", "wool_3", "wool_4"],
			["tree_1", "tree_2", "tree_3"],
			["tool_1", "tool_2", "tool_3"],
			["water_1", "water_2", "water_3"]
		]
	else:
		possible_pools = [
			["egg_1", "egg_2", "egg_3", "egg_4"],
			["leaf_1", "leaf_2", "leaf_3", "leaf_4"],
			["beef_1", "beef_2", "beef_3", "beef_4"],
			["cake_1", "cake_2", "cake_3", "cake_4"],
			["sandwich_1", "sandwich_2", "sandwich_3", "sandwich_4"],
			["drink_1", "drink_2", "drink_3", "drink_4"],
			["util_1", "util_2", "util_3", "util_4"]
		]

	# Filter out any pool whose chain the player hasn't unlocked yet
	var unlocked_pools: Array[Array] = []
	for pool in possible_pools:
		var starter_id: String = pool[0]
		var item_data := ItemDatabase.get_item(starter_id)
		var chain_id := item_data.chain_id if item_data else starter_id.split("_")[0]
		if ProgressionManager.is_unlocked(starter_id) or ProgressionManager.get_chain_unlocked_count(chain_id) > 0:
			unlocked_pools.append(pool)

	if unlocked_pools.is_empty():
		if is_farm:
			unlocked_pools = [
				["hay_1", "hay_2", "hay_3"],
				["fruit_1", "fruit_2"]
			]
		else:
			unlocked_pools = [
				["egg_1", "egg_2", "egg_3", "egg_4"],
				["leaf_1", "leaf_2", "leaf_3", "leaf_4"]
			]

	if completed_quest_count < 5:
		var low_tier_unlocked: Array[Array] = []
		for pool in unlocked_pools:
			var low_pool: Array = []
			for id in pool:
				var it := ItemDatabase.get_item(id)
				if it and it.tier <= 2:
					low_pool.append(id)
			if not low_pool.is_empty():
				low_tier_unlocked.append(low_pool)
		if low_tier_unlocked.is_empty():
			low_tier_unlocked = [["hay_1", "hay_2"]] if is_farm else [["egg_1", "egg_2"], ["leaf_1", "leaf_2"]]

		var chosen_pool: Array = low_tier_unlocked[randi() % low_tier_unlocked.size()]
		var starter_reqs: Array[String] = [chosen_pool[randi() % chosen_pool.size()]]
		if randf() < 0.4:
			var second_pool: Array = low_tier_unlocked[randi() % low_tier_unlocked.size()]
			starter_reqs.append(second_pool[randi() % second_pool.size()])

		q.required_item_ids = starter_reqs
		var early_tier := 0
		for item_id in q.required_item_ids:
			var it := ItemDatabase.get_item(item_id)
			if it:
				early_tier += it.tier
		q.reward_coins = 25 + early_tier * 15
		q.reward_gems = 1
		q.reward_exp = 15 + early_tier * 5
		return q

	for i in range(count):
		var pool: Array = unlocked_pools[randi() % unlocked_pools.size()]
		var chosen_id: String = pool[randi() % pool.size()]
		reqs.append(chosen_id)
		var it := ItemDatabase.get_item(chosen_id)
		if it:
			total_tier += it.tier

	q.required_item_ids = reqs
	q.reward_coins = 20 + total_tier * 18 + randi() % 10
	q.reward_gems = 2 if total_tier >= 4 else (1 if randf() < 0.35 else 0)
	q.reward_exp = 10 + total_tier * 6

	return q

func complete_active_quest_debug() -> void:
	for i in range(MAX_QUESTS):
		var q = active_quests[i]
		if q is QuestData:
			_on_deliver_pressed(q as QuestData)
			return
	# If all slots are currently waiting / on cooldown, force slot 0 to arrive immediately and deliver it
	_slot_cooldowns[0] = 0.0
	_arrive_quest_for_slot(0)
	if active_quests[0] is QuestData:
		_on_deliver_pressed(active_quests[0] as QuestData)

func serialize_data() -> Dictionary:
	_save_current_board_state()
	return {
		"current_board_theme": current_board_theme,
		"boards_quests": _boards_data,
		"quests": serialize_quests(),
		"completed_quest_count": completed_quest_count,
		"slot_cooldowns": _slot_cooldowns.duplicate(),
		"slot_total_cooldowns": _slot_total_cooldowns.duplicate(),
		"ultimate_quest_active": ultimate_quest_active,
		"ultimate_quest_completed": ultimate_quest_completed
	}

func load_data(data: Dictionary) -> void:
	if data.has("boards_quests"):
		_boards_data = data["boards_quests"]
	else:
		_boards_data.clear()

	if data.has("current_board_theme"):
		current_board_theme = str(data["current_board_theme"])

	if _boards_data.has(current_board_theme):
		_restore_board_state(_boards_data[current_board_theme])
	else:
		completed_quest_count = int(data.get("completed_quest_count", 0))
		ultimate_quest_active = data.get("ultimate_quest_active", false)
		ultimate_quest_completed = data.get("ultimate_quest_completed", false)
		var sc = data.get("slot_cooldowns", [])
		var stc = data.get("slot_total_cooldowns", [])
		if sc is Array and sc.size() == MAX_QUESTS:
			for i in range(MAX_QUESTS):
				_slot_cooldowns[i] = float(sc[i])
				_slot_total_cooldowns[i] = float(stc[i]) if (stc is Array and stc.size() == MAX_QUESTS) else float(sc[i])
		load_quests(data.get("quests", []))
		_save_current_board_state()

	_rebuild_cards()
	update_quest_status()

func serialize_quests() -> Array[Dictionary]:
	return _serialize_quest_array(active_quests)

func _serialize_quest_array(arr: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for q in arr:
		if q is QuestData:
			var qd: QuestData = q
			result.append({
				"id": qd.id,
				"customer_name": qd.customer_name,
				"customer_color": qd.customer_color.to_html(true),
				"required_item_ids": qd.required_item_ids.duplicate(),
				"reward_coins": qd.reward_coins,
				"reward_gems": qd.reward_gems,
				"reward_energy": qd.reward_energy,
				"reward_exp": qd.reward_exp
			})
		else:
			result.append({})
	return result

func _deserialize_quest_array(arr: Array) -> Array[Variant]:
	var result: Array[Variant] = []
	result.resize(MAX_QUESTS)
	result.fill(null)
	for i in range(mini(arr.size(), MAX_QUESTS)):
		var entry = arr[i]
		if entry is Dictionary and not entry.is_empty():
			result[i] = _dict_to_quest(entry)
	return result

func _deserialize_quest_list(arr: Array) -> Array[QuestData]:
	var result: Array[QuestData] = []
	for entry in arr:
		if entry is Dictionary and not entry.is_empty():
			result.append(_dict_to_quest(entry))
	return result

func _dict_to_quest(entry: Dictionary) -> QuestData:
	var q := QuestData.new()
	q.id = str(entry.get("id", "quest_%d" % randi()))
	q.customer_name = str(entry.get("customer_name", "Customer"))
	q.customer_color = Color.from_string(str(entry.get("customer_color", "#4da6ff")), Color(0.3, 0.7, 1.0))
	var reqs: Array[String] = []
	for req in entry.get("required_item_ids", []):
		reqs.append(str(req))
	q.required_item_ids = reqs
	q.reward_coins = int(entry.get("reward_coins", 25))
	q.reward_gems = int(entry.get("reward_gems", 0))
	q.reward_energy = int(entry.get("reward_energy", 0))
	q.reward_exp = int(entry.get("reward_exp", 15))
	return q

func load_quests(quests_data: Variant, completed_count: int = -1) -> void:
	if completed_count >= 0:
		completed_quest_count = completed_count
		GameEvents.quest_count_changed.emit(completed_quest_count)
	var list: Array = []
	if quests_data is Dictionary:
		if quests_data.has("completed_quest_count"):
			completed_quest_count = int(quests_data.get("completed_quest_count", 0))
			GameEvents.quest_count_changed.emit(completed_quest_count)
		list = quests_data.get("quests", quests_data.get("active_quests", []))
	elif quests_data is Array:
		list = quests_data

	if list.is_empty():
		_init_starter_quests()
	else:
		active_quests.clear()
		active_quests.resize(MAX_QUESTS)
		active_quests.fill(null)
		for i in range(mini(list.size(), MAX_QUESTS)):
			var entry = list[i]
			if entry is Dictionary and not entry.is_empty():
				active_quests[i] = _dict_to_quest(entry)
	_rebuild_cards()
	update_quest_status()
