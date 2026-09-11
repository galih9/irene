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

	# =========================================================================
	# 1. PRODUCER ITEMS
	# =========================================================================

	# 1.1 Foodbox Chain (produces egg, leafs)
	var foodbox_textures := [
		preload("res://assets/foodbox/food1.png"),
		preload("res://assets/foodbox/food2.png"),
		preload("res://assets/foodbox/food3.png"),
		preload("res://assets/foodbox/food4.png"),
		preload("res://assets/foodbox/food5.png"),
		preload("res://assets/foodbox/food6.png")
	]
	var foodbox_names := [
		"Wooden Foodbox", "Reinforced Foodbox", "Pantry Box",
		"Chef's Produce Box", "Gourmet Harvest Crate", "Master Harvest Vault"
	]
	var foodbox_descs := [
		"A wooden produce box. Merge to tier 3 to create a fresh food spawner!",
		"A sturdy reinforced produce crate. Merge to tier 3 to create a fresh food spawner!",
		"A well-stocked pantry box. Tap to produce fresh farm eggs and greens! Uses 1 Energy.",
		"Chef's selection box with fresh eggs and herbs. Uses 1 Energy.",
		"Gourmet crate packed with prime kitchen harvest. Uses 1 Energy.",
		"The ultimate farm produce vault! Produces eggs and greens. Uses 1 Energy."
	]
	for t in range(1, 7):
		var id := "foodbox_%d" % t
		var it := _register_item(
			id, "foodbox", "Foodbox", t, 6,
			foodbox_names[t - 1], foodbox_descs[t - 1],
			Color(0.88, 0.65, 0.35), foodbox_textures[t - 1]
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_foodbox_pool(t)

	# 1.2 Oven Chain (produces beef, cake, sandwich)
	var oven_textures := [
		preload("res://assets/oven/oven_1.png"),
		preload("res://assets/oven/oven_2.png"),
		preload("res://assets/oven/oven_3.png"),
		preload("res://assets/oven/oven_4.png"),
		preload("res://assets/oven/oven_5.png"),
		preload("res://assets/oven/oven_6.png")
	]
	var oven_names := [
		"Clay Toaster", "Stone Stove", "Brick Baker",
		"Stainless Oven", "Pastry Range", "Grand Master Oven"
	]
	var oven_descs := [
		"A small clay toaster. Merge to tier 3 to bake delicious goods!",
		"A sturdy stone hearth with steady baking heat. Merge to tier 3 to bake delicious goods!",
		"Traditional brick oven for savory meats and cakes. Uses 1 Energy.",
		"Precision stainless steel oven. Uses 1 Energy.",
		"Professional dual-deck pastry and roast range. Uses 1 Energy.",
		"Grand culinary oven! Bakes gourmet beef, cake and sandwiches. Uses 1 Energy."
	]
	for t in range(1, 7):
		var id := "oven_%d" % t
		var it := _register_item(
			id, "oven", "Oven", t, 6,
			oven_names[t - 1], oven_descs[t - 1],
			Color(0.95, 0.45, 0.28), oven_textures[t - 1]
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_oven_pool(t)

	# 1.3 Fridge Chain (produces drink)
	var fridge_textures := [
		preload("res://assets/fridge/fridge1.png"),
		preload("res://assets/fridge/fridge2.png"),
		preload("res://assets/fridge/fridge3.png"),
		preload("res://assets/fridge/fridge4.png"),
		preload("res://assets/fridge/fridge5.png"),
		preload("res://assets/fridge/fridge6.png")
	]
	var fridge_names := [
		"Mini Icebox", "Retro Cooler", "Kitchen Refrigerator",
		"Double-Door Chiller", "Beverage Dispenser", "Master Cryo Chiller"
	]
	var fridge_descs := [
		"A compact mini icebox. Merge to tier 3 to dispense chilled drinks!",
		"A cool retro cooler keeping drinks icy fresh. Merge to tier 3 to dispense chilled drinks!",
		"Standard household fridge with chilled drinks. Uses 1 Energy.",
		"Double-door chiller with rapid refreshment cooling. Uses 1 Energy.",
		"Commercial glass-front beverage cooler. Uses 1 Energy.",
		"Supreme cryo chiller! Dispenses premium drinks. Uses 1 Energy."
	]
	for t in range(1, 7):
		var id := "fridge_%d" % t
		var it := _register_item(
			id, "fridge", "Fridge", t, 6,
			fridge_names[t - 1], fridge_descs[t - 1],
			Color(0.35, 0.72, 0.95), fridge_textures[t - 1]
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_fridge_pool(t)

	# 1.4 Rack Chain (produces utils)
	var rack_textures := [
		preload("res://assets/rack/rack1.png"),
		preload("res://assets/rack/rack2.png"),
		preload("res://assets/rack/rack3.png"),
		preload("res://assets/rack/rack4.png"),
		preload("res://assets/rack/rack5.png"),
		preload("res://assets/rack/rack6.png"),
		preload("res://assets/rack/rack7.png")
	]
	var rack_names := [
		"Small Pegboard", "Wooden Utensil Stand", "Metal Tool Rack",
		"Chef's Cutlery Caddy", "Magnetic Tool Bar", "Master Prep Station", "Grand Kitchen Arsenal"
	]
	var rack_descs := [
		"A small wooden pegboard. Merge to tier 3 to produce culinary gear!",
		"Organized wooden stand holding basic utensils. Merge to tier 3 to produce culinary gear!",
		"Stainless steel kitchen utensil rack. Uses 1 Energy.",
		"Heavy-duty cutlery caddy with culinary gear. Uses 1 Energy.",
		"Chef-grade magnetic organizer bar. Uses 1 Energy.",
		"Modular prep station with specialized cooking tools. Uses 1 Energy.",
		"Supreme culinary arsenal! Produces kitchen utensils. Uses 1 Energy."
	]
	for t in range(1, 8):
		var id := "rack_%d" % t
		var it := _register_item(
			id, "rack", "Rack", t, 7,
			rack_names[t - 1], rack_descs[t - 1],
			Color(0.65, 0.55, 0.75), rack_textures[t - 1]
		)
		it.min_spawner_tier = default_min_spawner_tier
		it.is_spawner = (t >= default_min_spawner_tier)
		it.max_charges = default_spawner_max_charges
		it.cooldown_per_charge = default_spawner_cooldown_per_charge
		it.energy_cost = 1
		it.spawn_pool = _get_rack_pool(t)

	# =========================================================================
	# 2. NORMAL ITEMS (produced from producers)
	# =========================================================================

	# 2.1 Egg Chain (produced from Foodbox)
	var egg_textures := [
		preload("res://assets/eggs/egg_0.png"),
		preload("res://assets/eggs/egg_1.png"),
		preload("res://assets/eggs/egg_2.png"),
		preload("res://assets/eggs/egg_3.png"),
		preload("res://assets/eggs/egg_4.png"),
		preload("res://assets/eggs/egg_5.png")
	]
	var egg_names := [
		"Fresh Egg", "Double Eggs", "Egg Trio",
		"Egg Carton", "Egg Crate", "Egg Tub"
	]
	var egg_descs := [
		"A smooth white egg, fresh from the farm.",
		"Two fresh eggs, ready for breakfast.",
		"A trio of farm eggs for baking recipes.",
		"A half-dozen carton of farm-fresh eggs.",
		"A sturdy wooden storage crate packed with eggs.",
		"A wholesale tub of farm eggs! Max tier egg."
	]
	for t in range(1, 7):
		_register_item(
			"egg_%d" % t, "egg", "Eggs", t, 6,
			egg_names[t - 1], egg_descs[t - 1],
			Color(0.96, 0.93, 0.88), egg_textures[t - 1]
		)

	# 2.2 Leafs / Greens Chain (produced from Foodbox)
	var leaf_textures := [
		preload("res://assets/leafs/leaf_0.png"),
		preload("res://assets/leafs/leaf_1.png"),
		preload("res://assets/leafs/leaf_2.png"),
		preload("res://assets/leafs/leaf_3.png"),
		preload("res://assets/leafs/leaf_4.png")
	]
	var leaf_names := [
		"Fresh Herb", "Crisp Celery", "Spinach Bundle",
		"Crisp Cabbage", "Garden Salad"
	]
	var leaf_descs := [
		"A fragrant culinary herb, fresh from the kitchen garden.",
		"A crunchy stalk packed with aromatic flavor.",
		"A vibrant bundle of farm-fresh spinach greens.",
		"A hearty head of crisp green cabbage.",
		"A colorful gourmet garden salad bowl! Max tier greens."
	]
	for t in range(1, 6):
		_register_item(
			"leaf_%d" % t, "leaf", "Leafs", t, 5,
			leaf_names[t - 1], leaf_descs[t - 1],
			Color(0.35, 0.82, 0.32), leaf_textures[t - 1]
		)

	# 2.3 Beef Chain (produced from Oven)
	var beef_textures := [
		preload("res://assets/beef/beef_1.png"),
		preload("res://assets/beef/beef_2.png"),
		preload("res://assets/beef/beef_3.png"),
		preload("res://assets/beef/beef_4.png"),
		preload("res://assets/beef/beef_5.png"),
		preload("res://assets/beef/beef_6.png"),
		preload("res://assets/beef/beef_7.png")
	]
	var beef_names := [
		"Ground Beef", "Meat Patty", "Beef Sausage",
		"Rib Cut", "Marbled Steak", "Prime Roast", "Wagyu Feast"
	]
	var beef_descs := [
		"Freshly minced premium beef.",
		"A shaped seasoned beef patty ready to sizzle.",
		"Spicy smoked beef sausage link.",
		"A tender butcher's cut of prime beef ribs.",
		"Heavily marbled steak cut with rich flavor.",
		"Slow-roasted golden brown beef roast.",
		"An extravagant five-star Wagyu beef feast! Max tier beef."
	]
	for t in range(1, 8):
		_register_item(
			"beef_%d" % t, "beef", "Beef", t, 7,
			beef_names[t - 1], beef_descs[t - 1],
			Color(0.85, 0.32, 0.3), beef_textures[t - 1]
		)

	# 2.4 Cake Chain (produced from Oven)
	var cake_textures := [
		preload("res://assets/cake/cake_1.png"),
		preload("res://assets/cake/cake_2.png"),
		preload("res://assets/cake/cake_3.png"),
		preload("res://assets/cake/cake_4.png"),
		preload("res://assets/cake/cake_5.png"),
		preload("res://assets/cake/cake_6.png")
	]
	var cake_names := [
		"Cupcake", "Berry Tart", "Sponge Roll",
		"Cream Layer Cake", "Chocolate Gateau", "Royal Wedding Cake"
	]
	var cake_descs := [
		"A sweet fluffy cupcake topped with swirl frosting.",
		"A crisp buttery tart filled with berry custard.",
		"Soft vanilla sponge rolled with sweet jam.",
		"Delicate multi-layer frosted sponge cake.",
		"Decadent dark chocolate dessert cake.",
		"Magnificent towering multi-tier confection! Max tier cake."
	]
	for t in range(1, 7):
		_register_item(
			"cake_%d" % t, "cake", "Cake", t, 6,
			cake_names[t - 1], cake_descs[t - 1],
			Color(0.96, 0.65, 0.78), cake_textures[t - 1]
		)

	# 2.5 Sandwich Chain (produced from Oven)
	var sandwich_textures := [
		preload("res://assets/sandwich/sandwich1.png"),
		preload("res://assets/sandwich/sandwich2.png"),
		preload("res://assets/sandwich/sandwich3.png"),
		preload("res://assets/sandwich/sandwich4.png"),
		preload("res://assets/sandwich/sandwich5.png"),
		preload("res://assets/sandwich/sandwich6.png")
	]
	var sandwich_names := [
		"Toast Slice", "Buttered Bread", "Club Sandwich",
		"Submarine Roll", "Artisan Panini", "Gourmet Burger"
	]
	var sandwich_descs := [
		"Warm toasted bread slice.",
		"Fresh bread slices with rich creamy butter.",
		"Triple-decker deli club sandwich.",
		"Footlong toasted submarine sandwich.",
		"Crispy pressed Italian panini sandwich.",
		"Juicy towering gourmet burger with all toppings! Max tier sandwich."
	]
	for t in range(1, 7):
		_register_item(
			"sandwich_%d" % t, "sandwich", "Sandwich", t, 6,
			sandwich_names[t - 1], sandwich_descs[t - 1],
			Color(0.92, 0.78, 0.42), sandwich_textures[t - 1]
		)

	# 2.6 Drink Chain (produced from Fridge)
	var drink_textures := [
		preload("res://assets/drink/drink_1.png"),
		preload("res://assets/drink/drink_2.png"),
		preload("res://assets/drink/drink_3.png"),
		preload("res://assets/drink/drink_4.png"),
		preload("res://assets/drink/drink_5.png")
	]
	var drink_names := [
		"Water Glass", "Iced Lemonade", "Berry Smoothie",
		"Milkshake", "Tropical Punch"
	]
	var drink_descs := [
		"A refreshing glass of pure chilled spring water.",
		"Zesty cold lemonade sweetened with cane sugar.",
		"Thick blended smoothie with fresh summer berries.",
		"Creamy frothy milkshake with vanilla whip.",
		"Exotic blended tropical fruit punch! Max tier drink."
	]
	for t in range(1, 6):
		_register_item(
			"drink_%d" % t, "drink", "Drink", t, 5,
			drink_names[t - 1], drink_descs[t - 1],
			Color(0.35, 0.85, 0.95), drink_textures[t - 1]
		)

	# 2.7 Utils Chain (produced from Rack)
	var util_textures := [
		preload("res://assets/utils/util1.png"),
		preload("res://assets/utils/util2.png"),
		preload("res://assets/utils/util3.png"),
		preload("res://assets/utils/util4.png"),
		preload("res://assets/utils/util5.png"),
		preload("res://assets/utils/util6.png"),
		preload("res://assets/utils/util7.png"),
		preload("res://assets/utils/util8.png"),
		preload("res://assets/utils/util9.png"),
		preload("res://assets/utils/util10.png"),
		preload("res://assets/utils/util11.png"),
		preload("res://assets/utils/util12.png")
	]
	var util_names := [
		"Spoon", "Fork", "Table Knife",
		"Wire Whisk", "Kitchen Spatula", "Soup Ladle",
		"Rolling Pin", "Chef's Cleaver", "Vegetable Grater",
		"Copper Kettle", "Cast Pot", "Golden Master Skillet"
	]
	var util_descs := [
		"A basic dining spoon.",
		"A shiny stainless steel fork.",
		"A sharp table knife.",
		"Flexible wire whisk for eggs and creams.",
		"Heat-resistant cooking spatula.",
		"Deep ladle for hot soups and sauces.",
		"Smooth hardwood pastry rolling pin.",
		"Heavy culinary cleaver for meat prep.",
		"Four-sided stainless grating tool.",
		"Charming whistling stovetop copper kettle.",
		"Heavy-duty heirloom cast cooking pot.",
		"The legendary golden chef's skillet! Max tier kitchen util."
	]
	for t in range(1, 13):
		_register_item(
			"util_%d" % t, "util", "Utils", t, 12,
			util_names[t - 1], util_descs[t - 1],
			Color(0.72, 0.76, 0.82), util_textures[t - 1]
		)

	# =========================================================================
	# 3. CONSUMABLE ITEMS (EXP, Gold, Energy, Diamond)
	# =========================================================================

	# 3.1 EXP Chain (10 Tiers)
	var exp_textures := [
		preload("res://assets/exp/exp1.png"),
		preload("res://assets/exp/exp2.png"),
		preload("res://assets/exp/exp3.png"),
		preload("res://assets/exp/exp4.png"),
		preload("res://assets/exp/exp5.png"),
		preload("res://assets/exp/exp6.png"),
		preload("res://assets/exp/exp7.png"),
		preload("res://assets/exp/exp8.png"),
		preload("res://assets/exp/exp9.png"),
		preload("res://assets/exp/exp10.png")
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
		preload("res://assets/gold/gold1.png"),
		preload("res://assets/gold/gold2.png"),
		preload("res://assets/gold/gold3.png"),
		preload("res://assets/gold/gold4.png"),
		preload("res://assets/gold/gold5.png"),
		preload("res://assets/gold/gold6.png"),
		preload("res://assets/gold/gold7.png"),
		preload("res://assets/gold/gold8.png")
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
		preload("res://assets/energy/energy_1.png"),
		preload("res://assets/energy/energy_2.png"),
		preload("res://assets/energy/energy_3.png"),
		preload("res://assets/energy/energy_4.png"),
		preload("res://assets/energy/energy_5.png"),
		preload("res://assets/energy/energy_6.png"),
		preload("res://assets/energy/energy_7.png"),
		preload("res://assets/energy/energy_8.png")
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
		preload("res://assets/diamond/diamond_1.png"),
		preload("res://assets/diamond/diamond_2.png"),
		preload("res://assets/diamond/diamond_3.png"),
		preload("res://assets/diamond/diamond_4.png"),
		preload("res://assets/diamond/diamond_5.png"),
		preload("res://assets/diamond/diamond_6.png"),
		preload("res://assets/diamond/diamond_7.png")
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
	var chest_texture := preload("res://icon.svg")
	var chest_names := [
		"Producer Supply Chest", "Grand Producer Chest"
	]
	var chest_descs := [
		"A special supply chest filled with kitchen appliances! Tap to spawn tier 1 Oven or Fridge. Exhausts and vanishes after 5 uses. Merge to reset charges!",
		"A grand culinary chest! Tap to spawn tier 1 Oven, Fridge, Rack, or Foodbox. Exhausts and vanishes after 5 uses. Merge to reset charges!"
	]
	var chest_colors := [
		Color(0.95, 0.65, 0.25), Color(1.0, 0.85, 0.35)
	]
	var chest_pools: Array[Array] = [
		["oven_1", "fridge_1"],
		["oven_1", "fridge_1", "rack_1", "foodbox_1"]
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

func _get_foodbox_pool(tier: int) -> Array[String]:
	var pool: Array[String] = ["egg_1", "egg_1", "leaf_1", "leaf_1"]
	if tier >= 2:
		pool.append("egg_2")
	if tier >= 3:
		pool.append("leaf_2")
		pool.append("gold_1")
	if tier >= 4:
		pool.append("egg_2")
		pool.append("leaf_2")
		pool.append("exp_1")
	if tier >= 5:
		pool.append("egg_3")
		pool.append("leaf_3")
		pool.append("energy_1")
	if tier >= 6:
		pool.append("egg_3")
		pool.append("leaf_3")
		pool.append("exp_2")
	return pool

func _get_oven_pool(tier: int) -> Array[String]:
	var pool: Array[String] = ["beef_1", "cake_1", "sandwich_1"]
	if tier >= 2:
		pool.append("beef_1")
		pool.append("cake_1")
		pool.append("sandwich_1")
	if tier >= 3:
		pool.append("beef_2")
		pool.append("cake_2")
		pool.append("sandwich_2")
		pool.append("gold_1")
	if tier >= 4:
		pool.append("beef_2")
		pool.append("cake_2")
		pool.append("sandwich_2")
		pool.append("exp_1")
	if tier >= 5:
		pool.append("beef_3")
		pool.append("cake_3")
		pool.append("sandwich_3")
	if tier >= 6:
		pool.append("beef_3")
		pool.append("cake_3")
		pool.append("sandwich_3")
		pool.append("exp_2")
	return pool

func _get_fridge_pool(tier: int) -> Array[String]:
	var pool: Array[String] = ["drink_1", "drink_1", "drink_1"]
	if tier >= 2:
		pool.append("drink_1")
		pool.append("drink_2")
	if tier >= 3:
		pool.append("drink_2")
		pool.append("gold_1")
	if tier >= 4:
		pool.append("drink_2")
		pool.append("drink_3")
		pool.append("energy_1")
	if tier >= 5:
		pool.append("drink_3")
		pool.append("exp_1")
	if tier >= 6:
		pool.append("drink_3")
		pool.append("drink_4")
		pool.append("exp_2")
	return pool

func _get_rack_pool(tier: int) -> Array[String]:
	var pool: Array[String] = ["util_1", "util_1", "util_2"]
	if tier >= 2:
		pool.append("util_2")
	if tier >= 3:
		pool.append("util_2")
		pool.append("util_3")
		pool.append("gold_1")
	if tier >= 4:
		pool.append("util_3")
		pool.append("exp_1")
	if tier >= 5:
		pool.append("util_3")
		pool.append("util_4")
		pool.append("energy_1")
	if tier >= 6:
		pool.append("util_4")
		pool.append("util_5")
		pool.append("exp_2")
	if tier >= 7:
		pool.append("util_5")
		pool.append("diamond_1")
	return pool

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
	return _items.get(id, null)

func has_item(id: String) -> bool:
	return _items.has(id)

func get_spawner_drop(spawner_id: String) -> String:
	var item: ItemData = get_item(spawner_id)
	if not item or not item.is_spawner or item.spawn_pool.is_empty():
		return "egg_1"
	return item.spawn_pool[randi() % item.spawn_pool.size()]

func get_all_items() -> Array:
	return _items.values()

func get_chain(chain_id: String) -> Array:
	return _chains.get(chain_id, [])
