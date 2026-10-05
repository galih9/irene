extends Node

var _items: Dictionary = {} # id -> ItemData
var _chains: Dictionary = {} # chain_id -> Array[ItemData]

var default_min_spawner_tier: int = 3
var default_spawner_max_charges: int = 10
var default_spawner_cooldown_per_charge: float = 5.0

func _ready() -> void:
	_init_database()

func _init_database() -> void:
	_items.clear()
	_chains.clear()

	_register_kitchen_items()
	_register_temporary_spawners()

	# =========================================================================
	# 3. CONSUMABLE ITEMS (EXP, Gold, Energy, Diamond)
	# =========================================================================

	# 3.1 EXP Chain (10 Tiers)
	var exp_textures := [
		preload("res://assets/items/rewards/exp/exp1.png"),
		preload("res://assets/items/rewards/exp/exp2.png"),
		preload("res://assets/items/rewards/exp/exp3.png"),
		preload("res://assets/items/rewards/exp/exp4.png"),
		preload("res://assets/items/rewards/exp/exp5.png"),
		preload("res://assets/items/rewards/exp/exp6.png"),
		preload("res://assets/items/rewards/exp/exp7.png"),
		preload("res://assets/items/rewards/exp/exp8.png"),
		preload("res://assets/items/rewards/exp/exp9.png"),
		preload("res://assets/items/rewards/exp/exp10.png")
	]
	var exp_names := [
		"Mini EXP Spark", "EXP Ember", "Glowing Shard",
		"Radiant Star", "Luminous Orb", "Stellar Crystal",
		"Astral Prism", "Cosmic Nova", "Celestial Beacon", "Infinite Core"
	]
	var exp_amounts := [1, 3, 8, 20, 50, 125, 320, 800, 2000, 5000]
	for t in range(1, 11):
		var it := _register_item(
			"exp_%d" % t, "exp", "EXP", t, 10,
			exp_names[t - 1], "Tap to collect %d EXP for your player level!" % exp_amounts[t - 1],
			Color(0.78, 0.45, 1.0), exp_textures[t - 1]
		)
		it.is_consumable = true
		it.consume_currency = "exp"
		it.consume_amount = exp_amounts[t - 1]

	# 3.2 Gold Chain (8 Tiers)
	var gold_textures := [
		preload("res://assets/items/rewards/gold/gold1.png"),
		preload("res://assets/items/rewards/gold/gold2.png"),
		preload("res://assets/items/rewards/gold/gold3.png"),
		preload("res://assets/items/rewards/gold/gold4.png"),
		preload("res://assets/items/rewards/gold/gold5.png"),
		preload("res://assets/items/rewards/gold/gold6.png"),
		preload("res://assets/items/rewards/gold/gold7.png"),
		preload("res://assets/items/rewards/gold/gold8.png")
	]
	var gold_names := [
		"Bronze Penny", "Silver Dime", "Gold Sovereign",
		"Coin Stack", "Velvet Coin Pouch", "Leather Money Bag",
		"Golden Coffer", "Royal Treasure Chest"
	]
	var gold_amounts := [5, 15, 40, 100, 250, 600, 1500, 4000]
	for t in range(1, 9):
		var it := _register_item(
			"gold_%d" % t, "gold", "Gold", t, 8,
			gold_names[t - 1], "Tap to collect %d Gold!" % gold_amounts[t - 1],
			Color(1.0, 0.82, 0.2), gold_textures[t - 1]
		)
		it.is_consumable = true
		it.consume_currency = "coins"
		it.consume_amount = gold_amounts[t - 1]

	# 3.3 Energy Chain (8 Tiers)
	var energy_textures := [
		preload("res://assets/items/rewards/energy/energy_1.png"),
		preload("res://assets/items/rewards/energy/energy_2.png"),
		preload("res://assets/items/rewards/energy/energy_3.png"),
		preload("res://assets/items/rewards/energy/energy_4.png"),
		preload("res://assets/items/rewards/energy/energy_5.png"),
		preload("res://assets/items/rewards/energy/energy_6.png"),
		preload("res://assets/items/rewards/energy/energy_7.png"),
		preload("res://assets/items/rewards/energy/energy_8.png")
	]
	var energy_names := [
		"Energy Spark", "Energy Droplet", "Energy Battery",
		"Power Cell", "Plasma Capsule", "Turbo Reactor",
		"Quantum Dynamo", "Infinity Matrix"
	]
	var energy_amounts := [5, 15, 35, 80, 180, 400, 900, 2000]
	for t in range(1, 9):
		var it := _register_item(
			"energy_%d" % t, "energy", "Energy", t, 8,
			energy_names[t - 1], "Tap to restore %d Energy!" % energy_amounts[t - 1],
			Color(0.25, 0.92, 0.55), energy_textures[t - 1]
		)
		it.is_consumable = true
		it.consume_currency = "energy"
		it.consume_amount = energy_amounts[t - 1]

	# 3.4 Diamond Chain (7 Tiers)
	var diamond_textures := [
		preload("res://assets/items/rewards/diamond/diamond_1.png"),
		preload("res://assets/items/rewards/diamond/diamond_2.png"),
		preload("res://assets/items/rewards/diamond/diamond_3.png"),
		preload("res://assets/items/rewards/diamond/diamond_4.png"),
		preload("res://assets/items/rewards/diamond/diamond_5.png"),
		preload("res://assets/items/rewards/diamond/diamond_6.png"),
		preload("res://assets/items/rewards/diamond/diamond_7.png")
	]
	var diamond_names := [
		"Raw Diamond Shard", "Flawed Diamond", "Cut Diamond",
		"Radiant Diamond", "Brilliant Solitaire", "Royal Crown Jewel", "Heart of Eternity"
	]
	var diamond_amounts := [1, 3, 8, 20, 50, 125, 300]
	for t in range(1, 8):
		var it := _register_item(
			"diamond_%d" % t, "diamond", "Diamond", t, 7,
			diamond_names[t - 1], "Tap to collect %d Diamonds!" % diamond_amounts[t - 1],
			Color(0.45, 0.88, 1.0), diamond_textures[t - 1]
		)
		it.is_consumable = true
		it.consume_currency = "gems"
		it.consume_amount = diamond_amounts[t - 1]

	# =========================================================================
	# 4. SPECIAL REWARD CHESTS (Hybrid Spawner + Consumable)
	# =========================================================================
	var chest_texture := preload("res://icon.jpg")
	var chest_names := [
		"Producer Supply Chest", "Grand Producer Chest"
	]
	var chest_descs := [
		"A special supply chest! Tap to spawn tier 1 producers for your current board (Oven/Fridge in Kitchen, Barn/Water on Farm, Mystic Tree/Cauldron in Witch). Exhausts and vanishes after 5 uses. Merge to reset charges!",
		"A grand supply chest! Tap to spawn tier 1 producers for your current board (Oven/Fridge/Rack/Foodbox in Kitchen, Barn/Water/Tree/Pine on Farm, Mystic Tree/Cauldron/Shroom/Wand in Witch). Exhausts and vanishes after 5 uses. Merge to reset charges!"
	]
	var chest_colors := [
		Color(0.95, 0.65, 0.25), Color(1.0, 0.85, 0.35)
	]
	var chest_pools: Array[Array] = [
		["oven_1", "fridge_1", "pantry_1"],
		["oven_1", "fridge_1", "rack_1", "pantry_1", "burner_1", "foodbox_1"]
	]

	for t in range(1, 3):
		var id := "chest_%d" % t
		var it := _register_item(
			id, "chest", "Chest", t, 2,
			chest_names[t - 1], chest_descs[t - 1],
			chest_colors[t - 1], chest_texture
		)
		it.is_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = 5
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.disappears_when_exhausted = true
		var pool: Array[String] = []
		for p in chest_pools[t - 1]:
			pool.append(str(p))
		it.spawn_pool = pool

	_register_color_chests()
	_register_farm_items()
	_register_witch_items()
	_register_aliases()

