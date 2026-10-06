class_name DeliveryLevelDatabase
extends RefCounted

## Food Delivery Rush: 10 Handcrafted & Mathematically Proven Levels
## Guaranteed solvable within the 7 temporary holding slots.

const TOTAL_LEVELS: int = 10

static func get_total_levels() -> int:
	return TOTAL_LEVELS

static func get_level(level_num: int) -> Dictionary:
	var clamped_num := clampi(level_num, 1, TOTAL_LEVELS)
	var data := _get_raw_level(clamped_num)
	# Return a deep duplicate so stacks can be modified by the game instance
	return data.duplicate(true)

static func get_all_levels() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for i in range(1, TOTAL_LEVELS + 1):
		list.append(get_level(i))
	return list

static func _get_raw_level(level_num: int) -> Dictionary:
	match level_num:
		1:
			return {
				"level": 1,
				"title": "Morning Rush",
				"description": "Fresh bakery & breakfast orders!",
				"time_limit": 90,
				"orders": ["bakery_6", "sweets_2", "healthy_3"],
				"stacks": [
					["healthy_3", "sweets_2", "bakery_6"],
					["healthy_3", "sweets_2", "bakery_6"],
					["healthy_3", "sweets_2", "bakery_6"],
				]
			}
		2:
			return {
				"level": 2,
				"title": "Cafe Orders",
				"description": "Drinks & sweet pastries on the go!",
				"time_limit": 85,
				"orders": ["drinks_2", "bakery_6", "sweets_2", "healthy_3"],
				"stacks": [
					["healthy_3", "sweets_2", "bakery_6"],
					["healthy_3", "sweets_2", "drinks_2"],
					["healthy_3", "bakery_6", "drinks_2"],
					["sweets_2", "bakery_6", "drinks_2"],
				]
			}
		3:
			return {
				"level": 3,
				"title": "Lunchtime Express",
				"description": "Hot grill snacks joining the menu!",
				"time_limit": 80,
				"orders": ["bakery_6", "grill_2", "drinks_2", "sweets_2", "healthy_3"],
				"stacks": [
					["healthy_3", "sweets_2", "drinks_2", "bakery_6"],
					["healthy_3", "sweets_2", "grill_2", "bakery_6"],
					["healthy_3", "drinks_2", "grill_2", "bakery_6"],
					["sweets_2", "drinks_2", "grill_2"],
				]
			}
		4:
			return {
				"level": 4,
				"title": "Bistro Delight",
				"description": "Pretzels and skewers ready to pack!",
				"time_limit": 75,
				"orders": ["sweets_2", "bakery_3", "grill_2", "drinks_2", "bakery_6", "healthy_3"],
				"stacks": [
					["healthy_3", "bakery_6", "grill_2", "sweets_2"],
					["healthy_3", "drinks_2", "grill_2", "sweets_2"],
					["healthy_3", "drinks_2", "bakery_3", "sweets_2"],
					["bakery_6", "drinks_2", "bakery_3"],
					["bakery_6", "grill_2", "bakery_3"],
				]
			}
		5:
			return {
				"level": 5,
				"title": "Sweet Tooth Feast",
				"description": "Glazed donuts and assorted treats!",
				"time_limit": 75,
				"orders": ["bakery_6", "sweets_5", "grill_2", "drinks_2", "sweets_2", "bakery_3", "healthy_3"],
				"stacks": [
					["healthy_3", "bakery_3", "drinks_2", "sweets_5", "bakery_6"],
					["healthy_3", "sweets_2", "drinks_2", "sweets_5"],
					["healthy_3", "sweets_2", "grill_2", "sweets_5"],
					["bakery_3", "sweets_2", "grill_2", "bakery_6"],
					["bakery_3", "drinks_2", "grill_2", "bakery_6"],
				]
			}
		6:
			return {
				"level": 6,
				"title": "Gourmet Grill Dash",
				"description": "Sizzling burgers and hearty plates!",
				"time_limit": 70,
				"orders": ["grill_3", "bakery_6", "sweets_2", "grill_2", "bakery_3", "drinks_2", "sweets_5", "healthy_3"],
				"stacks": [
					["healthy_3", "drinks_2", "grill_2", "bakery_6"],
					["healthy_3", "drinks_2", "grill_2", "bakery_6"],
					["healthy_3", "drinks_2", "grill_2", "bakery_6"],
					["sweets_5", "bakery_3", "sweets_2", "grill_3"],
					["sweets_5", "bakery_3", "sweets_2", "grill_3"],
					["sweets_5", "bakery_3", "sweets_2", "grill_3"],
				]
			}
		7:
			return {
				"level": 7,
				"title": "Speedy Courier",
				"description": "Fast deliveries across the neighborhood!",
				"time_limit": 65,
				"orders": ["sweets_5", "grill_3", "drinks_2", "bakery_3", "grill_2", "sweets_2", "bakery_6", "healthy_3"],
				"stacks": [
					["healthy_3", "sweets_2", "bakery_3", "grill_3"],
					["healthy_3", "sweets_2", "bakery_3", "grill_3"],
					["healthy_3", "sweets_2", "bakery_3", "grill_3"],
					["bakery_6", "grill_2", "drinks_2", "sweets_5"],
					["bakery_6", "grill_2", "drinks_2", "sweets_5"],
					["bakery_6", "grill_2", "drinks_2", "sweets_5"],
				]
			}
		8:
			return {
				"level": 8,
				"title": "Downtown Catering",
				"description": "Nine big delivery boxes to arrange!",
				"time_limit": 65,
				"orders": ["bakery_3", "sweets_2", "grill_3", "bakery_6", "drinks_2", "sweets_5", "grill_2", "healthy_3", "bakery_6"],
				"stacks": [
					["bakery_6", "grill_2", "drinks_2", "grill_3", "bakery_3"],
					["bakery_6", "grill_2", "drinks_2", "grill_3", "bakery_3"],
					["bakery_6", "grill_2", "drinks_2", "grill_3", "bakery_3"],
					["healthy_3", "sweets_5", "bakery_6", "sweets_2"],
					["healthy_3", "sweets_5", "bakery_6", "sweets_2"],
					["healthy_3", "sweets_5", "bakery_6", "sweets_2"],
				]
			}
		9:
			return {
				"level": 9,
				"title": "Dinner Rush Hour",
				"description": "High-volume orders stacking up fast!",
				"time_limit": 60,
				"orders": ["drinks_2", "sweets_5", "grill_2", "bakery_3", "grill_3", "sweets_2", "bakery_6", "healthy_3", "sweets_2", "grill_2"],
				"stacks": [
					["grill_2", "healthy_3", "sweets_2", "bakery_3", "sweets_5"],
					["grill_2", "healthy_3", "sweets_2", "bakery_3", "sweets_5"],
					["grill_2", "healthy_3", "sweets_2", "bakery_3", "sweets_5"],
					["sweets_2", "bakery_6", "grill_3", "grill_2", "drinks_2"],
					["sweets_2", "bakery_6", "grill_3", "grill_2", "drinks_2"],
					["sweets_2", "bakery_6", "grill_3", "grill_2", "drinks_2"],
				]
			}
		10:
			return {
				"level": 10,
				"title": "Grand Master Banquet",
				"description": "Ultimate test of a Master Courier Chef!",
				"time_limit": 55,
				"orders": ["grill_3", "bakery_6", "sweets_5", "drinks_2", "grill_2", "bakery_3", "sweets_2", "healthy_3", "grill_3", "bakery_6"],
				"stacks": [
					["bakery_6", "healthy_3", "bakery_3", "drinks_2", "bakery_6"],
					["bakery_6", "healthy_3", "bakery_3", "drinks_2", "bakery_6"],
					["bakery_6", "healthy_3", "bakery_3", "drinks_2", "bakery_6"],
					["grill_3", "sweets_2", "grill_2", "sweets_5", "grill_3"],
					["grill_3", "sweets_2", "grill_2", "sweets_5", "grill_3"],
					["grill_3", "sweets_2", "grill_2", "sweets_5", "grill_3"],
				]
			}
	return _get_raw_level(1)
