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
@export var texture_path: String = ""
@export var scale: float = 1.0
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var badge_text: String = ""
@export var badge_color: Color = Color.WHITE
@export var next_tier: int = 0

func get_footprint() -> Array[Vector2i]:
	return footprint.duplicate()

## In-memory registry for extensible chains and building types.
static var _registry: Dictionary = {}
static var _initialized: bool = false

static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_register_default_bakery_chain()

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
	p_next: int
) -> Resource:
	var item = (load("res://scripts/experimental/overworld_building_data.gd") as GDScript).new()
	item.id = p_id
	item.chain_id = p_chain
	item.tier = p_tier
	item.name = p_name
	item.footprint = p_footprint
	item.footprint_desc = p_desc
	item.texture_path = p_tex
	item.scale = p_scale
	item.sprite_offset = p_offset
	item.badge_text = p_badge
	item.badge_color = p_color
	item.next_tier = p_next
	return item

static func _register_default_bakery_chain() -> void:
	var t1 = _create_item(
		"bakery_t1", "bakery", 1, "Bakery Foundation",
		[Vector2i(0, 0)], "1x1",
		"res://assets/world/1x1.png", 0.185, Vector2(13.7, -46.0),
		"T1 (1x1)", Color(0.92, 0.78, 0.42), 2
	)
	register(t1)

	var t2 = _create_item(
		"bakery_t2", "bakery", 2, "Bakery Framework",
		[Vector2i(0, 0), Vector2i(1, 0)], "1x2",
		"res://assets/world/1x2.png", 0.26, Vector2(-12.0, -38.0),
		"T2 (1x2)", Color(0.45, 0.85, 0.95), 3
	)
	register(t2)

	var t3 = _create_item(
		"bakery_t3", "bakery", 3, "Grand Bakery",
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], "2x2",
		"res://assets/world/2x2.png", 0.36, Vector2(-47.0, -98.0),
		"T3 (2x2) MAX", Color(1.0, 0.82, 0.25), 0
	)
	register(t3)

static func register(data: Resource) -> void:
	if not _registry.has(data.chain_id):
		_registry[data.chain_id] = {}
	_registry[data.chain_id][data.tier] = data

static func get_data(tier_num: int, chain: String = "bakery") -> Resource:
	_ensure_initialized()
	if _registry.has(chain) and _registry[chain].has(tier_num):
		return _registry[chain][tier_num]
	return _registry["bakery"][1]