func _register_farm_items() -> void:
	# =========================================================================
	# 5. FARM CHAINS (15 Chains)
	# =========================================================================

	# 5.1 Barn Chain (Tiers 1-5, Spawner at Tier 3+)
	var barn_textures := [
		preload("res://assets/items/farm/barn/1.png"),
		preload("res://assets/items/farm/barn/2.png"),
		preload("res://assets/items/farm/barn/3.png"),
		preload("res://assets/items/farm/barn/4.png"),
		preload("res://assets/items/farm/barn/5.png")
	]
	var barn_names := [
		"Barn Foundation", "Framed Barn", "Finished Barn",
		"Bigger Barn", "Grand Farm Barn"
	]
	var barn_descs := [
		"A laid stone foundation for a future farm barn. Merge to build!",
		"The walls and roof framing are up. Merge to complete!",
		"A completed red barn! Tap to produce fresh farm hay (Uses 1 Energy). Automatically spawns farm animals nearby over time! Can be boosted with Tools (Lv.3+).",
		"A spacious barn with animal stalls! Tap to produce hay and birds. Auto-spawns animals nearby (Holds up to 2 stacks). Rare chance to drop Animal Cage Lv.1! Can be boosted with Tools (Lv.3+).",
		"The grand master barn! Tap to produce livestock, birds, and hay. Auto-spawns animals nearby (Holds up to 3 stacks). Rare chance to drop Animal Cage Lv.1! Can be boosted with Tools (Lv.3+)."
	]
	for t in range(1, 6):
		var id := "barn_%d" % t
		var it := _register_item(
			id, "barn", "Barn", t, 5,
			barn_names[t - 1], barn_descs[t - 1],
			Color(0.85, 0.32, 0.25), barn_textures[t - 1]
		)
		it.min_spawner_tier = 3
		it.is_spawner = (t >= 3)
		it.max_charges = 10
		it.cooldown_per_charge = 5.0
		it.energy_cost = 1
		it.spawn_pool = _get_barn_pool(t)
		if t >= 3:
			it.has_auto_spawn = true
			it.auto_spawn_interval = 15.0
			it.auto_spawn_max_stack = t - 2 # Tier 3: 1, Tier 4: 2, Tier 5: 3
			it.auto_spawn_pool = _get_barn_auto_spawn_pool(t)

	# 5.2 Hay Chain (Tiers 1-8)
	var hay_textures := [
		preload("res://assets/items/farm/hay/1.png"),
		preload("res://assets/items/farm/hay/2.png"),
		preload("res://assets/items/farm/hay/3.png"),
		preload("res://assets/items/farm/hay/4.png"),
		preload("res://assets/items/farm/hay/5.png"),
		preload("res://assets/items/farm/hay/6.png"),
		preload("res://assets/items/farm/hay/7.png"),
		preload("res://assets/items/farm/hay/8.png")
	]
	var hay_names := [
		"Grass Seed", "Small Grass", "Tall Grass", "Stack of Green Grass",
		"Yellow Hay Bale", "Stacks of Yellow Hay Bale", "Compost", "Biomass Facility"
	]
	var hay_descs := [
		"Nutritious grass seed. Perfect for feeding baby chicks!",
		"Fresh green grass shoots. Feed to growing hens and cocks!",
		"Tall flourishing pasture grass. Needed to feed calves and lambs!",
		"Hearty green grass stacks. Feed to young cows and young sheep!",
		"Golden cured hay bale. Feed to mature cows to milk them, and sheep to upgrade!",
		"Bountiful stacks of golden hay bales. Feed to mature cows to upgrade!",
		"Rich organic compost. Feed to fruit trees to boost fruit drop!",
		"Advanced biomass green energy converter! Max tier farm biomass."
	]
	for t in range(1, 9):
		_register_item(
			"hay_%d" % t, "hay", "Hay", t, 8,
			hay_names[t - 1], hay_descs[t - 1],
			Color(0.88, 0.82, 0.28), hay_textures[t - 1]
		)

	# 5.3 Tree Chain (Tiers 1-4, Spawner at Tier 3+)
	var tree_textures := [
		preload("res://assets/items/farm/tree/1.png"),
		preload("res://assets/items/farm/tree/2.png"),
		preload("res://assets/items/farm/tree/3.png"),
		preload("res://assets/items/farm/tree/4.png")
	]
	var tree_names := [
		"Fruit Tree Seed", "Fruit Tree Sapling", "Young Fruit Tree", "Mature Fruit Tree"
	]
	var tree_descs := [
		"A sturdy fruit tree seed waiting for fertile soil.",
		"A tender fruit sapling. Merge to cultivate an orchard tree!",
		"A young orchard tree beginning to bear fruit. Tap to harvest fruits! Uses 1 Energy. Feed Compost (Hay Lv.7) to boost fruit drop to 2!",
		"A magnificent sprawling orchard tree laden with juicy fruits. Uses 1 Energy. Feed Compost (Hay Lv.7) to boost fruit drop to 4!"
	]
	for t in range(1, 5):
		var id := "tree_%d" % t
		var it := _register_item(
			id, "tree", "Tree", t, 4,
			tree_names[t - 1], tree_descs[t - 1],
			Color(0.28, 0.72, 0.32), tree_textures[t - 1]
		)
		it.min_spawner_tier = 3
		it.is_spawner = (t >= 3)
		it.max_charges = 10
		it.cooldown_per_charge = 5.0
		it.energy_cost = 1
		it.spawn_pool = _get_tree_pool(t)

	# 5.4 Bird Chain (Tiers 1-8)
	var bird_textures := [
		preload("res://assets/items/farm/bird/1.png"),
		preload("res://assets/items/farm/bird/2.png"),
		preload("res://assets/items/farm/bird/3.png"),
		preload("res://assets/items/farm/bird/4.png"),
		preload("res://assets/items/farm/bird/5.png"),
		preload("res://assets/items/farm/bird/6.png"),
		preload("res://assets/items/farm/bird/7.png"),
		preload("res://assets/items/farm/bird/8.png")
	]
	var bird_names := [
		"Egg in a Nest", "Baby Chick", "Farm Hen", "Proud Cock",
		"Farm Duck", "Graceful Swan", "Wild Turkey", "Noble Rhea"
	]
	var bird_descs := [
		"A warm clutch of eggs nestled in straw. Merge to hatch!",
		"A fluffy yellow chick. Feed Grass Seed (Hay Lv.1) 5 times before it can upgrade!",
		"A plump hen. Feed Small Grass (Hay Lv.2) 5 times before it can upgrade!",
		"A proud farm cock with vibrant feathers. Feed Small Grass (Hay Lv.2) 10 times before it can upgrade!",
		"A friendly farm duck enjoying the pond.",
		"An elegant white swan gliding gracefully.",
		"A large heritage wild turkey.",
		"The majestic rhea! Max tier farm avian."
	]
	for t in range(1, 9):
		_register_item(
			"bird_%d" % t, "bird", "Bird", t, 8,
			bird_names[t - 1], bird_descs[t - 1],
			Color(0.96, 0.68, 0.28), bird_textures[t - 1]
		)

	# 5.5 Pine Chain (Tiers 1-5, Spawner at Tier 3+)
	var pine_textures := [
		preload("res://assets/items/farm/pine/1.png"),
		preload("res://assets/items/farm/pine/2.png"),
		preload("res://assets/items/farm/pine/3.png"),
		preload("res://assets/items/farm/pine/4.png"),
		preload("res://assets/items/farm/pine/5.png")
	]
	var pine_names := [
		"Pine Cone", "Pine Sapling", "Young Pine Tree",
		"Mature Pine Tree", "Dense Pine Forest"
	]
	var pine_descs := [
		"A resinous pine cone gathered from the woodland.",
		"A fragrant little pine seedling.",
		"A young evergreen pine. Tap to produce farm tools and fruit tree seeds! Uses 1 Energy.",
		"A towering evergreen pine tree. Tap to produce tools, pine cones, and tree seeds! Uses 1 Energy.",
		"A dense evergreen woodland producing tools, pine cones, and tree seeds. Uses 1 Energy."
	]
	for t in range(1, 6):
		var id := "pine_%d" % t
		var it := _register_item(
			id, "pine", "Pine", t, 5,
			pine_names[t - 1], pine_descs[t - 1],
			Color(0.18, 0.58, 0.35), pine_textures[t - 1]
		)
		it.min_spawner_tier = 3
		it.is_spawner = (t >= 3)
		it.max_charges = 10
		it.cooldown_per_charge = 5.0
		it.energy_cost = 1
		it.spawn_pool = _get_pine_pool(t)

	# 5.6 Water Chain (Tiers 1-6, Spawner at Tier 3+)
	var water_textures := [
		preload("res://assets/items/farm/water/1.png"),
		preload("res://assets/items/farm/water/2.png"),
		preload("res://assets/items/farm/water/3.png"),
		preload("res://assets/items/farm/water/4.png"),
		preload("res://assets/items/farm/water/5.png"),
		preload("res://assets/items/farm/water/6.png")
	]
	var water_names := [
		"Water Bucket", "Bigger Water Bucket", "Jerrycan",
		"Water Tank", "Water Tank Car", "Water Tower"
	]
	var water_descs := [
		"A wooden bucket of clear well water.",
		"A sturdy iron-banded bucket holding more fresh water.",
		"A portable jerrycan of spring water. Tap to produce watering equipment! Uses 1 Energy.",
		"A high-capacity galvanized water tank. Produces watering tools. Uses 1 Energy.",
		"A mobile water tanker on wheels. Produces advanced watering gear. Uses 1 Energy.",
		"A landmark farm water tower ensuring endless irrigation pressure! Max tier water."
	]
	for t in range(1, 7):
		var id := "water_%d" % t
		var it := _register_item(
			id, "water", "Water", t, 6,
			water_names[t - 1], water_descs[t - 1],
			Color(0.25, 0.65, 0.95), water_textures[t - 1]
		)
		it.min_spawner_tier = 3
		it.is_spawner = (t >= 3)
		it.max_charges = 10
		it.cooldown_per_charge = 5.0
		it.energy_cost = 1
		it.spawn_pool = _get_water_pool(t)

	# 5.7 Cow Chain (Tiers 1-6)
	var cow_textures := [
		preload("res://assets/items/farm/cow/1.png"),
		preload("res://assets/items/farm/cow/2.png"),
		preload("res://assets/items/farm/cow/3.png"),
		preload("res://assets/items/farm/cow/4.png"),
		preload("res://assets/items/farm/cow/5.png"),
		preload("res://assets/items/farm/cow/6.png")
	]
	var cow_names := [
		"Playful Calf", "Young Cow", "Mature Dairy Cow",
		"Hairy Highland Cow", "Sturdy Ox", "Mighty Bull"
	]
	var cow_descs := [
		"An adorable young calf. Feed Tall Grass (Hay Lv.3) 5 times to upgrade!",
		"A healthy young cow. Feed Stack of Grass (Hay Lv.4) 5 times to upgrade!",
		"A gentle dairy cow! Feed Hay Bale (Lv.5) 1 time to milk for fresh milk. Feed Hay Stacks (Lv.6) 1 time to upgrade!",
		"A thick-coated highland cow adapted to chilly weather.",
		"A muscular working ox capable of heavy fieldwork.",
		"The grand master farm bull! Max tier bovine."
	]
	for t in range(1, 7):
		_register_item(
			"cow_%d" % t, "cow", "Cow", t, 6,
			cow_names[t - 1], cow_descs[t - 1],
			Color(0.85, 0.85, 0.82), cow_textures[t - 1]
		)

	# 5.8 Sheep Chain (Tiers 1-4)
	var sheep_textures := [
		preload("res://assets/items/farm/sheep/1.png"),
		preload("res://assets/items/farm/sheep/2.png"),
		preload("res://assets/items/farm/sheep/3.png"),
		preload("res://assets/items/farm/sheep/4.png")
	]
	var sheep_names := [
		"Spring Lamb", "Young Sheep", "Mature Wool Sheep", "Horned Ram"
	]
	var sheep_descs := [
		"A gentle little lamb. Shear with Clipper (Tool Lv.4) to harvest 1 Wool! Feed Hay Lv.3 5 times to upgrade.",
		"A woolly young sheep. Shear with Clipper (Tool Lv.4) to harvest 3 Wool! Feed Hay Lv.4 5 times to upgrade.",
		"A full-fleeced mature sheep. Shear with Clipper (Tool Lv.4) to harvest 6 Wool! Feed Hay Lv.5 5 times to upgrade.",
		"A magnificent ram with curled horns. Shear with Clipper (Tool Lv.4) to harvest 8 Wool! Max tier sheep."
	]
	for t in range(1, 5):
		_register_item(
			"sheep_%d" % t, "sheep", "Sheep", t, 4,
			sheep_names[t - 1], sheep_descs[t - 1],
			Color(0.95, 0.95, 0.9), sheep_textures[t - 1]
		)

	# 5.9 Pig Chain (Tiers 1-5)
	var pig_textures := [
		preload("res://assets/items/farm/pig/1.png"),
		preload("res://assets/items/farm/pig/2.png"),
		preload("res://assets/items/farm/pig/3.png"),
		preload("res://assets/items/farm/pig/4.png"),
		preload("res://assets/items/farm/pig/5.png")
	]
	var pig_names := [
		"Pink Piglet", "Young Pig", "Mature Pig", "Dirty Pig", "Wild Boar"
	]
	var pig_descs := [
		"A cheerful little piglet. Feed any Hay 10 times to upgrade! Sells for high gold ($50).",
		"A growing young pig. Feed any Hay 10 times to upgrade! Sells for high gold ($150).",
		"A well-fed mature pig. Feed any Hay 10 times to upgrade! Sells for high gold ($400).",
		"A happy pig caked in protective mud. Feed any Hay 10 times to upgrade! Sells for high gold ($1000).",
		"A legendary wild boar with sharp tusks! Sells for 25 precious Diamonds!"
	]
	var pig_sell_values := [50, 150, 400, 1000, 25]
	for t in range(1, 6):
		var it := _register_item(
			"pig_%d" % t, "pig", "Pig", t, 5,
			pig_names[t - 1], pig_descs[t - 1],
			Color(0.95, 0.65, 0.7), pig_textures[t - 1]
		)
		it.sell_value = pig_sell_values[t - 1]

	# 5.10 Watering Chain (Tiers 1-5)
	var watering_textures := [
		preload("res://assets/items/farm/watering/1.png"),
		preload("res://assets/items/farm/watering/2.png"),
		preload("res://assets/items/farm/watering/3.png"),
		preload("res://assets/items/farm/watering/4.png"),
		preload("res://assets/items/farm/watering/5.png")
	]
	var watering_names := [
		"Water Bottle", "Water Sprayer", "Watering Can",
		"Portable Tank Sprayer", "Electric Power Sprayer"
	]
	var watering_descs := [
		"A handheld spray bottle. Drag onto Hay, Trees, or Pines to boost them!",
		"A pump mister bottle. Drag onto Hay, Trees, or Pines to boost them!",
		"A classic galvanized metal watering can. Drag onto plants to boost!",
		"A portable backpack sprayer for extensive garden irrigation.",
		"High-pressure electric spraying system with extended hose! Max tier watering."
	]
	for t in range(1, 6):
		_register_item(
			"watering_%d" % t, "watering", "Watering", t, 5,
			watering_names[t - 1], watering_descs[t - 1],
			Color(0.3, 0.8, 0.85), watering_textures[t - 1]
		)

	# 5.11 Fruit Chain (Tiers 1-8)
	var fruit_textures := [
		preload("res://assets/items/farm/fruit/1.png"),
		preload("res://assets/items/farm/fruit/2.png"),
		preload("res://assets/items/farm/fruit/3.png"),
		preload("res://assets/items/farm/fruit/4.png"),
		preload("res://assets/items/farm/fruit/5.png"),
		preload("res://assets/items/farm/fruit/6.png"),
		preload("res://assets/items/farm/fruit/7.png"),
		preload("res://assets/items/farm/fruit/8.png")
	]
	var fruit_names := [
		"Crisp Green Apple", "Sweet Red Apple", "Juicy Farm Pear", "Sun-ripened Orange",
		"Velvet Peach", "Ripe Yellow Banana", "Sweet Concord Grapes", "Grand Harvest Fruit Basket"
	]
	var fruit_descs := [
		"A tart green apple freshly picked from the tree.",
		"A crisp sweet apple shining in the orchard sunlight.",
		"A fragrant and juicy ripe orchard pear.",
		"Bursting with sweet citrus juice.",
		"Soft, fragrant velvet peach.",
		"A bunch of golden sweet bananas.",
		"Plump clusters of sweet wine grapes.",
		"An extravagant basket overflowing with farm-fresh orchard fruits! Max tier fruit."
	]
	for t in range(1, 9):
		_register_item(
			"fruit_%d" % t, "fruit", "Fruit", t, 8,
			fruit_names[t - 1], fruit_descs[t - 1],
			Color(0.95, 0.45, 0.25), fruit_textures[t - 1]
		)

	# 5.12 Tool Chain (Tiers 1-10)
	var tool_textures := [
		preload("res://assets/items/farm/tool/1.png"),
		preload("res://assets/items/farm/tool/2.png"),
		preload("res://assets/items/farm/tool/3.png"),
		preload("res://assets/items/farm/tool/4.png"),
		preload("res://assets/items/farm/tool/5.png"),
		preload("res://assets/items/farm/tool/6.png"),
		preload("res://assets/items/farm/tool/7.png"),
		preload("res://assets/items/farm/tool/8.png"),
		preload("res://assets/items/farm/tool/9.png"),
		preload("res://assets/items/farm/tool/10.png")
	]
	var tool_names := [
		"Hand Shovel", "Pruning Shears", "Garden Hoe", "Shearing Clipper",
		"Heavy Pitchfork", "Woodsman Axe", "Steel Pickaxe", "Craftsman Sledge",
		"Farm Chainsaw", "Master Farm Powerplant"
	]
	var tool_descs := [
		"A small garden trowel for planting seeds.",
		"Sharp hand clippers for trimming vines.",
		"A durable iron hoe. Can be fed to Barn (Lv.3+) to boost drop rates!",
		"Professional shearing clipper! Consumed to shear sheep for wool.",
		"A sturdy pitchfork for tossing fresh straw and hay bales. Can boost the Barn!",
		"A sharp felling axe for timber and brush clearing. Can boost the Barn!",
		"Solid steel pickaxe for breaking hard earth and stone. Can boost the Barn!",
		"Heavy blacksmith sledgehammer for farm construction. Can boost the Barn!",
		"Gas-powered timber chainsaw for clearing woodland. Can boost the Barn!",
		"The supreme industrial farming powerplant! Max tier farm tool."
	]
	for t in range(1, 11):
		_register_item(
			"tool_%d" % t, "tool", "Tool", t, 10,
			tool_names[t - 1], tool_descs[t - 1],
			Color(0.65, 0.68, 0.72), tool_textures[t - 1]
		)

	# 5.13 Milk Chain (Tiers 1-8)
	var milk_textures := [
		preload("res://assets/items/farm/milk/1.png"),
		preload("res://assets/items/farm/milk/2.png"),
		preload("res://assets/items/farm/milk/3.png"),
		preload("res://assets/items/farm/milk/4.png"),
		preload("res://assets/items/farm/milk/5.png"),
		preload("res://assets/items/farm/milk/6.png"),
		preload("res://assets/items/farm/milk/7.png"),
		preload("res://assets/items/farm/milk/8.png")
	]
	var milk_names := [
		"Fresh Milk Glass", "Pasteurized Milk Bottle", "Heavy Cream Jug", "Fresh Curd Bowl",
		"Soft Farm Cheese", "Aged Cheddar Wedge", "Gouda Wheel", "Grand Artisan Fromagerie"
	]
	var milk_descs := [
		"Rich warm milk fresh from the dairy cow.",
		"Chilled bottle of wholesome whole milk.",
		"Thick golden farm cream, ready for churning.",
		"Fresh cheese curds separated from whey.",
		"A wheel of young, soft farm cheese.",
		"Sharp cheddar aged to perfection in the cellar.",
		"A massive wheel of waxed Gouda cheese.",
		"A five-star gourmet spread of cellar-aged artisan cheeses! Max tier dairy."
	]
	for t in range(1, 9):
		_register_item(
			"milk_%d" % t, "milk", "Milk", t, 8,
			milk_names[t - 1], milk_descs[t - 1],
			Color(0.98, 0.96, 0.88), milk_textures[t - 1]
		)

	# 5.14 Wool Chain (Tiers 1-7)
	var wool_textures := [
		preload("res://assets/items/farm/wool/1.png"),
		preload("res://assets/items/farm/wool/2.png"),
		preload("res://assets/items/farm/wool/3.png"),
		preload("res://assets/items/farm/wool/4.png"),
		preload("res://assets/items/farm/wool/5.png"),
		preload("res://assets/items/farm/wool/6.png"),
		preload("res://assets/items/farm/wool/7.png")
	]
	var wool_names := [
		"Wool Tuft", "Cleaned Fleece", "Spinning Yarn Spool", "Knitted Mittens",
		"Woolen Scarf", "Cozy Cable Sweater", "Farm Boutique Coat"
	]
	var wool_descs := [
		"Soft raw wool sheared from sheep.",
		"Washed and carded cloud-soft fleece.",
		"A spool of tightly spun natural woolen yarn.",
		"Warm knitted mittens to keep hands cozy in winter.",
		"A thick knit wool scarf with decorative tassels.",
		"A warm, hand-knit cable sweater with rich texture.",
		"An elegant, bespoke designer coat tailored from pure farm wool! Max tier clothing."
	]
	for t in range(1, 8):
		_register_item(
			"wool_%d" % t, "wool", "Wool", t, 7,
			wool_names[t - 1], wool_descs[t - 1],
			Color(0.92, 0.88, 0.94), wool_textures[t - 1]
		)

	# 5.15 Animal Cage Chain (Tiers 1-6)
	var cage_textures := [
		preload("res://assets/items/farm/cage/1.png"),
		preload("res://assets/items/farm/cage/2.png"),
		preload("res://assets/items/farm/cage/3.png"),
		preload("res://assets/items/farm/cage/4.png"),
		preload("res://assets/items/farm/cage/5.png"),
		preload("res://assets/items/farm/cage/6.png")
	]
	var cage_names := [
		"Small Cage", "Sturdy Cage", "Animal Pen",
		"Spacious Cage", "Large Animal Enclosure", "Automated Animal Sanctuary"
	]
	var cage_descs := [
		"A small wooden cage. Merge to build larger animal enclosures!",
		"A sturdy reinforced cage. Merge to Lv.3 to unlock animal storage!",
		"An animal pen with 2 storage slots. Stores matching farm animals of the same level! Feed Hay (Lv.3-6) to harvest.",
		"A spacious animal cage with 4 storage slots. Feed Hay or Shearing Tool to harvest stored animals!",
		"A large animal enclosure with 10 storage slots. Keeps your farm board clean and compact!",
		"The ultimate automated animal sanctuary! Holds 15 matching animals and automatically feeds/harvests every 30 seconds!"
	]
	for t in range(1, 7):
		_register_item(
			"cage_%d" % t, "cage", "Animal Cage", t, 6,
			cage_names[t - 1], cage_descs[t - 1],
			Color(0.72, 0.52, 0.35), cage_textures[t - 1]
		)

func _get_barn_pool(tier: int) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		3:
			# Tier 3 Finished Barn (Starter Spawner): Strictly Level 1 items only (100% Hay Lv.1)
			pool = ["hay_1"]
		4:
			# Tier 4 Bigger Barn: 85% Hay (65% Lv.1, 20% Lv.2), 10% Bird Lv.1, 5% Cage Lv.1
			pool = [
				"hay_1", "hay_1", "hay_1", "hay_1", "hay_1",
				"hay_1", "hay_1", "hay_1", "hay_1", "hay_1",
				"hay_1", "hay_1", "hay_1",
				"hay_2", "hay_2", "hay_2", "hay_2",
				"bird_1", "bird_1",
				"cage_1"
			]
		5:
			# Tier 5 Grand Farm Barn: 85% Hay, 10% Animals, 5% Cage (Trees moved to forest; rare cage_1 drop)
			# Animals (bird, cow, sheep, pig) 2.5% each (4/40 = 10% total); cage_1 has 5% (2/40)
			pool = [
				# Hay (34/40 = 85%)
				"hay_1", "hay_1", "hay_1", "hay_1", "hay_1", "hay_1", "hay_1", "hay_1",
				"hay_1", "hay_1", "hay_1", "hay_1", "hay_1", "hay_1", "hay_1", "hay_1",
				"hay_1", "hay_1",
				"hay_2", "hay_2", "hay_2", "hay_2", "hay_2", "hay_2", "hay_2", "hay_2",
				"hay_2", "hay_2", "hay_2", "hay_2",
				"hay_3", "hay_3", "hay_3", "hay_3",
				# Animals (4/40 = 10% total, 2.5% each)
				"bird_1", "cow_1", "sheep_1", "pig_1",
				# Rare Cage Lv.1 (2/40 = 5% rare chance)
				"cage_1", "cage_1"
			]
		_:
			pool = ["hay_1"]
	return pool

