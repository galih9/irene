class_name ItemData
extends Resource

@export var id: String = ""
@export var chain_id: String = ""
@export var chain_name: String = ""
@export var tier: int = 1
@export var max_tier: int = 5
@export var display_name: String = ""
@export var description: String = ""
@export var color: Color = Color.WHITE
@export var icon_scale: float = 1.0
@export var icon_texture: Texture2D = null

# Spawner attributes
@export var is_spawner: bool = false
@export var spawn_pool: Array[String] = []
@export var energy_cost: int = 1
@export var min_spawner_tier: int = 3
@export var max_charges: int = 10
@export var cooldown_per_charge: float = 5.0

# Consumable attributes (e.g. Coins, Energy batteries)
@export var is_consumable: bool = false
@export var consume_currency: String = "" # "coins" or "energy"
@export var consume_amount: int = 0

# Economy
@export var sell_value: int = 1

func get_next_tier_id() -> String:
	if tier >= max_tier:
		return ""
	return "%s_%d" % [chain_id, tier + 1]
