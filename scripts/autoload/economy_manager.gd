extends Node

var coins: int = 150
var gems: int = 25
var energy: int = 100
var max_energy: int = 100

var energy_regen_time: float = 6.0
var _regen_timer: float = 0.0

var infinite_energy: bool = false

func _ready() -> void:
	_regen_timer = energy_regen_time

func _process(delta: float) -> void:
	if energy < max_energy:
		_regen_timer -= delta
		if _regen_timer <= 0.0:
			_regen_timer = energy_regen_time
			add_energy(1)

func add_coins(amount: int) -> void:
	if amount == 0:
		return
	coins += amount
	GameEvents.currency_changed.emit("coins", coins, amount)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		GameEvents.currency_changed.emit("coins", coins, -amount)
		return true
	return false

func add_gems(amount: int) -> void:
	if amount == 0:
		return
	gems += amount
	GameEvents.currency_changed.emit("gems", gems, amount)

func spend_gems(amount: int) -> bool:
	if gems >= amount:
		gems -= amount
		GameEvents.currency_changed.emit("gems", gems, -amount)
		return true
	return false

func add_energy(amount: int) -> void:
	if amount == 0:
		return
	var prev := energy
	energy = clampi(energy + amount, 0, max_energy)
	var delta := energy - prev
	if delta != 0:
		GameEvents.currency_changed.emit("energy", energy, delta)

func has_energy(amount: int = 1) -> bool:
	return infinite_energy or energy >= amount

func consume_energy(amount: int = 1) -> bool:
	if infinite_energy:
		return true
	if energy >= amount:
		energy -= amount
		GameEvents.currency_changed.emit("energy", energy, -amount)
		return true
	return false

func get_seconds_to_next_energy() -> float:
	if energy >= max_energy:
		return 0.0
	return _regen_timer
