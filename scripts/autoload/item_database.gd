extends Node

var _items: Dictionary = {} # id -> ItemData
var _chains: Dictionary = {} # chain_id -> Array[ItemData]

func _ready() -> void:
	_init_database()

func _init_database() -> void:
	# 1. Tools Chain
	_register_item("tools_1", "tools", "Tools", 1, 5, "Wrench", "A basic wrench for fixing things.", Color(0.85, 0.85, 0.9))
	_register_item("tools_2", "tools", "Tools", 2, 5, "Hammer", "A sturdy hammer to build with.", Color(0.4, 0.7, 0.95))
	_register_item("tools_3", "tools", "Tools", 3, 5, "Hand Saw", "Sharp hand saw for cutting wood.", Color(0.2, 0.5, 0.9))
	_register_item("tools_4", "tools", "Tools", 4, 5, "Power Drill", "Heavy duty motorized power drill.", Color(0.3, 0.35, 0.85))
	var toolbox := _register_item("tools_5", "tools", "Tools", 5, 5, "Toolbox", "Tap to produce tool items! Uses 1 Energy.", Color(0.9, 0.25, 0.25))
	toolbox.is_spawner = true
	toolbox.energy_cost = 1
	toolbox.spawn_pool = ["tools_1", "tools_1", "tools_1", "tools_2", "coins_1"]

	# 2. Plant Chain
	_register_item("plant_1", "plant", "Plant", 1, 5, "Seed", "A tiny magical seed.", Color(0.75, 0.88, 0.55))
	_register_item("plant_2", "plant", "Plant", 2, 5, "Sprout", "A fresh green sprout reaching up.", Color(0.45, 0.82, 0.3))
	_register_item("plant_3", "plant", "Plant", 3, 5, "Wildflower", "A colorful blooming wildflower.", Color(0.92, 0.45, 0.7))
	_register_item("plant_4", "plant", "Plant", 4, 5, "Berry Bush", "A lush bush rich with sweet berries.", Color(0.8, 0.25, 0.55))
	var tree := _register_item("plant_5", "plant", "Plant", 5, 5, "Ancient Tree", "Tap to produce plant items! Uses 1 Energy.", Color(0.18, 0.65, 0.32))
	tree.is_spawner = true
	tree.energy_cost = 1
	tree.spawn_pool = ["plant_1", "plant_1", "plant_1", "plant_2", "energy_1"]

	# 3. Gem Chain (valuable quest / sell items)
	_register_item("gem_1", "gem", "Gem", 1, 4, "Gem Shard", "A shining fragment of a crystal.", Color(0.55, 0.9, 0.95))
	_register_item("gem_2", "gem", "Gem", 2, 4, "Rough Crystal", "A clustered crystalline formation.", Color(0.35, 0.72, 1.0))
	_register_item("gem_3", "gem", "Gem", 3, 4, "Cut Ruby", "A brilliant faceted ruby gemstone.", Color(0.95, 0.2, 0.38))
	_register_item("gem_4", "gem", "Gem", 4, 4, "Royal Diamond", "The crowning jewel of the realm.", Color(1.0, 0.88, 0.28))

	# 4. Coins Chain (Consumable)
	var coin1 := _register_item("coins_1", "coins", "Coins", 1, 4, "Bronze Coin", "Double-tap to collect 5 Coins.", Color(0.85, 0.55, 0.25))
	coin1.is_consumable = true
	coin1.consume_currency = "coins"
	coin1.consume_amount = 5

	var coin2 := _register_item("coins_2", "coins", "Coins", 2, 4, "Silver Coins", "Double-tap to collect 15 Coins.", Color(0.85, 0.88, 0.92))
	coin2.is_consumable = true
	coin2.consume_currency = "coins"
	coin2.consume_amount = 15

	var coin3 := _register_item("coins_3", "coins", "Coins", 3, 4, "Gold Pouch", "Double-tap to collect 40 Coins.", Color(1.0, 0.82, 0.1))
	coin3.is_consumable = true
	coin3.consume_currency = "coins"
	coin3.consume_amount = 40

	var coin4 := _register_item("coins_4", "coins", "Coins", 4, 4, "Treasure Chest", "Double-tap to collect 100 Coins!", Color(1.0, 0.62, 0.05))
	coin4.is_consumable = true
	coin4.consume_currency = "coins"
	coin4.consume_amount = 100

	# 5. Energy Chain (Consumable)
	var energy1 := _register_item("energy_1", "energy", "Energy", 1, 3, "Energy Spark", "Double-tap to restore 5 Energy.", Color(0.3, 0.95, 0.6))
	energy1.is_consumable = true
	energy1.consume_currency = "energy"
	energy1.consume_amount = 5

	var energy2 := _register_item("energy_2", "energy", "Energy", 2, 3, "Battery", "Double-tap to restore 15 Energy.", Color(0.2, 0.9, 0.3))
	energy2.is_consumable = true
	energy2.consume_currency = "energy"
	energy2.consume_amount = 15

	var energy3 := _register_item("energy_3", "energy", "Energy", 3, 3, "Power Cell", "Double-tap to restore 35 Energy.", Color(0.1, 0.85, 0.95))
	energy3.is_consumable = true
	energy3.consume_currency = "energy"
	energy3.consume_amount = 35

func _register_item(id: String, chain_id: String, chain_name: String, tier: int, max_tier: int,
		display_name: String, description: String, color: Color) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.chain_id = chain_id
	item.chain_name = chain_name
	item.tier = tier
	item.max_tier = max_tier
	item.display_name = display_name
	item.description = description
	item.color = color
	item.sell_value = int(pow(2, tier - 1))

	_items[id] = item

	if not _chains.has(chain_id):
		_chains[chain_id] = []
	_chains[chain_id].append(item)

	return item

func get_item(id: String) -> ItemData:
	return _items.get(id, null)

func has_item(id: String) -> bool:
	return _items.has(id)

func get_spawner_drop(spawner_id: String) -> String:
	var item: ItemData = get_item(spawner_id)
	if not item or not item.is_spawner or item.spawn_pool.is_empty():
		return "tools_1"
	return item.spawn_pool[randi() % item.spawn_pool.size()]

func get_all_items() -> Array:
	return _items.values()

func get_chain(chain_id: String) -> Array:
	return _chains.get(chain_id, [])
