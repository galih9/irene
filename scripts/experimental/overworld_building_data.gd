class_name OverworldBuildingData
extends Resource

## Data definition for overworld merge buildings.
## Defines footprint geometry, visual scaling, ground offsets, and upgrade progression.

@export var id: String = ""
@export var chain_id: String = "bakery"
@export var tier: int = 1
@export var name: String = ""
@export var footprint: Array[Vector2i] = [Vector2i(0, 0)]
@export var footprint_desc: String = "1x1"
@export var tilesize: String = "1x1"
@export var texture_path: String = ""
@export var scale: float = 1.0
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var badge_text: String = ""
@export var badge_color: Color = Color.WHITE
@export var next_tier: int = 0
@export var construction_time: float = 10.0
@export var requires_construction: bool = true

func get_footprint() -> Array[Vector2i]:
	return footprint.duplicate()

## Returns the formatted "{tier}_{tilesize}" information string.
func get_info() -> String:
	return "%d_%s" % [tier, footprint_desc]

## In-memory registry for extensible chains and building types.
static var _registry: Dictionary = {}
static var _initialized: bool = false

static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_register_default_bakery_chain()
	_register_default_kitchen_chain()
	_register_default_tree_chain()
	_register_default_library_chain()

static func generate_footprint(desc: String) -> Array[Vector2i]:
	var parts := desc.split("x")
	if parts.size() != 2:
		return [Vector2i(0, 0)]
	var rows := parts[0].to_int()
	var cols := parts[1].to_int()
	var cells: Array[Vector2i] = []
	for y in range(rows):
		for x in range(cols):
			cells.append(Vector2i(x, y))
	return cells

static func _create_item(
	p_id: String,
	p_chain: String,
	p_tier: int,
	p_name: String,
	p_footprint: Array[Vector2i],
	p_desc: String,
	p_tex: String,
	p_scale: float,
	p_offset: Vector2,
	p_badge: String,
	p_color: Color,
	p_next: int,
	p_construction_time: float = 10.0,
	p_requires_construction: bool = true
) -> Resource:
	var item = (load("res://scripts/experimental/overworld_building_data.gd") as GDScript).new()
	item.id = p_id
	item.chain_id = p_chain
	item.tier = p_tier
	item.name = p_name
	item.footprint = p_footprint
	item.footprint_desc = p_desc
	item.tilesize = p_desc
	item.texture_path = p_tex
	item.scale = p_scale
	item.sprite_offset = p_offset
	item.badge_text = p_badge
	item.badge_color = p_color
	item.next_tier = p_next
	item.construction_time = p_construction_time
	item.requires_construction = p_requires_construction
	return item

static func _register_default_bakery_chain() -> void:
	var t1 = _create_item(
		"bakery_t1", "bakery", 1, "Bakery Foundation",
		generate_footprint("1x1"), "1x1",
		"res://assets/world/1x1.png", 0.185, Vector2(13.7, -46.0),
		"T1 (1x1)", Color(0.92, 0.78, 0.42), 2
	)
	register(t1)

	var t2 = _create_item(
		"bakery_t2", "bakery", 2, "Bakery Framework",
		generate_footprint("1x2"), "1x2",
		"res://assets/world/1x2.png", 0.26, Vector2(-12.0, -38.0),
		"T2 (1x2)", Color(0.45, 0.85, 0.95), 3
	)
	register(t2)

	var t3 = _create_item(
		"bakery_t3", "bakery", 3, "Grand Bakery",
		generate_footprint("2x2"), "2x2",
		"res://assets/world/2x2.png", 0.36, Vector2(-47.0, -98.0),
		"T3 (2x2) MAX", Color(1.0, 0.82, 0.25), 0
	)
	register(t3)

