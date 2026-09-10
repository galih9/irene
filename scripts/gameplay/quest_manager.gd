class_name QuestManager
extends Control

@export var quest_card_scene: PackedScene = preload("res://scenes/quest_card.tscn")
@onready var cards_container: HBoxContainer = $CardsContainer

var board_ref: Board = null

var active_quests: Array[QuestData] = []
var _cards: Array[QuestCard] = []

const MAX_QUESTS: int = 3

var _customer_names: Array[String] = [
	"Mayor Bob", "Florist Lily", "Mechanic Rex", "Grandma Rose",
	"Chef Luigi", "Artist Chloe", "Explorer Sam", "Professor Oak"
]

var _customer_colors: Array[Color] = [
	Color(0.2, 0.6, 0.9), Color(0.9, 0.4, 0.6), Color(0.9, 0.6, 0.2),
	Color(0.4, 0.8, 0.4), Color(0.8, 0.3, 0.3), Color(0.7, 0.3, 0.8)
]

func _ready() -> void:
	GameEvents.board_changed.connect(update_quest_status)
	GameEvents.inventory_changed.connect(update_quest_status)

func setup(board: Board, _inventory = null) -> void:
	board_ref = board

	_init_starter_quests()
	_rebuild_cards()
	update_quest_status()

func _init_starter_quests() -> void:
	active_quests.clear()

	# Quest 1: Farm Breakfast (Egg + Fresh Herb)
	var q1 := QuestData.new()
	q1.id = "quest_1"
	q1.customer_name = "Chef Luigi"
	q1.customer_color = Color(0.85, 0.35, 0.3)
	q1.required_item_ids = ["egg_1", "leaf_1"]
	q1.reward_coins = 35
	q1.reward_gems = 0
	q1.reward_exp = 15
	active_quests.append(q1)

	# Quest 2: Sweet Lunch (Cake + Toast)
	var q2 := QuestData.new()
	q2.id = "quest_2"
	q2.customer_name = "Grandma Rose"
	q2.customer_color = Color(0.9, 0.55, 0.2)
	q2.required_item_ids = ["cake_1", "sandwich_1"]
	q2.reward_coins = 45
	q2.reward_gems = 1
	q2.reward_exp = 20
	active_quests.append(q2)

	# Quest 3: Hearty Meal (Beef + Kitchen Spoon)
	var q3 := QuestData.new()
	q3.id = "quest_3"
	q3.customer_name = "Mayor Bob"
	q3.customer_color = Color(0.25, 0.6, 0.9)
	q3.required_item_ids = ["beef_1", "util_1"]
	q3.reward_coins = 55
	q3.reward_gems = 2
	q3.reward_exp = 30
	active_quests.append(q3)

func _rebuild_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	_cards.clear()

	for q in active_quests:
		var card: QuestCard = quest_card_scene.instantiate()
		card.deliver_pressed.connect(_on_deliver_pressed)
		cards_container.add_child(card)
		_cards.append(card)

func _get_all_available_item_ids() -> Array[String]:
	var result: Array[String] = []
	if board_ref:
		for item in board_ref.get_all_items_on_board():
			if item and item.data:
				result.append(item.data.id)
	result.append_array(InventoryManager.get_all_item_ids())
	return result

func update_quest_status() -> void:
	var available := _get_all_available_item_ids()

	for i in range(mini(active_quests.size(), _cards.size())):
		var q: QuestData = active_quests[i]
		var card: QuestCard = _cards[i]

		# Check if player has all required items
		var temp_avail := available.duplicate()
		var can_deliver := true
		for req_id in q.required_item_ids:
			if temp_avail.has(req_id):
				temp_avail.erase(req_id)
			else:
				can_deliver = false
				break

		card.setup(q, can_deliver, available)

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

	SoundManager.play_quest()

	# Floating celebration
	var reward_str: String = "+%d Gold!" % quest.reward_coins
	if quest.reward_gems > 0:
		reward_str += " +%d Gems!" % quest.reward_gems
	if quest.reward_exp > 0:
		reward_str += " +%d EXP!" % quest.reward_exp
	GameEvents.show_floating_text.emit("Order Complete!\n" + reward_str, global_position + Vector2(332, 100), Color(0.3, 1.0, 0.4))

	# Replace with new quest
	var idx := active_quests.find(quest)
	if idx >= 0:
		active_quests[idx] = _generate_new_quest()

	_rebuild_cards()
	update_quest_status()
	GameEvents.quest_completed.emit(quest)
	GameEvents.board_changed.emit()

func _consume_single_item(item_id: String) -> bool:
	# First search board
	if board_ref:
		for item in board_ref.get_all_items_on_board():
			if item and item.data and item.data.id == item_id:
				board_ref.remove_item(item)
				item.queue_free()
				return true

	# Then search backpack inventory
	if InventoryManager.remove_item_by_id(item_id):
		return true

	return false

func _generate_new_quest() -> QuestData:
	var q := QuestData.new()
	q.id = "quest_%d" % randi()
	q.customer_name = _customer_names[randi() % _customer_names.size()]
	q.customer_color = _customer_colors[randi() % _customer_colors.size()]

	# Randomly choose between 1 or 2 items
	var count := 1 if randf() < 0.4 else 2
	var reqs: Array[String] = []
	var total_tier := 0

	var possible_pools := [
		["egg_1", "egg_2", "egg_3", "egg_4"],
		["leaf_1", "leaf_2", "leaf_3", "leaf_4"],
		["beef_1", "beef_2", "beef_3", "beef_4"],
		["cake_1", "cake_2", "cake_3", "cake_4"],
		["sandwich_1", "sandwich_2", "sandwich_3", "sandwich_4"],
		["drink_1", "drink_2", "drink_3", "drink_4"],
		["util_1", "util_2", "util_3", "util_4"]
	]

	for i in range(count):
		var pool: Array = possible_pools[randi() % possible_pools.size()]
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
	if not active_quests.is_empty():
		var q := active_quests[0]
		EconomyManager.add_coins(q.reward_coins)
		if q.reward_gems > 0:
			EconomyManager.add_gems(q.reward_gems)
		if q.reward_exp > 0:
			ProgressionManager.add_exp(q.reward_exp)
		active_quests[0] = _generate_new_quest()
		_rebuild_cards()
		update_quest_status()
		SoundManager.play_quest()

func serialize_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for q in active_quests:
		if q:
			result.append({
				"id": q.id,
				"customer_name": q.customer_name,
				"customer_color": q.customer_color.to_html(true),
				"required_item_ids": q.required_item_ids.duplicate(),
				"reward_coins": q.reward_coins,
				"reward_gems": q.reward_gems,
				"reward_energy": q.reward_energy,
				"reward_exp": q.reward_exp
			})
	return result

func load_quests(quests_data: Array) -> void:
	if quests_data.is_empty():
		_init_starter_quests()
	else:
		active_quests.clear()
		for entry in quests_data:
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
			active_quests.append(q)
	_rebuild_cards()
	update_quest_status()