func _get_barn_auto_spawn_pool(tier: int) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		3:
			# Tier 3 Finished Barn auto spawns farm animals
			pool = ["bird_1", "cow_1", "sheep_1", "pig_1"]
		4:
			# Tier 4 Bigger Barn auto spawns farm animals
			pool = ["bird_1", "cow_1", "sheep_1", "pig_1"]
		5:
			# Tier 5 Grand Farm Barn auto spawns farm animals
			pool = ["bird_1", "cow_1", "sheep_1", "pig_1"]
		_:
			pool = ["bird_1", "cow_1", "sheep_1", "pig_1"]
	return pool

func _get_tree_pool(tier: int) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		3:
			# Tier 3 Fruit Tree: Strictly Level 1 items only (100% Fruit Lv.1)
			pool = ["fruit_1"]
		4:
			# Tier 4 Fruit Tree: 85% Fruit Lv.1, 15% Fruit Lv.2
			pool = [
				"fruit_1", "fruit_1", "fruit_1", "fruit_1", "fruit_1", "fruit_1",
				"fruit_2"
			]
		_:
			pool = ["fruit_1"]
	return pool

func _get_pine_pool(tier: int) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		3:
			# Forest Lv.3 produces Tools and Fruit Tree Seeds (both strictly Level 1)
			pool = ["tool_1", "tool_1", "tool_1", "tree_1"]
		4:
			# Forest Lv.4 produces Tools Lv.1 (70%), Tools Lv.2 (15%), Pine Cones Lv.1 (7.5%), Fruit Tree Seeds Lv.1 (7.5%)
			pool = [
				"tool_1", "tool_1", "tool_1", "tool_1", "tool_1", "tool_1", "tool_1",
				"tool_2", "tool_2",
				"pine_1", "tree_1"
			]
		5:
			# Dense Pine Forest Lv.5 produces Tools Lv.1-3, Pine Cones, and Tree Seeds
			pool = [
				"tool_1", "tool_1", "tool_1", "tool_1", "tool_1",
				"tool_2", "tool_2", "tool_2",
				"tool_3",
				"pine_1", "tree_1", "tree_1"
			]
		_:
			pool = ["tool_1"]
	return pool

func _get_water_pool(tier: int) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		3:
			# Well Lv.3 (Starter Spawner): Strictly Level 1 items only (100% Watering Can Lv.1)
			pool = ["watering_1"]
		4:
			# Well Lv.4: 85% Lv.1, 15% Lv.2
			pool = [
				"watering_1", "watering_1", "watering_1", "watering_1", "watering_1", "watering_1",
				"watering_2"
			]
		5:
			# Spring Lv.5: 60% Lv.1, 30% Lv.2, 10% Lv.3
			pool = [
				"watering_1", "watering_1", "watering_1", "watering_1", "watering_1", "watering_1",
				"watering_2", "watering_2", "watering_2",
				"watering_3"
			]
		6:
			# River Basin Lv.6: 35% Lv.1, 35% Lv.2, 20% Lv.3, 10% Lv.4
			pool = [
				"watering_1", "watering_1", "watering_1", "watering_1",
				"watering_2", "watering_2", "watering_2", "watering_2",
				"watering_3", "watering_3",
				"watering_4"
			]
		_:
			pool = ["watering_1"]
	return pool

func _register_witch_items() -> void:
	# =========================================================================
	# 6. WITCH CHAINS (10 Chains)
	# =========================================================================

	# 6.1 Mystic Tree Chain (Tiers 1-6, Spawner at Tier 3+)
	var mystic_tree_textures := [
		preload("res://assets/items/witch/mystic_tree/1.png"),
		preload("res://assets/items/witch/mystic_tree/2.png"),
		preload("res://assets/items/witch/mystic_tree/3.png"),
		preload("res://assets/items/witch/mystic_tree/4.png"),
		preload("res://assets/items/witch/mystic_tree/5.png"),
		preload("res://assets/items/witch/mystic_tree/6.png")
	]
	var mystic_tree_names := [
		"Mystic Sprout", "Mystic Sapling", "Enchanted Mystic Tree",
		"Arcane Elder Tree", "Ancient Runetree", "Celestial Worldtree"
	]
	var mystic_tree_descs := [
		"A mysterious magical sprout glowing with faint ether. Merge to grow!",
		"A tender magical sapling pulsing with mana. Merge to cultivate!",
		"An enchanted mystic tree! Tap to produce magical shrooms and wands (Uses 1 Energy).",
		"An arcane elder tree bearing glowing shrooms and sturdy wands. Uses 1 Energy.",
		"An ancient runetree. Produces shrooms, wands, and ancient magic staves! Uses 1 Energy.",
		"The supreme celestial worldtree! Produces shrooms, wands, staves, and flying brooms! Uses 1 Energy."
	]
	for t in range(1, 7):
		var id := "mystic_tree_%d" % t
		var it := _register_item(
			id, "mystic_tree", "Mystic Tree", t, 6,
			mystic_tree_names[t - 1], mystic_tree_descs[t - 1],
			Color(0.55, 0.35, 0.85), mystic_tree_textures[t - 1]
		)
		it.min_spawner_tier = 3
		it.is_spawner = (t >= 3)
		it.max_charges = 10
		it.cooldown_per_charge = 5.0
		it.energy_cost = 1
		it.spawn_pool = _get_mystic_tree_pool(t)

	# 6.2 Shrooms Chain (Tiers 1-6, Spawner at Tier 3+)
	var shroom_textures := [
		preload("res://assets/items/witch/shroom/1.png"),
		preload("res://assets/items/witch/shroom/2.png"),
		preload("res://assets/items/witch/shroom/3.png"),
		preload("res://assets/items/witch/shroom/4.png"),
		preload("res://assets/items/witch/shroom/5.png"),
		preload("res://assets/items/witch/shroom/6.png")
	]
	var shroom_names := [
		"Tiny Truffle", "Glowing Cap", "Spore Spawner",
		"Moonlit Toadstool", "Arcane Fungus", "Elder Spirit Shroom"
	]
	var shroom_descs := [
		"A small wild mushroom found in the damp enchanted woods.",
		"A luminous cap flickering with magical spores in the dark.",
		"A magical spore cluster! Tap to produce ritual candles (Uses 1 Energy).",
		"A moonlit toadstool! Produces candles with a chance of ancient spellbooks. Uses 1 Energy.",
		"A potent arcane fungus producing ritual candles and spellbooks. Uses 1 Energy.",
		"An elder spirit mushroom radiating mystical spores! Uses 1 Energy."
	]
	for t in range(1, 7):
		var id := "shroom_%d" % t
		var it := _register_item(
			id, "shroom", "Shroom", t, 6,
			shroom_names[t - 1], shroom_descs[t - 1],
			Color(0.85, 0.40, 0.65), shroom_textures[t - 1]
		)
		it.min_spawner_tier = 3
		it.is_spawner = (t >= 3)
		it.max_charges = 10
		it.cooldown_per_charge = 5.0
		it.energy_cost = 1
		it.spawn_pool = _get_shroom_pool(t)

	# 6.3 Candle Chain (Tiers 1-6, Spawner ONLY at Tier 6)
	var candle_textures := [
		preload("res://assets/items/witch/candle/1.png"),
		preload("res://assets/items/witch/candle/2.png"),
		preload("res://assets/items/witch/candle/3.png"),
		preload("res://assets/items/witch/candle/4.png"),
		preload("res://assets/items/witch/candle/5.png"),
		preload("res://assets/items/witch/candle/6.png")
	]
	var candle_names := [
		"Wax Stub", "Tallow Candle", "Scented Taper",
		"Altar Candle", "Coven Candelabra", "Eternal Witch's Flame"
	]
	var candle_descs := [
		"A small wax stub with a fresh wick.",
		"A steady-burning tallow candle. Merge to elevate!",
		"A fragrant taper imbued with soothing magical herbs.",
		"A tall ceremonial candle for secret coven rites.",
		"An ornate multi-candle candelabra glowing brightly.",
		"An eternal flame of pure witchcraft! Tap to produce flying brooms with a rare chance of spellbooks! (Uses 1 Energy). Familiars can be sacrificed here."
	]
	for t in range(1, 7):
		var id := "candle_%d" % t
		var it := _register_item(
			id, "candle", "Candle", t, 6,
			candle_names[t - 1], candle_descs[t - 1],
			Color(0.95, 0.75, 0.30), candle_textures[t - 1]
		)
		it.min_spawner_tier = 6
		it.is_spawner = (t == 6)
		it.max_charges = 10
		it.cooldown_per_charge = 5.0
		it.energy_cost = 1
		if t == 6:
			it.spawn_pool = ["broom_1", "broom_1", "broom_1", "broom_1", "spellbook_1"]

	# 6.4 Spellbook Chain (Tiers 1-6, Spawner ONLY at Tier 6)
	var spellbook_textures := [
		preload("res://assets/items/witch/spellbook/1.png"),
		preload("res://assets/items/witch/spellbook/2.png"),
		preload("res://assets/items/witch/spellbook/3.png"),
		preload("res://assets/items/witch/spellbook/4.png"),
		preload("res://assets/items/witch/spellbook/5.png"),
		preload("res://assets/items/witch/spellbook/6.png")
	]
	var spellbook_names := [
		"Apprentice Notes", "Parchment Scroll", "Leatherbound Tome",
		"Enchanted Grimoire", "Shadow Codex", "Archmage's Book of Spells"
	]
	var spellbook_descs := [
		"Scattered parchment notes scribbled with beginner runes.",
		"An unrolled spell scroll sealed with purple wax.",
		"A sturdy leather tome filled with hex formulas.",
		"A glowing grimoire whispering forbidden arcane words.",
		"A dark codex bound with enchanted astral threads.",
		"The supreme Book of Spells! Tap to produce pure Player EXP! (Uses 1 Energy)."
	]
	for t in range(1, 7):
		var id := "spellbook_%d" % t
		var it := _register_item(
			id, "spellbook", "Spellbook", t, 6,
			spellbook_names[t - 1], spellbook_descs[t - 1],
			Color(0.40, 0.50, 0.90), spellbook_textures[t - 1]
		)
		it.min_spawner_tier = 6
		it.is_spawner = (t == 6)
		it.max_charges = 10
		it.cooldown_per_charge = 5.0
		it.energy_cost = 1
		if t == 6:
			it.spawn_pool = ["exp_1", "exp_1", "exp_2", "exp_3"]

	# 6.5 Wand Chain (Tiers 1-6)
	var wand_textures := [
		preload("res://assets/items/witch/wand/1.png"),
		preload("res://assets/items/witch/wand/2.png"),
		preload("res://assets/items/witch/wand/3.png"),
		preload("res://assets/items/witch/wand/4.png"),
		preload("res://assets/items/witch/wand/5.png"),
		preload("res://assets/items/witch/wand/6.png")
	]
	var wand_names := [
		"Twig Wand", "Carved Hazel Wand", "Runed Oak Wand",
		"Crystal Tipped Wand", "Starlight Wand", "Grand Master Wand"
	]
	var wand_descs := [
		"A supple wooden twig with raw magic energy.",
		"Carefully carved hazel wood polished smooth.",
		"Inscribed with protective glyphs and runes.",
		"Crowned with a sparkling quartz focus crystal.",
		"Channeling astral light through its radiant tip.",
		"The supreme wand of master spellweavers! Max tier wand."
	]
	for t in range(1, 7):
		_register_item(
			"wand_%d" % t, "wand", "Wand", t, 6,
			wand_names[t - 1], wand_descs[t - 1],
			Color(0.70, 0.55, 0.85), wand_textures[t - 1]
		)

	# 6.6 Staff Chain (Tiers 1-6)
	var staff_textures := [
		preload("res://assets/items/witch/staff/1.png"),
		preload("res://assets/items/witch/staff/2.png"),
		preload("res://assets/items/witch/staff/3.png"),
		preload("res://assets/items/witch/staff/4.png"),
		preload("res://assets/items/witch/staff/5.png"),
		preload("res://assets/items/witch/staff/6.png")
	]
	var staff_names := [
		"Walking Staff", "Druid's Crook", "Ironbound Rod",
		"Sorcerer's Stave", "Astral Scepter", "Archmage Worldstaff"
	]
	var staff_descs := [
		"A tall walking stick resonant with forest magic.",
		"A curved pastoral crook infused with nature spirits.",
		"Reinforced with iron rings to channel heavy spells.",
		"A gleaming stave crackling with arcane electricity.",
		"A majestic scepter adorned with orbiting cosmic orbs.",
		"The legendary Archmage Worldstaff! Max tier magic staff."
	]
	for t in range(1, 7):
		_register_item(
			"staff_%d" % t, "staff", "Staff", t, 6,
			staff_names[t - 1], staff_descs[t - 1],
			Color(0.35, 0.75, 0.80), staff_textures[t - 1]
		)

	# 6.7 Broom Chain (Tiers 1-6)
	var broom_textures := [
		preload("res://assets/items/witch/broom/1.png"),
		preload("res://assets/items/witch/broom/2.png"),
		preload("res://assets/items/witch/broom/3.png"),
		preload("res://assets/items/witch/broom/4.png"),
		preload("res://assets/items/witch/broom/5.png"),
		preload("res://assets/items/witch/broom/6.png")
	]
	var broom_names := [
		"Straw Whisk", "Kitchen Sweeper", "Flying Broomstick",
		"Nimble Sweeper", "Silverwind Glider", "Celestial Comet Broom"
	]
	var broom_descs := [
		"A bundled straw whisk for simple hearth chores.",
		"A practical broomstick made of tied twigs and ash wood.",
		"Enchanted to hover slightly above the floor!",
		"Aerodynamic and swift, perfect for low-altitude night rides.",
		"Silver-threaded bristles that ride on the nocturnal breeze.",
		"The fastest broom in the skies, trailing shimmering stardust! Max tier broom."
	]
	for t in range(1, 7):
		_register_item(
			"broom_%d" % t, "broom", "Broom", t, 6,
			broom_names[t - 1], broom_descs[t - 1],
			Color(0.85, 0.65, 0.40), broom_textures[t - 1]
		)

	# 6.8 Cauldron Chain (Tiers 1-8, Combiner)
	var cauldron_textures := [
		preload("res://assets/items/witch/cauldron/1.png"),
		preload("res://assets/items/witch/cauldron/2.png"),
		preload("res://assets/items/witch/cauldron/3.png"),
		preload("res://assets/items/witch/cauldron/4.png"),
		preload("res://assets/items/witch/cauldron/5.png"),
		preload("res://assets/items/witch/cauldron/6.png"),
		preload("res://assets/items/witch/cauldron/7.png"),
		preload("res://assets/items/witch/cauldron/8.png")
	]
	var cauldron_names := [
		"Clay Pot", "Copper Kettle", "Cast Iron Pot",
		"Apprentice Cauldron", "Bubbling Cauldron", "Alchemist Cauldron",
		"Witch's Great Cauldron", "Grandmaster Astral Cauldron"
	]
	var cauldron_descs := [
		"A simple clay mixing pot. Merge to Lv.4 to unlock brewing!",
		"A burnished copper kettle for heating extracts. Merge to Lv.4 to unlock brewing!",
		"A heavy iron pot retaining magical heat. Merge to Lv.4 to unlock brewing!",
		"An apprentice cauldron! Can combine 1 ingredient to brew potions or familiars.",
		"A steadily bubbling cauldron brewing aromatic concoctions. Can combine 1 ingredient.",
		"A dual-chamber alchemist cauldron! Can combine up to 2 ingredients.",
		"A grand coven cauldron glowing with eldritch fires. Can combine up to 2 ingredients.",
		"The supreme astral cauldron! Can combine up to 3 ingredients for legendary brews."
	]
	for t in range(1, 9):
		var id := "cauldron_%d" % t
		var it := _register_item(
			id, "cauldron", "Cauldron", t, 8,
			cauldron_names[t - 1], cauldron_descs[t - 1],
			Color(0.30, 0.25, 0.45), cauldron_textures[t - 1]
		)
		it.is_combiner = true

	# 6.9 Potions (12 Special Consumables, Non-mergeable)
	var potion_defs := [
		{"id": "potion_health", "name": "Heal Potion", "desc": "A restorative draft brewed from fresh fruit. Can only be sold for Gold ($100)!", "tex": preload("res://assets/items/witch/potions/health.png"), "sell": 100},
		{"id": "potion_angelic", "name": "Angelic Potion", "desc": "A divine elixir of celestial light. Drag onto any item to elevate it to maximum level!", "tex": preload("res://assets/items/witch/potions/angelic.png"), "sell": 50},
		{"id": "potion_exp", "name": "EXP Potion", "desc": "Concentrated knowledge. Tap to spawn 5 max-level EXP stars!", "tex": preload("res://assets/items/witch/potions/exp.png"), "sell": 50},
		{"id": "potion_fire", "name": "Fire Potion", "desc": "Blazing volatile flames. Drag onto any item (Lv.2+) to split it into two items of tier minus 1!", "tex": preload("res://assets/items/witch/potions/fire.png"), "sell": 50},
		{"id": "potion_freeze", "name": "Freeze Potion", "desc": "Cryogenic stasis draft. Drag onto any item to create an exact duplicate of it!", "tex": preload("res://assets/items/witch/potions/freeze.png"), "sell": 50},
		{"id": "potion_gold", "name": "Gold Potion", "desc": "Liquid aurum. Tap to spawn 5 max-level Royal Treasure Chests of Gold!", "tex": preload("res://assets/items/witch/potions/gold.png"), "sell": 50},
		{"id": "potion_love", "name": "Love Potion", "desc": "Sweet heart elixir. Tap to spawn 5 max-level Hearts of Eternity Diamonds!", "tex": preload("res://assets/items/witch/potions/love.png"), "sell": 50},
		{"id": "potion_nature", "name": "Nature Potion", "desc": "Primal spirit extract. Drag onto Pine or Fruit Tree to remove its cooldown entirely!", "tex": preload("res://assets/items/witch/potions/nature.png"), "sell": 50},
		{"id": "potion_omni", "name": "Omni Potion", "desc": "Supreme catalyst. Tap to purify the entire current board and gain 20,000 Diamonds!", "tex": preload("res://assets/items/witch/potions/omni.png"), "sell": 500},
		{"id": "potion_void", "name": "Void Potion", "desc": "Essence of the abyss. Drag onto any unwanted item to banish and remove it from the board!", "tex": preload("res://assets/items/witch/potions/void.png"), "sell": 50},
		{"id": "potion_water", "name": "Water Potion", "desc": "Endless flow droplet. Drag onto any Water item to remove its cooldown entirely!", "tex": preload("res://assets/items/witch/potions/water.png"), "sell": 50},
		{"id": "potion_wind", "name": "Wind Potion", "desc": "Gale-force zephyr draft. Drag onto Mystic Tree to remove its cooldown entirely!", "tex": preload("res://assets/items/witch/potions/wind.png"), "sell": 50}
	]
	for p in potion_defs:
		var it := _register_item(
			p.id, "potions", "Potions", 1, 1,
			p.name, p.desc,
			Color(0.80, 0.30, 0.80), p.tex
		)
		it.is_potion = true
		it.sell_value = p.sell

	# 6.10 Familiars (6 Magical Companions, Non-mergeable, Non-sellable)
	var familiar_defs := [
		{"id": "familiar_rat", "name": "Sewer Rat", "desc": "A sneaky nocturnal rat. Cannot be merged or sold. Sacrifice at Candle or Mystic Tree for Gold or EXP!", "tex": preload("res://assets/items/witch/familiars/rat.png")},
		{"id": "familiar_owl", "name": "Barn Owl", "desc": "A wise nocturnal avian familiar. Cannot be merged or sold. Sacrifice at Candle or Mystic Tree for Gold or EXP!", "tex": preload("res://assets/items/witch/familiars/owl.png")},
		{"id": "familiar_raven", "name": "Shadow Raven", "desc": "An omen of cunning magic. Cannot be merged or sold. Sacrifice at Candle or Mystic Tree for Gold or EXP!", "tex": preload("res://assets/items/witch/familiars/raven.png")},
		{"id": "familiar_frog", "name": "Poison Dart Frog", "desc": "A vibrant amphibious familiar. Cannot be merged or sold. Sacrifice at Candle or Mystic Tree for Gold or EXP!", "tex": preload("res://assets/items/witch/familiars/frog.png")},
		{"id": "familiar_kitten", "name": "Witch's Kitten", "desc": "A playful magical kitten. Cannot be merged or sold. Sacrifice at Candle or Mystic Tree for Gold or EXP!", "tex": preload("res://assets/items/witch/familiars/kitten.png")},
		{"id": "familiar_cat", "name": "Mystic Black Cat", "desc": "A legendary familiar brimming with luck and mystery. Cannot be merged or sold. Sacrifice at Candle or Mystic Tree for Gold or EXP!", "tex": preload("res://assets/items/witch/familiars/cat.png")}
	]
	for f in familiar_defs:
		var it := _register_item(
			f.id, "familiars", "Familiars", 1, 1,
			f.name, f.desc,
			Color(0.45, 0.35, 0.60), f.tex
		)
		it.is_familiar = true
		it.sell_value = 0