static func _register_default_kitchen_chain() -> void:
	var t1 = _create_item(
		"kitchen_1", "kitchen", 1, "Kitchen Prep Counter",
		generate_footprint("1x1"), "1x1",
		"res://assets/world/kitchen/1_1x1.png", 0.19, Vector2(2.0, -48.0),
		"T1 (1x1)", Color(0.92, 0.78, 0.42), 2
	)
	register(t1)

	var t2 = _create_item(
		"kitchen_2", "kitchen", 2, "Kitchen Cooktop",
		generate_footprint("1x2"), "1x2",
		"res://assets/world/kitchen/2_1x2.png", 0.26, Vector2(-10.0, -42.0),
		"T2 (1x2)", Color(0.45, 0.85, 0.95), 3
	)
	register(t2)

	var t3 = _create_item(
		"kitchen_3", "kitchen", 3, "Kitchenette",
		generate_footprint("2x2"), "2x2",
		"res://assets/world/kitchen/3_2x2.png", 0.36, Vector2(0.0, -95.0),
		"T3 (2x2)", Color(0.4, 0.9, 0.5), 4
	)
	register(t3)

	var t4 = _create_item(
		"kitchen_4", "kitchen", 4, "Bistro Kitchen",
		generate_footprint("3x2"), "3x2",
		"res://assets/world/kitchen/4_3x2.png", 0.38, Vector2(-35.0, -115.0),
		"T4 (3x2)", Color(0.35, 0.75, 1.0), 5
	)
	register(t4)

	var t5 = _create_item(
		"kitchen_5", "kitchen", 5, "Restaurant Kitchen",
		generate_footprint("3x2"), "3x2",
		"res://assets/world/kitchen/5_3x2.png", 0.40, Vector2(-55.0, -125.0),
		"T5 (3x2)", Color(0.85, 0.55, 1.0), 6
	)
	register(t5)

	var t6 = _create_item(
		"kitchen_6", "kitchen", 6, "Gourmet Kitchen",
		generate_footprint("3x3"), "3x3",
		"res://assets/world/kitchen/6_3x3.png", 0.50, Vector2(-40.0, -165.0),
		"T6 (3x3)", Color(1.0, 0.55, 0.25), 7
	)
	register(t6)

	var t7 = _create_item(
		"kitchen_7", "kitchen", 7, "Executive Kitchen",
		generate_footprint("3x3"), "3x3",
		"res://assets/world/kitchen/7_3x3.png", 0.52, Vector2(-25.0, -175.0),
		"T7 (3x3)", Color(1.0, 0.35, 0.45), 8
	)
	register(t7)

	var t8 = _create_item(
		"kitchen_8", "kitchen", 8, "Grand Gastronomy Palace",
		generate_footprint("4x4"), "4x4",
		"res://assets/world/kitchen/8_4x4.png", 0.65, Vector2(-80.0, -230.0),
		"T8 (4x4) MAX", Color(1.0, 0.84, 0.2), 0
	)
	register(t8)

static func _register_default_tree_chain() -> void:
	var t1 = _create_item(
		"tree_1", "tree", 1, "Sprout",
		generate_footprint("1x1"), "1x1",
		"res://assets/world/tree/1_1x1.tres", 1.0, Vector2(0.0, -65.0),
		"T1 (1x1)", Color(0.45, 0.85, 0.45), 2,
		0.0, false
	)
	register(t1)

	var t2 = _create_item(
		"tree_2", "tree", 2, "Small Bush",
		generate_footprint("1x1"), "1x1",
		"res://assets/world/tree/2_1x1.tres", 0.92, Vector2(0.0, -90.0),
		"T2 (1x1)", Color(0.5, 0.9, 0.5), 3,
		0.0, false
	)
	register(t2)

	var t3 = _create_item(
		"tree_3", "tree", 3, "Young Tree",
		generate_footprint("1x1"), "1x1",
		"res://assets/world/tree/3_1x1.tres", 0.88, Vector2(0.0, -100.0),
		"T3 (1x1)", Color(0.35, 0.85, 0.6), 4,
		0.0, false
	)
	register(t3)

	var t4 = _create_item(
		"tree_4", "tree", 4, "Forest Oak",
		generate_footprint("1x1"), "1x1",
		"res://assets/world/tree/4_1x1.tres", 0.82, Vector2(0.0, -115.0),
		"T4 (1x1)", Color(0.2, 0.8, 0.4), 5,
		0.0, false
	)
	register(t4)

	var t5 = _create_item(
		"tree_5", "tree", 5, "Flowering Grove",
		generate_footprint("2x2"), "2x2",
		"res://assets/world/tree/5_2x2.tres", 1.15, Vector2(0.0, -160.0),
		"T5 (2x2)", Color(0.4, 0.9, 0.7), 6,
		0.0, false
	)
	register(t5)

	var t6 = _create_item(
		"tree_6", "tree", 6, "Ancient Willow",
		generate_footprint("2x2"), "2x2",
		"res://assets/world/tree/6_2x2.tres", 1.15, Vector2(0.0, -165.0),
		"T6 (2x2)", Color(0.3, 0.85, 0.85), 7,
		0.0, false
	)
	register(t6)

	var t7 = _create_item(
		"tree_7", "tree", 7, "Whispering Arbor",
		generate_footprint("3x3"), "3x3",
		"res://assets/world/tree/7_3x3.tres", 1.5, Vector2(0.0, -195.0),
		"T7 (3x3)", Color(0.35, 0.75, 1.0), 8,
		0.0, false
	)
	register(t7)

	var t8 = _create_item(
		"tree_8", "tree", 8, "Celestial Guardian Tree",
		generate_footprint("4x4"), "4x4",
		"res://assets/world/tree/8_4x4.tres", 1.85, Vector2(0.0, -240.0),
		"T8 (4x4)", Color(0.75, 0.55, 1.0), 9,
		0.0, false
	)
	register(t8)

	var t9 = _create_item(
		"tree_9", "tree", 9, "World Tree Yggdrasil",
		generate_footprint("5x5"), "5x5",
		"res://assets/world/tree/9_5x5.tres", 2.2, Vector2(0.0, -290.0),
		"T9 (5x5) MAX", Color(1.0, 0.84, 0.2), 0,
		0.0, false
	)
	register(t9)