func _get_mystic_tree_pool(tier: int) -> Array[String]:
	match tier:
		3:
			# Mystic Tree Lv.3 (Starter Spawner): Strictly Level 1 items only (Shroom Lv.1 & Wand Lv.1)
			return ["shroom_1", "wand_1"]
		4:
			# Mystic Tree Lv.4: 85% Lv.1, 15% Lv.2
			return [
				"shroom_1", "shroom_1", "shroom_1", "shroom_1",
				"wand_1", "wand_1", "wand_1", "wand_1",
				"shroom_2", "wand_2"
			]
		5:
			# Mystic Tree Lv.5: 65% Lv.1, 25% Lv.2, 10% Staff Lv.1
			return [
				"shroom_1", "shroom_1", "shroom_1", "wand_1", "wand_1", "wand_1",
				"shroom_2", "shroom_2", "wand_2", "wand_2",
				"staff_1"
			]
		6:
			# Mystic Tree Lv.6: 40% Lv.1, 30% Lv.2, 20% Lv.3, 5% Staff, 5% Broom
			return [
				"shroom_1", "shroom_1", "wand_1", "wand_1",
				"shroom_2", "shroom_2", "wand_2", "wand_2",
				"shroom_3", "wand_3", "staff_1", "broom_1"
			]
		_:
			return ["shroom_1", "wand_1"]

func _get_shroom_pool(tier: int) -> Array[String]:
	match tier:
		3:
			# Shroom Lv.3 (Starter Spawner): Strictly Level 1 items only (Candle Lv.1)
			return ["candle_1"]
		4:
			# Shroom Lv.4: 80% Candle Lv.1, 10% Candle Lv.2, 10% Spellbook Lv.1
			return [
				"candle_1", "candle_1", "candle_1", "candle_1", "candle_1",
				"candle_1", "candle_1", "candle_1",
				"candle_2", "spellbook_1"
			]
		5:
			# Shroom Lv.5: 50% Lv.1, 30% Lv.2, 10% Lv.3, 10% Spellbook
			return [
				"candle_1", "candle_1", "candle_1", "candle_1", "candle_1",
				"candle_2", "candle_2", "candle_2", "candle_3",
				"spellbook_1"
			]
		6:
			# Shroom Lv.6: 30% Lv.2, 30% Lv.3, 20% Lv.4, 10% Spellbook 1, 10% Spellbook 2
			return [
				"candle_2", "candle_2", "candle_2",
				"candle_3", "candle_3", "candle_3",
				"candle_4", "candle_4",
				"spellbook_1", "spellbook_2"
			]
		_:
			return ["candle_1"]

func _register_color_chests() -> void:
	var chest_charges := [5, 8, 12, 18]

	# 4.1 Purple Chest Chain (EXP Focus)
	var purple_textures := [
		preload("res://assets/items/rewards/chest/purple/1.png"),
		preload("res://assets/items/rewards/chest/purple/2.png"),
		preload("res://assets/items/rewards/chest/purple/3.png"),
		preload("res://assets/items/rewards/chest/purple/4.png")
	]
	var purple_names := [
		"Mystic EXP Chest", "Glowing Arcane Chest", "Astral EXP Vault", "Celestial EXP Coffer"
	]
	var purple_descs := [
		"A magical purple chest radiating player experience! High chance to drop EXP shards and appliance parts. Tap to open!",
		"A glowing arcane chest packed with vibrant EXP embers and appliance parts. Tap to open!",
		"A magnificent astral vault overflowing with high tier EXP stars and appliances. Tap to open!",
		"A legendary celestial coffer with supreme EXP orbs and appliances. Max tier chest!"
	]
	for t in range(1, 5):
		var id := "chest_purple_%d" % t
		var it := _register_item(
			id, "chest_purple", "Purple Chest", t, 4,
			purple_names[t - 1], purple_descs[t - 1],
			Color(0.78, 0.45, 1.0), purple_textures[t - 1]
		)
		it.is_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = chest_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.disappears_when_exhausted = true
		it.sell_value = int(pow(2, t) * 5)
		it.spawn_pool = _get_purple_chest_pool(t)

	# 4.2 Green Chest Chain (Energy Focus)
	var green_textures := [
		preload("res://assets/items/rewards/chest/green/1.png"),
		preload("res://assets/items/rewards/chest/green/2.png"),
		preload("res://assets/items/rewards/chest/green/3.png"),
		preload("res://assets/items/rewards/chest/green/4.png")
	]
	var green_names := [
		"Vitality Energy Chest", "Surging Energy Chest", "Overcharged Energy Vault", "Infinite Energy Coffer"
	]
	var green_descs := [
		"A vibrant green chest humming with vitality! High chance to drop Energy and appliance parts. Tap to open!",
		"A surging emerald chest packed with powerful energy batteries and appliance parts. Tap to open!",
		"An overcharged jade vault containing massive energy cells and appliances. Tap to open!",
		"A legendary infinite energy coffer that restores immense power. Max tier chest!"
	]
	for t in range(1, 5):
		var id := "chest_green_%d" % t
		var it := _register_item(
			id, "chest_green", "Green Chest", t, 4,
			green_names[t - 1], green_descs[t - 1],
			Color(0.25, 0.92, 0.55), green_textures[t - 1]
		)
		it.is_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = chest_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.disappears_when_exhausted = true
		it.sell_value = int(pow(2, t) * 5)
		it.spawn_pool = _get_green_chest_pool(t)

	# 4.3 Yellow Chest Chain (Gold Focus)
	var yellow_textures := [
		preload("res://assets/items/rewards/chest/yellow/1.png"),
		preload("res://assets/items/rewards/chest/yellow/2.png"),
		preload("res://assets/items/rewards/chest/yellow/3.png"),
		preload("res://assets/items/rewards/chest/yellow/4.png")
	]
	var yellow_names := [
		"Gilded Gold Chest", "Treasure Gold Chest", "Royal Gold Vault", "Emperor's Gold Coffer"
	]
	var yellow_descs := [
		"A shining golden chest filled with riches! High chance to drop coins and appliance parts. Tap to open!",
		"A heavy treasure chest stacked with coin piles and appliance parts. Tap to open!",
		"A royal treasury vault brimming with velvet pouches of gold and appliances. Tap to open!",
		"A legendary imperial coffer overflowing with golden wealth. Max tier chest!"
	]
	for t in range(1, 5):
		var id := "chest_yellow_%d" % t
		var it := _register_item(
			id, "chest_yellow", "Yellow Chest", t, 4,
			yellow_names[t - 1], yellow_descs[t - 1],
			Color(1.0, 0.82, 0.2), yellow_textures[t - 1]
		)
		it.is_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = chest_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.disappears_when_exhausted = true
		it.sell_value = int(pow(2, t) * 5)
		it.spawn_pool = _get_yellow_chest_pool(t)

	# 4.4 Blue Chest Chain (Diamond Focus)
	var blue_textures := [
		preload("res://assets/items/rewards/chest/blue/1.png"),
		preload("res://assets/items/rewards/chest/blue/2.png"),
		preload("res://assets/items/rewards/chest/blue/3.png"),
		preload("res://assets/items/rewards/chest/blue/4.png")
	]
	var blue_names := [
		"Sapphire Diamond Chest", "Crystal Diamond Chest", "Radiant Diamond Vault", "Starlight Diamond Coffer"
	]
	var blue_descs := [
		"A crystalline blue chest shimmering with rare gems! High chance to drop Diamonds and appliance parts. Tap to open!",
		"A brilliant crystal chest with cut diamonds and appliance parts. Tap to open!",
		"A dazzling sapphire vault with radiant diamond gems and appliances. Tap to open!",
		"A legendary starlight coffer packed with precious diamonds. Max tier chest!"
	]
	for t in range(1, 5):
		var id := "chest_blue_%d" % t
		var it := _register_item(
			id, "chest_blue", "Blue Chest", t, 4,
			blue_names[t - 1], blue_descs[t - 1],
			Color(0.35, 0.75, 1.0), blue_textures[t - 1]
		)
		it.is_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = chest_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.disappears_when_exhausted = true
		it.sell_value = int(pow(2, t) * 5)
		it.spawn_pool = _get_blue_chest_pool(t)

func _get_purple_chest_pool(tier: int, is_farm: bool = false, is_witch: bool = false) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		1:
			pool = ["exp_1", "exp_1", "exp_1", "exp_1"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "foodbox_1"])
		2:
			pool = ["exp_1", "exp_1", "exp_2", "exp_2"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "fridge_1", "foodbox_1"])
		3:
			pool = ["exp_2", "exp_2", "exp_3", "exp_3"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1", "wand_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1", "pine_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"])
		_:
			pool = ["exp_3", "exp_3", "exp_4", "exp_4", "exp_5"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1", "wand_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1", "pine_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"])
	return pool

func _get_green_chest_pool(tier: int, is_farm: bool = false, is_witch: bool = false) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		1:
			pool = ["energy_1", "energy_1", "energy_1", "energy_1"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "foodbox_1"])
		2:
			pool = ["energy_1", "energy_1", "energy_2", "energy_2"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "fridge_1", "foodbox_1"])
		3:
			pool = ["energy_2", "energy_2", "energy_3", "energy_3"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1", "wand_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1", "pine_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"])
		_:
			pool = ["energy_3", "energy_3", "energy_4", "energy_4", "energy_5"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1", "wand_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1", "pine_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"])
	return pool

func _get_yellow_chest_pool(tier: int, is_farm: bool = false, is_witch: bool = false) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		1:
			pool = ["gold_1", "gold_1", "gold_1", "gold_1"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "foodbox_1"])
		2:
			pool = ["gold_1", "gold_1", "gold_2", "gold_2"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "fridge_1", "foodbox_1"])
		3:
			pool = ["gold_2", "gold_2", "gold_3", "gold_3"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1", "wand_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1", "pine_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"])
		_:
			pool = ["gold_3", "gold_3", "gold_4", "gold_4", "gold_5"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1", "wand_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1", "pine_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"])
	return pool

func _get_blue_chest_pool(tier: int, is_farm: bool = false, is_witch: bool = false) -> Array[String]:
	var pool: Array[String] = []
	match tier:
		1:
			pool = ["diamond_1", "diamond_1", "diamond_1", "diamond_1"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "foodbox_1"])
		2:
			pool = ["diamond_1", "diamond_1", "diamond_2", "diamond_2"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "fridge_1", "foodbox_1"])
		3:
			pool = ["diamond_2", "diamond_2", "diamond_3", "diamond_3"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1", "wand_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1", "pine_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"])
		_:
			pool = ["diamond_3", "diamond_3", "diamond_4", "diamond_4", "diamond_5"]
			if is_witch:
				pool.append_array(["mystic_tree_1", "cauldron_1", "shroom_1", "wand_1"])
			elif is_farm:
				pool.append_array(["barn_1", "water_1", "tree_1", "pine_1"])
			else:
				pool.append_array(["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"])
	return pool


func _register_kitchen_items() -> void:
	var beta_tex: Texture2D = preload("res://assets/items/beta_item.png")

	# -------------------------------------------------------------------------
	# 1.1 Pantry Chain (10 Tiers, produces healthy & staples)
	# -------------------------------------------------------------------------
	var pantry_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/foodbox/food1.png"),
		preload("res://assets/items/kitchen/foodbox/food2.png"),
		preload("res://assets/items/kitchen/foodbox/food3.png"),
		preload("res://assets/items/kitchen/foodbox/food4.png"),
		preload("res://assets/items/kitchen/foodbox/food5.png"),
		preload("res://assets/items/kitchen/foodbox/food6.png"),
		beta_tex, beta_tex, beta_tex, beta_tex
	]
	var pantry_names := [
		"Wooden Pantry Crate", "Reinforced Pantry Bin", "Pantry Box",
		"Chef's Produce Bin", "Gourmet Harvest Locker", "Master Walk-in Pantry",
		"Artisan Food Cellar", "Deluxe Culinary Larder", "Imperial Farm Pantry", "Grand Master Gastronomy Vault"
	]
	var pantry_descs := [
		"A small wooden storage crate. Merge to tier 3 to create a fresh pantry spawner!",
		"A reinforced produce storage bin. Merge to tier 3 to create a fresh pantry spawner!",
		"A well-stocked kitchen pantry box. Tap to produce healthy food and staples! Uses 1 Energy.",
		"Chef's selection produce bin with fresh ingredients. Uses 1 Energy.",
		"Gourmet harvest locker packed with kitchen staples and fresh items. Uses 1 Energy.",
		"Spacious master pantry vault producing high-quality culinary essentials. Uses 1 Energy.",
		"Artisan food cellar! Produces healthy items, staples, and drops Grocery Bags. Uses 1 Energy.",
		"Deluxe culinary larder! Drops healthy items, staples, Grocery Bags, and Seed Packets. Uses 1 Energy.",
		"Imperial farm pantry! Drops healthy items, staples, temp spawners, and rare Golden Hens! Uses 1 Energy.",
		"Supreme culinary vault! Packed with elite ingredients and wondrous temporary spawners. Uses 1 Energy."
	]
	for t in range(1, 11):
		var it := _register_item(
			"pantry_%d" % t, "pantry", "Pantry", t, 10,
		pantry_names[t - 1], pantry_descs[t - 1],
			Color(0.88, 0.65, 0.35), pantry_textures[t - 1]
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_pantry_pool(t)

	# -------------------------------------------------------------------------
	# 1.2 Oven Chain (10 Tiers, produces bakery & sweets)
	# -------------------------------------------------------------------------
	var oven_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/oven/oven_1.png"),
		preload("res://assets/items/kitchen/oven/oven_2.png"),
		preload("res://assets/items/kitchen/oven/oven_3.png"),
		preload("res://assets/items/kitchen/oven/oven_4.png"),
		preload("res://assets/items/kitchen/oven/oven_5.png"),
		preload("res://assets/items/kitchen/oven/oven_6.png"),
		beta_tex, beta_tex, beta_tex, beta_tex
	]
	var oven_names := [
		"Clay Toaster", "Stone Stove", "Brick Baker",
		"Stainless Oven", "Pastry Range", "Grand Master Oven",
		"Artisan Deck Oven", "Hearth Stone Roaster", "Convection Master Range", "Supreme Culinary Blast Oven"
	]
	var oven_descs := [
		"A small clay toaster. Merge to tier 3 to bake delicious bakery goods and sweets!",
		"A sturdy stone hearth with steady baking heat. Merge to tier 3 to bake!",
		"Traditional brick baker for warm breads and sweet treats. Uses 1 Energy.",
		"Precision stainless steel baking oven. Uses 1 Energy.",
		"Professional pastry and cake range. Uses 1 Energy.",
		"Grand culinary oven! Bakes gourmet bakery and delicate sweets. Uses 1 Energy.",
		"Artisan deck oven! Produces bakery & sweets, and drops Sourdough Starters. Uses 1 Energy.",
		"Hearth stone roaster! Produces bakery, sweets, Sourdough Starters, and Ice Cream Carts. Uses 1 Energy.",
		"Convection master range! Fast baking and frequent temporary spawner drops. Uses 1 Energy.",
		"Supreme blast oven! The pinnacle of baking mastery. Uses 1 Energy."
	]
	for t in range(1, 11):
		var it := _register_item(
			"oven_%d" % t, "oven", "Oven", t, 10,
			oven_names[t - 1], oven_descs[t - 1],
			Color(0.95, 0.45, 0.28), oven_textures[t - 1]
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_oven_pool(t)

	# -------------------------------------------------------------------------
	# 1.3 Burner Chain (10 Tiers, produces grill & noodle)
	# -------------------------------------------------------------------------
	var burner_names := [
		"Portable Camping Stove", "Single Gas Burner", "Dual Kitchen Cooktop",
		"Cast-Iron Wok Burner", "Commercial High-BTU Range", "Chef's Turbo Wok Station",
		"Precision Induction Master", "Dual Dragon Flame Cooker", "Imperial Teppanyaki Station", "Celestial Inferno Range"
	]
	var burner_descs := [
		"A portable camping stove. Merge to tier 3 to sizzle grilled dishes and boil noodles!",
		"A single gas burner with focused flame. Merge to tier 3 to start cooking!",
		"Dual kitchen cooktop! Tap to cook grilled specialties and fresh noodles! Uses 1 Energy.",
		"Heavy cast-iron burner with intense stir-fry heat. Uses 1 Energy.",
		"Commercial restaurant range delivering blistering searing heat. Uses 1 Energy.",
		"Turbo-charged wok station! Produces savory grill items and aromatic noodle bowls. Uses 1 Energy.",
		"Precision induction master! Produces grill, noodles, and drops Fortune Cookie Jars. Uses 1 Energy.",
		"Dual dragon flame cooker! High-heat grill and noodle perfection. Uses 1 Energy.",
		"Imperial teppanyaki master station! High-tier grill, noodle, and temporary spawner drops. Uses 1 Energy.",
		"Celestial inferno range! Legendary stove capable of mythical gastronomic creations. Uses 1 Energy."
	]
	for t in range(1, 11):
		var it := _register_item(
			"burner_%d" % t, "burner", "Burner", t, 10,
			burner_names[t - 1], burner_descs[t - 1],
			Color(0.98, 0.4, 0.2), beta_tex
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_burner_pool(t)

	# -------------------------------------------------------------------------
	# 1.4 Fridge Chain (10 Tiers, produces drinks & dairy)
	# -------------------------------------------------------------------------
	var fridge_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/fridge/fridge1.png"),
		preload("res://assets/items/kitchen/fridge/fridge2.png"),
		preload("res://assets/items/kitchen/fridge/fridge3.png"),
		preload("res://assets/items/kitchen/fridge/fridge4.png"),
		preload("res://assets/items/kitchen/fridge/fridge5.png"),
		preload("res://assets/items/kitchen/fridge/fridge6.png"),
		beta_tex, beta_tex, beta_tex, beta_tex
	]
	var fridge_names := [
		"Mini Icebox", "Retro Cooler", "Kitchen Refrigerator",
		"Double-Door Chiller", "Beverage Dispenser", "Master Cryo Chiller",
		"Commercial Cold Vault", "Zero-Frost Prep Station", "Sub-Zero Gourmet Chiller", "Absolute Zero Preservation Chamber"
	]
	var fridge_descs := [
		"A compact mini icebox. Merge to tier 3 to dispense refreshing drinks and dairy!",
		"A cool retro cooler keeping drinks and milk icy fresh. Merge to tier 3!",
		"Standard household fridge dispensing chilled drinks and fresh dairy. Uses 1 Energy.",
		"Double-door chiller with rapid cooling. Uses 1 Energy.",
		"Commercial glass-front beverage & dairy cooler. Uses 1 Energy.",
		"Supreme cryo chiller! Dispenses premium drinks and rich dairy. Uses 1 Energy.",
		"Commercial cold vault! Drops drinks, dairy, and Grocery Bags. Uses 1 Energy.",
		"Zero-frost station! Drops drinks, dairy, Grocery Bags, and Ice Cream Carts. Uses 1 Energy.",
		"Sub-zero gourmet chiller! High-tier drinks, dairy, and temp spawners. Uses 1 Energy.",
		"Absolute zero preservation chamber! Master of cold refreshments and artisanal dairy. Uses 1 Energy."
	]
	for t in range(1, 11):
		var it := _register_item(
			"fridge_%d" % t, "fridge", "Fridge", t, 10,
			fridge_names[t - 1], fridge_descs[t - 1],
			Color(0.35, 0.72, 0.95), fridge_textures[t - 1]
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_fridge_pool(t)

	# -------------------------------------------------------------------------
	# 1.5 Rack Chain (10 Tiers, produces utils & random temp spawners)
	# -------------------------------------------------------------------------
	var rack_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/rack/rack1.png"),
		preload("res://assets/items/kitchen/rack/rack2.png"),
		preload("res://assets/items/kitchen/rack/rack3.png"),
		preload("res://assets/items/kitchen/rack/rack4.png"),
		preload("res://assets/items/kitchen/rack/rack5.png"),
		preload("res://assets/items/kitchen/rack/rack6.png"),
		preload("res://assets/items/kitchen/rack/rack7.png"),
		beta_tex, beta_tex, beta_tex
	]
	var rack_names := [
		"Small Pegboard", "Wooden Utensil Stand", "Metal Tool Rack",
		"Chef's Cutlery Caddy", "Magnetic Tool Bar", "Master Prep Station", "Grand Kitchen Arsenal",
		"Professional Wall Matrix", "High-Tech Culinary Hub", "Infinite Chef's Command Station"
	]
	var rack_descs := [
		"A small wooden pegboard. Merge to tier 3 to produce culinary gear and tools!",
		"Organized wooden stand holding basic utensils. Merge to tier 3 to produce gear!",
		"Stainless steel kitchen utensil rack. Uses 1 Energy.",
		"Heavy-duty cutlery caddy with culinary gear. Uses 1 Energy.",
		"Chef-grade magnetic organizer bar. Uses 1 Energy.",
		"Modular prep station with specialized cooking tools. Uses 1 Energy.",
		"Grand kitchen arsenal! Spawns utensils and Chef's Toolboxes. Uses 1 Energy.",
		"Professional wall matrix! Spawns utensils, Chef's Toolboxes, and Fortune Cookie Jars. Uses 1 Energy.",
		"Supreme culinary hub! Spawns utensils and random temporary spawners. Uses 1 Energy.",
		"Infinite command station! Ultimate tool organizer with frequent temporary spawner drops. Uses 1 Energy."
	]
	for t in range(1, 11):
		var it := _register_item(
			"rack_%d" % t, "rack", "Rack", t, 10,
			rack_names[t - 1], rack_descs[t - 1],
			Color(0.65, 0.55, 0.75), rack_textures[t - 1]
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_rack_pool(t)

	# -------------------------------------------------------------------------
	# 2.1 Healthy Food Chain (16 Tiers, replaces Eggs)
	# -------------------------------------------------------------------------
	var healthy_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/eggs/egg_0.png"),
		preload("res://assets/items/kitchen/eggs/egg_1.png"),
		preload("res://assets/items/kitchen/eggs/egg_2.png"),
		preload("res://assets/items/kitchen/eggs/egg_3.png"),
		preload("res://assets/items/kitchen/eggs/egg_4.png"),
		preload("res://assets/items/kitchen/eggs/egg_5.png"),
		beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex
	]
	var healthy_names := [
		"Fresh Farm Egg", "Boiled Egg & Chives", "Sunny Side Toast", "Avocado Egg Bowl",
		"Poached Egg Benedict", "Garden Omelet Supreme", "Grilled Chicken Caesar", "Superfood Quinoa Bowl",
		"Salmon Avocado Tartare", "Mediterranean Feast Salad", "Rainbow Poke Bowl", "Mezze Platter",
		"Michelin Protein Feast", "Gourmet Wellness Banquet", "Vitality Ambrosia Platter", "Celestial Healthy Feast"
	]
	var healthy_descs := [
		"A smooth white egg, fresh from the farm.",
		"Gently soft-boiled egg sprinkled with fresh garden chives.",
		"Golden toasted sourdough topped with a sunny-side farm egg.",
		"A nutritious breakfast bowl of creamy avocado and eggs.",
		"Silky poached egg drenched in velvety hollandaise sauce.",
		"Fluffy three-egg omelet loaded with crisp garden vegetables.",
		"Tender grilled chicken breast over fresh romaine and shaved parmesan.",
		"Nutrient-dense warm quinoa bowl packed with roasted veggies and seeds.",
		"Delicately seasoned fresh salmon and avocado tartare.",
		"Vibrant Mediterranean salad loaded with olives, feta, and olive oil.",
		"Colorful poke bowl with marinated tuna, edamame, and sesame crunch.",
		"Magnificent royal Mezze Platter with dips, falafel, and artisan flatbread!",
		"Three-star Michelin wellness feast balanced to culinary perfection.",
		"An extravagant banquet celebrating pure wholesome ingredients.",
		"Mythical vitality platter overflowing with supreme wholesome delights.",
		"The legendary Celestial Healthy Feast! Max tier healthy cuisine."
	]
	for t in range(1, 17):
		_register_item(
			"healthy_%d" % t, "healthy", "Healthy Food", t, 16,
			healthy_names[t - 1], healthy_descs[t - 1],
			Color(0.96, 0.93, 0.88), healthy_textures[t - 1]
		)

	# -------------------------------------------------------------------------
	# 2.2 Pantry Staples Chain (16 Tiers, replaces leaf)
	# -------------------------------------------------------------------------
	var staples_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/leafs/leaf_0.png"),
		preload("res://assets/items/kitchen/leafs/leaf_1.png"),
		preload("res://assets/items/kitchen/leafs/leaf_2.png"),
		preload("res://assets/items/kitchen/leafs/leaf_3.png"),
		preload("res://assets/items/kitchen/leafs/leaf_4.png"),
		beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex
	]
	var staples_names := [
		"Fresh Herb Leaf", "Crisp Celery Stalk", "Spinach Bundle", "Garden Cabbage",
		"Crispy Farm Greens", "Fresh Garlic & Onions", "Crushed Sea Salt & Pepper", "Extra Virgin Olive Oil",
		"Aged Balsamic Vinegar", "Saffron & Spice Jar", "Truffle Butter", "Aged Soy Reserve",
		"Imperial Spice Blend", "Gourmet Umami Essence", "Grand Master Secret Seasoning", "Divine Culinary Elixir"
	]
	var staples_descs := [
		"A fragrant culinary herb, fresh from the kitchen garden.",
		"A crunchy stalk packed with aromatic flavor.",
		"A vibrant bundle of farm-fresh spinach greens.",
		"A hearty head of crisp green cabbage.",
		"Freshly harvested crisp leafy greens.",
		"Aromatic bulbs of pungent garlic and golden kitchen onions.",
		"Coarse hand-harvested sea salt and tellicherry peppercorns.",
		"Cold-pressed single-estate extra virgin olive oil.",
		"Oak-barrel aged rich balsamic vinegar glaze.",
		"A precious jar of vibrant crimson saffron threads.",
		"Silky churned butter infused with black summer truffles.",
		"Centuries-old aged master soy sauce reserve.",
		"Exotic blend of hand-ground royal spices and fragrant herbs.",
		"Concentrated culinary essence that elevates any dish.",
		"Secret seasoning formula passed down through generations of master chefs.",
		"The mythical Divine Culinary Elixir! Max tier pantry staple."
	]
	for t in range(1, 17):
		_register_item(
			"staples_%d" % t, "staples", "Pantry Staples", t, 16,
			staples_names[t - 1], staples_descs[t - 1],
			Color(0.35, 0.82, 0.32), staples_textures[t - 1]
		)

	# -------------------------------------------------------------------------
	# 2.3 Bakery Chain (16 Tiers)
	# -------------------------------------------------------------------------
	var bakery_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/sandwich/sandwich1.png"),
		preload("res://assets/items/kitchen/sandwich/sandwich2.png"),
		preload("res://assets/items/kitchen/sandwich/sandwich3.png"),
		preload("res://assets/items/kitchen/sandwich/sandwich4.png"),
		preload("res://assets/items/kitchen/sandwich/sandwich5.png"),
		preload("res://assets/items/kitchen/sandwich/sandwich6.png"),
		beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex
	]
	var bakery_names := [
		"Bread Dough", "Dinner Roll", "Pretzel Knot", "French Baguette",
		"Sourdough Loaf", "Croissant", "Danish Pastry", "Cinnamon Swirl",
		"Challah Braid", "Brioche Loaf", "Focaccia Herb Bread", "Wheat Sheaf Loaf",
		"Artisan Pain de Campagne", "Master Baker's Showcase", "Royal Palace Bread", "Legendary Golden Loaf"
	]
	var bakery_descs := [
		"Kneaded bread dough slowly rising under a linen cloth.",
		"A warm, golden-brown dinner roll with a soft fluffy crumb.",
		"Traditional Bavarian pretzel baked with coarse salt flakes.",
		"Crusty French baguette with an airy open crumb.",
		"Slow-fermented rustic artisan sourdough loaf with a blistered crust.",
		"Flaky, golden, buttery layered French croissant. Finished bread shortcut!",
		"Crisp layered pastry filled with sweet custard and fruit.",
		"Fragrant rolled cinnamon pastry glazed with icing sugar. Finished bread shortcut!",
		"Golden braided holiday challah bread with a glossy egg wash.",
		"Rich, buttery, feather-light French brioche loaf. Finished bread shortcut!",
		"Rosemary and sea salt focaccia dimpled with virgin olive oil.",
		"Magnificent wheat sheaf shaped harvest bread. Finished bread shortcut!",
		"Rustic countryside pain de campagne baked in wood-fired hearths.",
		"An artisan baker's grand centerpiece bread display.",
		"Decadent bread fit for royalty, baked with golden heirloom grains.",
		"The legendary Golden Loaf of gastronomy! Max tier bakery masterpiece."
	]
	for t in range(1, 17):
		_register_item(
			"bakery_%d" % t, "bakery", "Bakery", t, 16,
			bakery_names[t - 1], bakery_descs[t - 1],
			Color(0.92, 0.78, 0.42), bakery_textures[t - 1]
		)

	# -------------------------------------------------------------------------
	# 2.4 Sweets Chain (16 Tiers)
	# -------------------------------------------------------------------------
	var sweets_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/cake/cake_1.png"),
		preload("res://assets/items/kitchen/cake/cake_2.png"),
		preload("res://assets/items/kitchen/cake/cake_3.png"),
		preload("res://assets/items/kitchen/cake/cake_4.png"),
		preload("res://assets/items/kitchen/cake/cake_5.png"),
		preload("res://assets/items/kitchen/cake/cake_6.png"),
		beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex
	]
	var sweets_names := [
		"Sugar Cookie", "Fluffy Cupcake", "Berry Tart", "Vanilla Sponge Roll",
		"Chocolate Donut", "Cream Layer Cake", "Strawberry Shortcake", "Decadent Chocolate Gateau",
		"Macaron Tower", "Mille-Feuille", "Royal Tiramisu", "Grand Croquembouche",
		"Golden Opera Cake", "Imperial Soufflé", "Royal Palace Confection", "Celestial Sugar Sculpture"
	]
	var sweets_descs := [
		"Crisp buttery sugar cookie with a sprinkle of sugar crystals.",
		"Soft fluffy vanilla cupcake topped with swirl buttercream.",
		"Crisp pastry tart filled with rich custard and fresh berries.",
		"Delicate sponge rolled with sweet raspberry preserve.",
		"Glazed chocolate donut covered with colorful sprinkles.",
		"Multi-layered sponge cake frosted with vanilla whipped cream.",
		"Fluffy biscuit layered with macerated sweet strawberries and cream.",
		"Rich dark chocolate gateau with mirror glaze.",
		"Tower of pastel almond macarons in assorted gourmet flavors.",
		"Classic French thousand-layer pastry with rich vanilla bean cream.",
		"Espresso-soaked ladyfingers layered with velvety mascarpone.",
		"Towering cone of cream puffs bound with spun caramel threads.",
		"Decadent multi-layer almond sponge, coffee syrup, and chocolate ganache.",
		"Puffed golden soufflé served warm with crème anglaise.",
		"An extravagant dessert spread fit for a royal court.",
		"Breathtaking crystalline spun sugar sculpture! Max tier sweet creation."
	]
	for t in range(1, 17):
		_register_item(
			"sweets_%d" % t, "sweets", "Sweets", t, 16,
			sweets_names[t - 1], sweets_descs[t - 1],
			Color(0.96, 0.65, 0.78), sweets_textures[t - 1]
		)

	# -------------------------------------------------------------------------
	# 2.5 Grill Chain (16 Tiers)
	# -------------------------------------------------------------------------
	var grill_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/beef/beef_1.png"),
		preload("res://assets/items/kitchen/beef/beef_2.png"),
		preload("res://assets/items/kitchen/beef/beef_3.png"),
		preload("res://assets/items/kitchen/beef/beef_4.png"),
		preload("res://assets/items/kitchen/beef/beef_5.png"),
		preload("res://assets/items/kitchen/beef/beef_6.png"),
		preload("res://assets/items/kitchen/beef/beef_7.png"),
		beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex
	]
	var grill_names := [
		"Skewered Veggies", "Grilled Sausage", "Seasoned Burger Patty", "BBQ Chicken Skewer",
		"Glazed Pork Ribs", "Grilled Lamb Chop", "Charbroiled Ribeye", "Hickory Smoked Brisket",
		"Seared Tomahawk Steak", "Korean BBQ Galbi Feast", "Brazilian Churrasco Board", "A5 Wagyu Ribcap",
		"Smoked Prime Rib Crown", "Master Chef's BBQ Platter", "Imperial Feast of Embers", "Mythic Phoenix Grill"
	]
	var grill_descs := [
		"Fire-roasted vegetable skewer with sweet peppers and mushrooms.",
		"Sizzling pork sausage grilled with smoke marks.",
		"Juicy seasoned patty grilled over open coals.",
		"Smoky marinated barbecue chicken skewer.",
		"Slow-cooked pork ribs with a sticky sweet glaze.",
		"Tender herb-crusted lamb chop seared over charcoal.",
		"Thick cut ribeye steak with golden brown sear.",
		"Hickory smoked beef brisket with a dark peppery bark.",
		"Long-bone tomahawk steak seared over roaring oak wood.",
		"Marinated Korean short ribs sizzling over charcoal.",
		"Array of churrasco meats sliced fresh from the skewer.",
		"Heavily marbled A5 Japanese Wagyu steak that melts on the tongue.",
		"Towering golden prime rib roast crowned with rosemary.",
		"Pitmaster's ultimate barbecue tasting platter.",
		"An imperial charcoal banquet of prime cuts and roasting embers.",
		"The legendary Phoenix Grill! Max tier flaming culinary triumph."
	]
	for t in range(1, 17):
		_register_item(
			"grill_%d" % t, "grill", "Grill", t, 16,
			grill_names[t - 1], grill_descs[t - 1],
			Color(0.85, 0.32, 0.3), grill_textures[t - 1]
		)

	# -------------------------------------------------------------------------
	# 2.6 Noodle Chain (16 Tiers)
	# -------------------------------------------------------------------------
	var noodle_names := [
		"Hand-Pulled Dough", "Fresh Noodle Strands", "Simple Clear Broth Noodle", "Garlic Butter Noodles",
		"Savory Yakisoba", "Spicy Dan Dan Mian", "Rich Tonkotsu Ramen", "Pad Thai Deluxe",
		"Beef Pho Bowl", "Handmade Udon with Tempura", "Lobster Truffle Tagliatelle", "Singapore Golden Laksa",
		"Imperial Lanzhou Beef Noodle", "Grand Master Dragon Noodle", "Celestial Broth Noodle", "Legend of the Golden Silk Noodle"
	]
	var noodle_descs := [
		"Smooth, elastic wheat dough ready to be stretched.",
		"Freshly cut ribbons of artisanal noodle dough.",
		"Light clear broth bowl with tender noodles and spring onions.",
		"Pan-tossed egg noodles rich in roasted garlic and butter.",
		"Stir-fried Japanese street noodles with savory brown sauce.",
		"Sichuan noodles with spicy chili oil and seasoned minced pork.",
		"Simmered 18-hour pork bone ramen with chashu and ajitsuke tamago.",
		"Tangy stir-fried rice noodles with tamarind, prawns, and peanuts.",
		"Fragrant Vietnamese beef bone broth with rice ribbons and herbs.",
		"Thick chewy udon noodles in dashi accompanied by crisp tempura.",
		"Handmade Italian tagliatelle tossed with sweet lobster and black truffle.",
		"Spicy coconut curry soup with thick vermicelli and seafood.",
		"Artisan Lanzhou clear beef soup with precision hand-pulled noodles.",
		"Spectacular dragon noodle masterwork crafted by culinary masters.",
		"Simmered with rare botanical broth and heavenly silken noodles.",
		"The mythical Golden Silk Noodle! Max tier noodle perfection."
	]
	for t in range(1, 17):
		_register_item(
			"noodle_%d" % t, "noodle", "Noodles", t, 16,
			noodle_names[t - 1], noodle_descs[t - 1],
			Color(0.95, 0.75, 0.3), beta_tex
		)

	# -------------------------------------------------------------------------
	# 2.7 Drinks Chain (16 Tiers)
	# -------------------------------------------------------------------------
	var drink_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/drink/drink_1.png"),
		preload("res://assets/items/kitchen/drink/drink_2.png"),
		preload("res://assets/items/kitchen/drink/drink_3.png"),
		preload("res://assets/items/kitchen/drink/drink_4.png"),
		preload("res://assets/items/kitchen/drink/drink_5.png"),
		beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex
	]
	var drink_names := [
		"Pure Spring Water", "Iced Lemonade", "Cold Brew Tea", "Berry Smoothie",
		"Classic Milkshake", "Tropical Punch Bowl", "Mint Lime Mojito", "Matcha Latte Frappe",
		"Sparkling Passion Fruit Soda", "Artisan Cold Brew Float", "Dragonfruit Boba Tea", "Royal Velvet Hot Cocoa",
		"Golden Citrus Fizz", "Elixir of Refreshment", "Imperial Nectar Cocktail", "Celestial Aurora Mocktail"
	]
	var drink_descs := [
		"A refreshing glass of pure chilled natural spring water.",
		"Zesty cold lemonade sweetened with pure cane sugar.",
		"Slow-steeped fragrant black tea served over crystal ice.",
		"Thick blended smoothie with fresh summer berries.",
		"Creamy frothy milkshake with vanilla whipped cream.",
		"Exotic punch bowl with fresh tropical juices.",
		"Crushed mint and lime soda mocktail with sparkling bubbles.",
		"Earthy ceremonial matcha blended into an icy sweet frappe.",
		"Tart sparkling soda infused with golden passion fruit seeds.",
		"Slow-drip artisan cold brew topped with vanilla bean gelato.",
		"Vibrant magenta dragonfruit iced tea with chewy brown sugar pearls.",
		"Rich spiced drinking chocolate melted with velvet dairy.",
		"Effervescent golden citrus tonic infused with fragrant herbs.",
		"Alchemical drink that completely revitalizes mind and body.",
		"Gourmet layered cocktail served in an imperial crystal goblet.",
		"The luminous Celestial Aurora Mocktail! Max tier refreshing beverage."
	]
	for t in range(1, 17):
		_register_item(
			"drinks_%d" % t, "drinks", "Drinks", t, 16,
			drink_names[t - 1], drink_descs[t - 1],
			Color(0.35, 0.85, 0.95), drink_textures[t - 1]
		)

	# -------------------------------------------------------------------------
	# 2.8 Dairy Chain (16 Tiers)
	# -------------------------------------------------------------------------
	var dairy_textures: Array[Texture2D] = [
		preload("res://assets/items/farm/milk/1.png"),
		preload("res://assets/items/farm/milk/2.png"),
		preload("res://assets/items/farm/milk/3.png"),
		preload("res://assets/items/farm/milk/4.png"),
		preload("res://assets/items/farm/milk/5.png"),
		preload("res://assets/items/farm/milk/6.png"),
		preload("res://assets/items/farm/milk/7.png"),
		preload("res://assets/items/farm/milk/8.png"),
		beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex, beta_tex
	]
	var dairy_names := [
		"Fresh Milk Bottle", "Heavy Cream Carton", "Churned Golden Butter", "Cottage Cheese Tub",
		"Fresh Mozzarella Ball", "Greek Yogurt Parfait", "Sharp Farmhouse Cheddar", "Wheel of Gouda",
		"Creamy French Brie", "Aged Emmental Wedge", "Gorgonzola Blue Cheese", "Reserve Parmigiano Reggiano",
		"Truffle Infused Pecorino", "Grand Dairy Artisanal Platter", "Royal Fromagerie Selection", "Celestial Golden Ambrosia Cheese"
	]
	var dairy_descs := [
		"A cool glass bottle of whole farm-fresh cow's milk.",
		"Rich pasture cream perfect for whipping and cooking.",
		"Sweet cream churned into silky golden country butter.",
		"Light and curd-rich fresh cottage cheese.",
		"Soft porcelain-white ball of fresh buffalo mozzarella.",
		"Thick strained Greek yogurt topped with raw clover honey.",
		"Cave-aged sharp cheddar cheese with crunchy salt crystals.",
		"Waxed round wheel of golden buttery Dutch Gouda.",
		"Velvety soft-ripened French cheese with a buttery bloomy rind.",
		"Traditional Swiss cheese with classic eyes and nutty aroma.",
		"Bold and creamy Italian blue-veined mountain cheese.",
		"Hard aged Italian cheese wheel aged for 36 months.",
		"Sheep's milk pecorino studded with aromatic black truffles.",
		"A master cheesemonger's curated board of fine European cheeses.",
		"An opulent fromagerie spread celebrating historic artisanal creameries.",
		"The legendary Golden Ambrosia Cheese! Max tier dairy achievement."
	]
	for t in range(1, 17):
		_register_item(
			"dairy_%d" % t, "dairy", "Dairy", t, 16,
			dairy_names[t - 1], dairy_descs[t - 1],
			Color(0.98, 0.95, 0.8), dairy_textures[t - 1]
		)

	# -------------------------------------------------------------------------
	# 2.9 Utils Chain (16 Tiers)
	# -------------------------------------------------------------------------
	var util_textures: Array[Texture2D] = [
		preload("res://assets/items/kitchen/utils/util1.png"),
		preload("res://assets/items/kitchen/utils/util2.png"),
		preload("res://assets/items/kitchen/utils/util3.png"),
		preload("res://assets/items/kitchen/utils/util4.png"),
		preload("res://assets/items/kitchen/utils/util5.png"),
		preload("res://assets/items/kitchen/utils/util6.png"),
		preload("res://assets/items/kitchen/utils/util7.png"),
		preload("res://assets/items/kitchen/utils/util8.png"),
		preload("res://assets/items/kitchen/utils/util9.png"),
		preload("res://assets/items/kitchen/utils/util10.png"),
		preload("res://assets/items/kitchen/utils/util11.png"),
		preload("res://assets/items/kitchen/utils/util12.png"),
		beta_tex, beta_tex, beta_tex, beta_tex
	]
	var util_names := [
		"Spoon", "Fork", "Table Knife", "Wire Whisk",
		"Kitchen Spatula", "Soup Ladle", "Rolling Pin", "Chef's Cleaver",
		"Vegetable Grater", "Copper Kettle", "Cast Pot", "Golden Master Skillet",
		"Damascus Santoku Knife", "Precision Immersion Circulator", "Diamond Sharpened Set", "Mythic Excalibur Chef's Blade"
	]
	var util_descs := [
		"A basic dining spoon.",
		"A shiny stainless steel fork.",
		"A sharp dining table knife.",
		"Flexible wire whisk for eggs and creams.",
		"Heat-resistant cooking spatula.",
		"Deep ladle for hot soups and sauces.",
		"Smooth hardwood pastry rolling pin.",
		"Heavy culinary cleaver for prep work.",
		"Four-sided stainless grating tool.",
		"Charming whistling stovetop copper kettle.",
		"Heavy-duty heirloom cast cooking pot.",
		"The famous golden chef's skillet.",
		"Folded Japanese Damascus steel knife with laser-sharp edge.",
		"Laboratory-grade sous vide precision circulator for flawless cooking.",
		"Master cutlery set honed with industrial diamond powder.",
		"The legendary Mythic Excalibur Blade! Max tier chef utensil."
	]
	for t in range(1, 17):
		_register_item(
			"util_%d" % t, "util", "Utils", t, 16,
			util_names[t - 1], util_descs[t - 1],
			Color(0.72, 0.76, 0.82), util_textures[t - 1]
		)