static func _register_default_library_chain() -> void:
	var t1 = _create_item(
		"library_1", "library", 1, "Village Reading Nook",
		generate_footprint("2x2"), "2x2",
		"res://assets/world/library/1_2x2.tres", 0.95, Vector2(-15.0, -60.0),
		"T1 (2x2)", Color(0.9, 0.78, 0.55), 2,
		10.0, true
	)
	register(t1)

	var t2 = _create_item(
		"library_2", "library", 2, "Scholar's Study",
		generate_footprint("2x2"), "2x2",
		"res://assets/world/library/2_2x2.tres", 1.05, Vector2(-10.0, -80.0),
		"T2 (2x2)", Color(0.85, 0.65, 0.6), 3,
		10.0, true
	)
	register(t2)

	var t3 = _create_item(
		"library_3", "library", 3, "Town Library",
		generate_footprint("2x2"), "2x2",
		"res://assets/world/library/3_2x2.tres", 1.0, Vector2(-12.0, -120.0),
		"T3 (2x2)", Color(0.65, 0.75, 0.95), 4,
		10.0, true
	)
	register(t3)

	var t4 = _create_item(
		"library_4", "library", 4, "Grand Athenaeum",
		generate_footprint("3x3"), "3x3",
		"res://assets/world/library/4_3x3.tres", 1.25, Vector2(-25.0, -155.0),
		"T4 (3x3)", Color(0.5, 0.85, 0.75), 5,
		10.0, true
	)
	register(t4)

	var t5 = _create_item(
		"library_5", "library", 5, "Royal Scriptorium",
		generate_footprint("4x3"), "4x3",
		"res://assets/world/library/5_4x3.tres", 1.35, Vector2(-30.0, -190.0),
		"T5 (4x3)", Color(0.85, 0.55, 1.0), 6,
		10.0, true
	)
	register(t5)

	var t6 = _create_item(
		"library_6", "library", 6, "Grand Citadel of Knowledge",
		generate_footprint("4x3"), "4x3",
		"res://assets/world/library/6_4x3.tres", 1.4, Vector2(-35.0, -220.0),
		"T6 (4x3) MAX", Color(1.0, 0.84, 0.2), 0,
		10.0, true
	)
	register(t6)

static func register(data: Resource) -> void:
	if not _registry.has(data.chain_id):
		_registry[data.chain_id] = {}
	_registry[data.chain_id][data.tier] = data

static func get_data(tier_num: int, chain: String = "bakery") -> Resource:
	_ensure_initialized()
	if _registry.has(chain) and _registry[chain].has(tier_num):
		return _registry[chain][tier_num]
	if _registry.has("tree") and _registry["tree"].has(tier_num):
		return _registry["tree"][tier_num]
	if _registry.has("library") and _registry["library"].has(tier_num):
		return _registry["library"][tier_num]
	if _registry.has("kitchen") and _registry["kitchen"].has(tier_num):
		return _registry["kitchen"][tier_num]
	if _registry.has("bakery") and _registry["bakery"].has(tier_num):
		return _registry["bakery"][tier_num]
	return _registry["bakery"][1]

static func get_data_by_id(p_id: String) -> Resource:
	_ensure_initialized()
	for chain_dict in _registry.values():
		for item in chain_dict.values():
			if item.id == p_id:
				return item
	if _registry.has(p_id) and _registry[p_id].has(1):
		return _registry[p_id][1]
	return null

static func get_max_tier(chain: String) -> int:
	_ensure_initialized()
	if _registry.has(chain):
		var max_t := 0
		for t in _registry[chain].keys():
			if int(t) > max_t:
				max_t = int(t)
		return max_t
	return 3

static func get_chains() -> Array[String]:
	_ensure_initialized()
	var chains: Array[String] = []
	for k in _registry.keys():
		chains.append(str(k))
	return chains

static func get_chain_items(chain: String) -> Array[Resource]:
	_ensure_initialized()
	var items: Array[Resource] = []
	if not _registry.has(chain):
		return items
	var tiers: Array = _registry[chain].keys()
	tiers.sort()
	for t in tiers:
		items.append(_registry[chain][t])
	return items

static func get_all_items() -> Array[Resource]:
	_ensure_initialized()
	var all_items: Array[Resource] = []
	for chain in get_chains():
		all_items.append_array(get_chain_items(chain))
	return all_items