func _register_temporary_spawners() -> void:
	var beta_tex: Texture2D = preload("res://assets/items/beta_item.png")

	# -------------------------------------------------------------------------
	# 1. Grocery Bag · CASH-OUT (4 Tiers)
	# -------------------------------------------------------------------------
	var bag_names := ["Paper Bag", "Canvas Tote", "Wicker Basket", "Market Trolley"]
	var bag_charges := [6, 10, 14, 20]
	var bag_convs := ["discount_coupon_1", "discount_coupon_2", "discount_coupon_3", "discount_coupon_4"]
	for t in range(1, 5):
		var it := _register_item(
			"grocery_bag_%d" % t, "grocery_bag", "Grocery Bag", t, 4,
			bag_names[t - 1],
			"A temporary grocery bag with %d charges. Spawns Healthy, Staples, and Dairy. Costs 0 Energy! Converts into a Discount Coupon when exhausted." % bag_charges[t - 1],
			Color(0.85, 0.7, 0.45), beta_tex
		)
		it.is_spawner = true
		it.is_temporary_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = bag_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.exhaust_conversion_id = bag_convs[t - 1]
		it.spawn_pool = _get_grocery_bag_pool(t)

	# Discount Coupon Chain (4 Tiers, produced upon bag exhaustion)
	var coupon_amounts := [25, 60, 150, 400]
	for t in range(1, 5):
		var it := _register_item(
			"discount_coupon_%d" % t, "discount_coupon", "Discount Coupon", t, 4,
			"Discount Coupon (%d Coins)" % coupon_amounts[t - 1],
			"Tap to cash out %d Gold Coins!" % coupon_amounts[t - 1],
			Color(1.0, 0.85, 0.25), beta_tex
		)
		it.is_consumable = true
		it.consume_currency = "coins"
		it.consume_amount = coupon_amounts[t - 1]

	# -------------------------------------------------------------------------
	# 2. Sourdough Starter · RUNG-SKIP (4 Tiers)
	# -------------------------------------------------------------------------
	var starter_names := ["Baby Starter Jar", "Bubbly Starter", "Mature Starter", "Heirloom Starter"]
	var starter_charges := [6, 10, 14, 20]
	var starter_convs := ["bakery_6", "bakery_8", "bakery_10", "bakery_12"]
	for t in range(1, 5):
		var it := _register_item(
			"sourdough_starter_%d" % t, "sourdough_starter", "Sourdough Starter", t, 4,
			starter_names[t - 1],
			"A live starter jar with %d charges. Spawns Bakery items! Costs 0 Energy. Bakes itself into a high-tier bread when exhausted." % starter_charges[t - 1],
			Color(0.92, 0.85, 0.65), beta_tex
		)
		it.is_spawner = true
		it.is_temporary_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = starter_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.exhaust_conversion_id = starter_convs[t - 1]
		it.spawn_pool = _get_sourdough_starter_pool(t)

	# -------------------------------------------------------------------------
	# 3. Seed Packet · CHAIN REACTION (3 Tiers)
	# -------------------------------------------------------------------------
	# Tier 1: Seed Packet (5 charges, spawns Healthy Plate T1-T2, converts to Planter)
	var sp1 := _register_item(
		"seed_packet_1", "seed_packet", "Seed Packet", 1, 3,
		"Seed Packet", "A packet of vegetable seeds with 5 charges. Spawns low-tier Healthy Plate items. Costs 0 Energy! Grows into a Planter when exhausted.",
		Color(0.4, 0.8, 0.35), beta_tex
	)
	sp1.is_spawner = true
	sp1.is_temporary_spawner = true
	sp1.min_spawner_tier = 1
	sp1.max_charges = 5
	sp1.cooldown_per_charge = 0.0
	sp1.energy_cost = 0
	sp1.exhaust_conversion_id = "seed_packet_2"
	sp1.spawn_pool = _get_seed_packet_pool(1)

	# Tier 2: Windowsill Planter (12 charges, spawns Healthy Plate T2-T5, converts to Herb Garden Box)
	var sp2 := _register_item(
		"seed_packet_2", "seed_packet", "Seed Packet", 2, 3,
		"Windowsill Planter", "A thriving windowsill planter with 12 charges. Spawns mid-tier Healthy Plate items. Costs 0 Energy! Converts into a permanent Herb Garden Box when exhausted.",
		Color(0.3, 0.75, 0.4), beta_tex
	)
	sp2.is_spawner = true
	sp2.is_temporary_spawner = true
	sp2.min_spawner_tier = 1
	sp2.max_charges = 12
	sp2.cooldown_per_charge = 0.0
	sp2.energy_cost = 0
	sp2.exhaust_conversion_id = "seed_packet_3"
	sp2.spawn_pool = _get_seed_packet_pool(2)

	# Tier 3: Herb Garden Box (Permanent upgrade booster)
	_register_item(
		"seed_packet_3", "seed_packet", "Seed Packet", 3, 3,
		"Herb Garden Box", "A handcrafted wooden herb garden box! Drag onto any Pantry to permanently add +2 Max Charges (up to 3 boxes per Pantry).",
		Color(0.2, 0.68, 0.35), beta_tex
	)

	# -------------------------------------------------------------------------
	# 4. Ice Cream Cart · COLLECTIBLE (4 Tiers)
	# -------------------------------------------------------------------------
	var cart_names := ["Cone Cooler", "Popsicle Box", "Gelato Cart", "Ice Cream Truck"]
	var cart_charges := [6, 10, 14, 20]
	for t in range(1, 5):
		var it := _register_item(
			"ice_cream_cart_%d" % t, "ice_cream_cart", "Ice Cream Cart", t, 4,
			cart_names[t - 1],
			"An ice cream cart with %d charges. Spawns Sweets and Drinks! Costs 0 Energy. Converts into a Golden Scoop Trophy when exhausted." % cart_charges[t - 1],
			Color(0.95, 0.6, 0.75), beta_tex
		)
		it.is_spawner = true
		it.is_temporary_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = cart_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.exhaust_conversion_id = "golden_scoop"
		it.spawn_pool = _get_ice_cream_cart_pool(t)

	# Golden Scoop Trophy (Collectible reward for Achievements)
	var scoop := _register_item(
		"golden_scoop", "golden_scoop", "Golden Scoop", 1, 1,
		"Golden Scoop Trophy", "A gleaming Golden Scoop trophy! Tap to collect into the Achievements codex to unlock exclusive milestone rewards.",
		Color(1.0, 0.85, 0.2), beta_tex
	)
	scoop.is_consumable = true
	scoop.consume_currency = "golden_scoop"
	scoop.consume_amount = 1

	# -------------------------------------------------------------------------
	# 5. Fortune Cookie Jar · GAMBLE (4 Tiers)
	# -------------------------------------------------------------------------
	var jar_names := ["Little Jar", "Lucky Jar", "Jade Jar", "Emperor's Jar"]
	var jar_charges := [6, 10, 14, 20]
	for t in range(1, 5):
		var it := _register_item(
			"fortune_cookie_jar_%d" % t, "fortune_cookie_jar", "Fortune Cookie Jar", t, 4,
			jar_names[t - 1],
			"A mystery jar with %d charges. Spawns random items from ANY kitchen chain! Costs 0 Energy. Converts into a Mystery Box when exhausted." % jar_charges[t - 1],
			Color(0.85, 0.45, 0.85), beta_tex
		)
		it.is_spawner = true
		it.is_temporary_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = jar_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.exhaust_conversion_id = "mystery_box"
		it.spawn_pool = _get_fortune_cookie_jar_pool(t)

	# Mystery Box (Tap to roll random temp spawner)
	_register_item(
		"mystery_box", "mystery_box", "Mystery Box", 1, 1,
		"Mystery Box", "A mysterious surprise box! Tap to roll a random temporary spawner (with a rare chance of the Golden Hen!).",
		Color(0.75, 0.4, 0.9), beta_tex
	)

	# -------------------------------------------------------------------------
	# 6. Chef's Toolbox · BOOSTER (4 Tiers)
	# -------------------------------------------------------------------------
	var box_names := ["Tin Toolbox", "Steel Toolbox", "Chef's Knife Roll", "Master Toolchest"]
	var box_charges := [6, 10, 14, 20]
	var box_convs := ["whetstone_1", "whetstone_2", "whetstone_3", "whetstone_4"]
	for t in range(1, 5):
		var it := _register_item(
			"chefs_toolbox_%d" % t, "chefs_toolbox", "Chef's Toolbox", t, 4,
			box_names[t - 1],
			"A culinary toolbox with %d charges. Spawns Utensils! Costs 0 Energy. Converts into a Whetstone charge booster when exhausted." % box_charges[t - 1],
			Color(0.55, 0.6, 0.7), beta_tex
		)
		it.is_spawner = true
		it.is_temporary_spawner = true
		it.min_spawner_tier = 1
		it.max_charges = box_charges[t - 1]
		it.cooldown_per_charge = 0.0
		it.energy_cost = 0
		it.exhaust_conversion_id = box_convs[t - 1]
		it.spawn_pool = _get_chefs_toolbox_pool(t)

	# Whetstones (4 Tiers)
	var stone_names := ["Coarse Whetstone (25% Refill)", "Fine Whetstone (50% Refill)", "Diamond Whetstone (75% Refill)", "Master Sharpener (100% Refill)"]
	var stone_pcts := [25, 50, 75, 100]
	for t in range(1, 5):
		_register_item(
			"whetstone_%d" % t, "whetstone", "Whetstone", t, 4,
			stone_names[t - 1],
			"A professional sharpening stone. Drag onto any generator to instantly refill %d%% of its charges!" % stone_pcts[t - 1],
			Color(0.5, 0.55, 0.65), beta_tex
		)

	# -------------------------------------------------------------------------
	# 7. Golden Hen · LEGENDARY (1 Tier)
	# -------------------------------------------------------------------------
	var hen := _register_item(
		"golden_hen_1", "golden_hen", "Golden Hen", 1, 1,
		"Golden Hen", "A magnificent golden hen with 8 charges! Spawns high-tier Healthy Plate items (T3-T6). Costs 0 Energy. Lays a Golden Egg when exhausted!",
		Color(1.0, 0.85, 0.2), beta_tex
	)
	hen.is_spawner = true
	hen.is_temporary_spawner = true
	hen.min_spawner_tier = 1
	hen.max_charges = 8
	hen.cooldown_per_charge = 0.0
	hen.energy_cost = 0
	hen.exhaust_conversion_id = "golden_egg"
	hen.spawn_pool = _get_golden_hen_pool()

	# Golden Egg
	var egg := _register_item(
		"golden_egg", "golden_egg", "Golden Egg", 1, 1,
		"Golden Egg", "A solid golden egg! Tap for 8 precious Diamonds, or merge two Golden Eggs together to create a Tier 12 Mezze Platter!",
		Color(1.0, 0.9, 0.3), beta_tex
	)
	egg.is_consumable = true
	egg.consume_currency = "gems"
	egg.consume_amount = 8


func _get_pantry_pool(tier: int) -> Array[String]:
	match tier:
		3:
			# Tier 3 Pantry Box (Starter Spawner): Strictly Level 1 items only (100% Level 1)
			return [
				"healthy_1", "healthy_1", "healthy_1", "healthy_1",
				"staples_1", "staples_1", "staples_1", "staples_1"
			]
		4:
			# Tier 4 Chef's Produce Bin: 85% Level 1, 15% Level 2
			return [
				"healthy_1", "healthy_1", "healthy_1", "healthy_1", "healthy_1", "healthy_1", "healthy_1", "healthy_1",
				"staples_1", "staples_1", "staples_1", "staples_1", "staples_1", "staples_1", "staples_1", "staples_1",
				"healthy_2", "staples_2", "healthy_2"
			]
		5:
			# Tier 5 Gourmet Harvest Locker: 70% Level 1, 25% Level 2, 5% Level 3
			return [
				"healthy_1", "healthy_1", "healthy_1", "healthy_1", "healthy_1", "healthy_1", "healthy_1",
				"staples_1", "staples_1", "staples_1", "staples_1", "staples_1", "staples_1", "staples_1",
				"healthy_2", "healthy_2", "healthy_2", "staples_2", "staples_2",
				"healthy_3"
			]
		6:
			# Tier 6 Master Walk-in Pantry: 50% Level 1, 35% Level 2, 15% Level 3
			return [
				"healthy_1", "healthy_1", "healthy_1", "healthy_1", "healthy_1",
				"staples_1", "staples_1", "staples_1", "staples_1", "staples_1",
				"healthy_2", "healthy_2", "healthy_2", "healthy_2", "staples_2", "staples_2", "staples_2",
				"healthy_3", "healthy_3", "staples_3"
			]
		7:
			# Tier 7 Artisan Food Cellar: Drops Healthy, Staples + Grocery Bag
			return [
				"healthy_1", "healthy_1", "healthy_2", "healthy_2", "healthy_3",
				"staples_1", "staples_1", "staples_2", "staples_2", "staples_3",
				"healthy_4", "staples_4",
				"grocery_bag_1", "grocery_bag_1"
			]
		8:
			# Tier 8 Deluxe Culinary Larder: Drops Healthy, Staples + Grocery Bag, Seed Packet
			return [
				"healthy_1", "healthy_2", "healthy_2", "healthy_3", "healthy_4",
				"staples_1", "staples_2", "staples_2", "staples_3", "staples_4",
				"grocery_bag_1", "seed_packet_1"
			]
		9:
			var p9: Array[String] = [
				"healthy_2", "healthy_2", "healthy_3", "healthy_3", "healthy_4", "healthy_5",
				"staples_2", "staples_2", "staples_3", "staples_3", "staples_4", "staples_5",
				"grocery_bag_1", "seed_packet_1"
			]
			if randf() < 0.01:
				p9.append("golden_hen_1")
			return p9
		_:
			var p10: Array[String] = [
				"healthy_2", "healthy_3", "healthy_3", "healthy_4", "healthy_4", "healthy_5",
				"staples_2", "staples_3", "staples_3", "staples_4", "staples_4", "staples_5",
				"grocery_bag_1", "seed_packet_1", "grocery_bag_1"
			]
			if randf() < 0.01:
				p10.append("golden_hen_1")
			return p10

func _get_foodbox_pool(tier: int) -> Array[String]:
	return _get_pantry_pool(tier)

func _get_oven_pool(tier: int) -> Array[String]:
	match tier:
		3:
			# Tier 3 Brick Baker: Strictly Level 1 items only (100% Level 1)
			return ["bakery_1", "sweets_1"]
		4:
			# Tier 4 Stainless Oven: 85% Level 1, 15% Level 2
			return [
				"bakery_1", "bakery_1", "bakery_1", "bakery_1", "bakery_1", "bakery_1",
				"sweets_1", "sweets_1", "sweets_1", "sweets_1", "sweets_1", "sweets_1",
				"bakery_2", "sweets_2"
			]
		5:
			# Tier 5 Pastry Range: 70% Level 1, 25% Level 2, 5% Level 3
			return [
				"bakery_1", "bakery_1", "bakery_1", "bakery_1",
				"sweets_1", "sweets_1", "sweets_1", "sweets_1",
				"bakery_2", "bakery_2", "sweets_2", "sweets_2",
				"sweets_3"
			]
		6:
			# Tier 6 Grand Master Oven: 50% Level 1, 35% Level 2, 15% Level 3
			return [
				"bakery_1", "bakery_1", "bakery_1",
				"sweets_1", "sweets_1", "sweets_1",
				"bakery_2", "bakery_2", "sweets_2", "sweets_2",
				"bakery_3", "sweets_3"
			]
		7:
			return [
				"bakery_1", "bakery_2", "bakery_3", "bakery_4",
				"sweets_1", "sweets_2", "sweets_3", "sweets_4",
				"sourdough_starter_1", "sourdough_starter_1"
			]
		8:
			return [
				"bakery_2", "bakery_2", "bakery_3", "bakery_4",
				"sweets_2", "sweets_2", "sweets_3", "sweets_4",
				"sourdough_starter_1", "ice_cream_cart_1"
			]
		9:
			return [
				"bakery_2", "bakery_3", "bakery_3", "bakery_4", "bakery_5",
				"sweets_2", "sweets_3", "sweets_3", "sweets_4", "sweets_5",
				"sourdough_starter_1", "ice_cream_cart_1"
			]
		_:
			return [
				"bakery_3", "bakery_3", "bakery_4", "bakery_4", "bakery_5",
				"sweets_3", "sweets_3", "sweets_4", "sweets_4", "sweets_5",
				"sourdough_starter_1", "ice_cream_cart_1"
			]

func _get_burner_pool(tier: int) -> Array[String]:
	match tier:
		3:
			return ["grill_1", "noodle_1"]
		4:
			return [
				"grill_1", "grill_1", "grill_1", "grill_1", "grill_1", "grill_1",
				"noodle_1", "noodle_1", "noodle_1", "noodle_1", "noodle_1", "noodle_1",
				"grill_2", "noodle_2"
			]
		5:
			return [
				"grill_1", "grill_1", "grill_1", "grill_1",
				"noodle_1", "noodle_1", "noodle_1", "noodle_1",
				"grill_2", "grill_2", "noodle_2", "noodle_2",
				"grill_3"
			]
		6:
			return [
				"grill_1", "grill_1", "grill_1",
				"noodle_1", "noodle_1", "noodle_1",
				"grill_2", "grill_2", "noodle_2", "noodle_2",
				"grill_3", "noodle_3"
			]
		7:
			return [
				"grill_1", "grill_2", "grill_3", "grill_4",
				"noodle_1", "noodle_2", "noodle_3", "noodle_4",
				"fortune_cookie_jar_1", "fortune_cookie_jar_1"
			]
		8:
			return [
				"grill_2", "grill_2", "grill_3", "grill_4",
				"noodle_2", "noodle_2", "noodle_3", "noodle_4",
				"fortune_cookie_jar_1"
			]
		9:
			return [
				"grill_2", "grill_3", "grill_3", "grill_4", "grill_5",
				"noodle_2", "noodle_3", "noodle_3", "noodle_4", "noodle_5",
				"fortune_cookie_jar_1"
			]
		_:
			return [
				"grill_3", "grill_3", "grill_4", "grill_4", "grill_5",
				"noodle_3", "noodle_3", "noodle_4", "noodle_4", "noodle_5",
				"fortune_cookie_jar_1"
			]

func _get_fridge_pool(tier: int) -> Array[String]:
	match tier:
		3:
			return ["drinks_1", "dairy_1"]
		4:
			return [
				"drinks_1", "drinks_1", "drinks_1", "drinks_1", "drinks_1", "drinks_1",
				"dairy_1", "dairy_1", "dairy_1", "dairy_1", "dairy_1", "dairy_1",
				"drinks_2", "dairy_2"
			]
		5:
			return [
				"drinks_1", "drinks_1", "drinks_1", "drinks_1",
				"dairy_1", "dairy_1", "dairy_1", "dairy_1",
				"drinks_2", "drinks_2", "dairy_2", "dairy_2",
				"drinks_3"
			]
		6:
			return [
				"drinks_1", "drinks_1", "drinks_1",
				"dairy_1", "dairy_1", "dairy_1",
				"drinks_2", "drinks_2", "dairy_2", "dairy_2",
				"drinks_3", "dairy_3"
			]
		7:
			return [
				"drinks_1", "drinks_2", "drinks_3", "drinks_4",
				"dairy_1", "dairy_2", "dairy_3", "dairy_4",
				"grocery_bag_1", "grocery_bag_1"
			]
		8:
			return [
				"drinks_2", "drinks_2", "drinks_3", "drinks_4",
				"dairy_2", "dairy_2", "dairy_3", "dairy_4",
				"grocery_bag_1", "ice_cream_cart_1"
			]
		9:
			return [
				"drinks_2", "drinks_3", "drinks_3", "drinks_4", "drinks_5",
				"dairy_2", "dairy_3", "dairy_3", "dairy_4", "dairy_5",
				"grocery_bag_1", "ice_cream_cart_1"
			]
		_:
			return [
				"drinks_3", "drinks_3", "drinks_4", "drinks_4", "drinks_5",
				"dairy_3", "dairy_3", "dairy_4", "dairy_4", "dairy_5",
				"grocery_bag_1", "ice_cream_cart_1"
			]

func _get_rack_pool(tier: int) -> Array[String]:
	match tier:
		3:
			return ["util_1"]
		4:
			return [
				"util_1", "util_1", "util_1", "util_1", "util_1", "util_1", "util_1",
				"util_2", "util_2"
			]
		5:
			return [
				"util_1", "util_1", "util_1", "util_1",
				"util_2", "util_2", "util_2",
				"util_3"
			]
		6:
			return [
				"util_1", "util_1", "util_1",
				"util_2", "util_2", "util_2",
				"util_3", "util_3", "util_4"
			]
		7:
			return [
				"util_1", "util_2", "util_2", "util_3", "util_4",
				"chefs_toolbox_1", "chefs_toolbox_1"
			]
		8:
			return [
				"util_2", "util_2", "util_3", "util_4",
				"chefs_toolbox_1", "fortune_cookie_jar_1"
			]
		9:
			var p9: Array[String] = [
				"util_2", "util_3", "util_3", "util_4", "util_5",
				"chefs_toolbox_1", "fortune_cookie_jar_1"
			]
			var temp_spawners := ["grocery_bag_1", "sourdough_starter_1", "seed_packet_1", "ice_cream_cart_1", "fortune_cookie_jar_1", "chefs_toolbox_1"]
			p9.append(temp_spawners[randi() % temp_spawners.size()])
			return p9
		_:
			var p10: Array[String] = [
				"util_3", "util_3", "util_4", "util_4", "util_5",
				"chefs_toolbox_1", "fortune_cookie_jar_1"
			]
			var temp_spawners := ["grocery_bag_1", "sourdough_starter_1", "seed_packet_1", "ice_cream_cart_1", "fortune_cookie_jar_1", "chefs_toolbox_1"]
			p10.append(temp_spawners[randi() % temp_spawners.size()])
			return p10

func _get_grocery_bag_pool(tier: int) -> Array[String]:
	match tier:
		1:
			return ["healthy_1", "healthy_2", "staples_1", "staples_2", "dairy_1", "dairy_2"]
		2:
			return ["healthy_1", "healthy_2", "healthy_3", "staples_1", "staples_2", "staples_3", "dairy_1", "dairy_2", "dairy_3"]
		3:
			return ["healthy_2", "healthy_3", "staples_2", "staples_3", "dairy_2", "dairy_3"]
		_:
			return ["healthy_2", "healthy_3", "healthy_4", "staples_2", "staples_3", "staples_4", "dairy_2", "dairy_3", "dairy_4"]

func _get_sourdough_starter_pool(tier: int) -> Array[String]:
	match tier:
		1:
			return ["bakery_1", "bakery_2"]
		2:
			return ["bakery_1", "bakery_2", "bakery_3"]
		3:
			return ["bakery_2", "bakery_3"]
		_:
			return ["bakery_2", "bakery_3", "bakery_4"]

func _get_seed_packet_pool(stage: int) -> Array[String]:
	match stage:
		1:
			return ["healthy_1", "healthy_2"]
		_:
			return ["healthy_2", "healthy_3", "healthy_4", "healthy_5"]

func _get_ice_cream_cart_pool(tier: int) -> Array[String]:
	match tier:
		1:
			return ["sweets_1", "sweets_2", "sweets_3", "sweets_4", "drinks_1", "drinks_2", "drinks_3"]
		2:
			return ["sweets_1", "sweets_2", "sweets_3", "sweets_4", "drinks_1", "drinks_2", "drinks_3"]
		3:
			return ["sweets_2", "sweets_3", "sweets_4", "drinks_2", "drinks_3"]
		_:
			return ["sweets_2", "sweets_3", "sweets_4", "drinks_2", "drinks_3", "drinks_4"]

func _get_fortune_cookie_jar_pool(tier: int) -> Array[String]:
	var min_t := 1
	var max_t := 2
	match tier:
		1: min_t = 1; max_t = 2
		2: min_t = 1; max_t = 3
		3: min_t = 2; max_t = 3
		_: min_t = 2; max_t = 4
	var pool: Array[String] = []
	var chains := ["healthy", "staples", "bakery", "sweets", "grill", "noodle", "drinks", "dairy", "util"]
	for c in chains:
		for t in range(min_t, max_t + 1):
			pool.append("%s_%d" % [c, t])
	return pool

func _get_chefs_toolbox_pool(tier: int) -> Array[String]:
	match tier:
		1:
			return ["util_1", "util_2"]
		2:
			return ["util_1", "util_2", "util_3"]
		3:
			return ["util_2", "util_3"]
		_:
			return ["util_2", "util_3", "util_4"]

func _get_golden_hen_pool() -> Array[String]:
	return ["healthy_3", "healthy_4", "healthy_5", "healthy_6"]


func _resolve_alias(id: String) -> String:
	var parts := id.split("_")
	if parts.size() >= 2:
		var prefix := parts[0]
		var suffix := parts[1]
		match prefix:
			"foodbox", "food":
				return "pantry_" + suffix
			"egg":
				return "healthy_" + suffix
			"leaf":
				return "staples_" + suffix
			"sandwich":
				return "bakery_" + suffix
			"cake":
				return "sweets_" + suffix
			"beef":
				return "grill_" + suffix
			"drink":
				return "drinks_" + suffix
			"utils":
				return "util_" + suffix
	return ""

func _register_aliases() -> void:
	for t in range(1, 11):
		var p_it := get_item("pantry_%d" % t)
		if p_it:
			_items["foodbox_%d" % t] = p_it
			_items["food_%d" % t] = p_it
	for t in range(1, 17):
		var h_it := get_item("healthy_%d" % t)
		if h_it and t <= 6:
			_items["egg_%d" % t] = h_it
		var s_it := get_item("staples_%d" % t)
		if s_it and t <= 5:
			_items["leaf_%d" % t] = s_it
		var b_it := get_item("bakery_%d" % t)
		if b_it and t <= 6:
			_items["sandwich_%d" % t] = b_it
		var sw_it := get_item("sweets_%d" % t)
		if sw_it and t <= 6:
			_items["cake_%d" % t] = sw_it
		var g_it := get_item("grill_%d" % t)
		if g_it and t <= 7:
			_items["beef_%d" % t] = g_it
		var d_it := get_item("drinks_%d" % t)
		if d_it and t <= 5:
			_items["drink_%d" % t] = d_it
		var u_it := get_item("util_%d" % t)
		if u_it:
			_items["utils_%d" % t] = u_it

	_chains["foodbox"] = _chains.get("pantry", [])
	_chains["food"] = _chains.get("pantry", [])
	_chains["egg"] = _chains.get("healthy", [])
	_chains["leaf"] = _chains.get("staples", [])
	_chains["sandwich"] = _chains.get("bakery", [])
	_chains["cake"] = _chains.get("sweets", [])
	_chains["beef"] = _chains.get("grill", [])
	_chains["drink"] = _chains.get("drinks", [])
	_chains["utils"] = _chains.get("util", [])

func _register_item(id: String, chain_id: String, chain_name: String, tier: int, max_tier: int,
		display_name: String, description: String, color: Color, texture: Texture2D = null) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.chain_id = chain_id
	item.chain_name = chain_name
	item.tier = tier
	item.max_tier = max_tier
	item.display_name = display_name
	item.description = description
	item.color = color
	item.icon_texture = texture
	item.sell_value = int(pow(2, tier - 1))

	_items[id] = item

	if not _chains.has(chain_id):
		_chains[chain_id] = []
	_chains[chain_id].append(item)

	return item

func get_item(id: String) -> ItemData:
	if _items.has(id):
		return _items[id]
	var alias := _resolve_alias(id)
	if not alias.is_empty() and _items.has(alias):
		return _items[alias]
	return null

func has_item(id: String) -> bool:
	if _items.has(id):
		return true
	var alias := _resolve_alias(id)
	return not alias.is_empty() and _items.has(alias)

func get_chest_pool(chest_id: String, board_context: String = "") -> Array[String]:
	var context := board_context
	if context.is_empty() and is_instance_valid(SaveManager):
		context = SaveManager.current_board_id
	if context.is_empty():
		context = "kitchen"

	var is_farm := (context == "farm")
	var is_witch := (context == "witch")

	if chest_id == "chest_1" or chest_id == "chest":
		if is_witch:
			return ["mystic_tree_1", "cauldron_1"]
		elif is_farm:
			return ["barn_1", "water_1"]
		return ["pantry_1", "oven_1", "fridge_1"]
	elif chest_id == "chest_2" or (chest_id.begins_with("chest_") and not (chest_id.begins_with("chest_purple") or chest_id.begins_with("chest_green") or chest_id.begins_with("chest_yellow") or chest_id.begins_with("chest_blue"))):
		if is_witch:
			return ["mystic_tree_1", "shroom_1", "wand_1", "cauldron_1"]
		elif is_farm:
			return ["barn_1", "water_1", "tree_1", "pine_1"]
		return ["pantry_1", "oven_1", "burner_1", "fridge_1", "rack_1", "foodbox_1"]

	var parts := chest_id.split("_")
	var tier := int(parts[-1]) if not parts.is_empty() else 1

	if chest_id.begins_with("chest_purple"):
		return _get_purple_chest_pool(tier, is_farm, is_witch)
	elif chest_id.begins_with("chest_green"):
		return _get_green_chest_pool(tier, is_farm, is_witch)
	elif chest_id.begins_with("chest_yellow"):
		return _get_yellow_chest_pool(tier, is_farm, is_witch)
	elif chest_id.begins_with("chest_blue"):
		return _get_blue_chest_pool(tier, is_farm, is_witch)

	return []

func get_spawner_drop(spawner_id: String, board_context: String = "") -> String:
	var item: ItemData = get_item(spawner_id)
	if not item or not item.is_spawner:
		return "healthy_1"

	if item.chain_id.begins_with("chest"):
		var pool := get_chest_pool(item.id, board_context)
		if not pool.is_empty():
			return pool[randi() % pool.size()]

	# Generator Tier 7+ Temporary Spawner Drops
	if (item.chain_id == "pantry" or item.chain_id == "foodbox") and item.tier >= 9:
		if randf() < 0.01:
			return "golden_hen_1"

	if (item.chain_id == "rack") and item.tier >= 7:
		if randf() < 0.20:
			var temp_choices := ["grocery_bag_1", "sourdough_starter_1", "seed_packet_1", "ice_cream_cart_1", "fortune_cookie_jar_1", "chefs_toolbox_1"]
			return temp_choices[randi() % temp_choices.size()]

	if item.spawn_pool.is_empty():
		return "healthy_1"
	return item.spawn_pool[randi() % item.spawn_pool.size()]

func get_all_items() -> Array:
	return _items.values()

func get_chain(chain_id: String) -> Array:
	return _chains.get(chain_id, [])
