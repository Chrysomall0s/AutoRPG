extends Node
var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

func get_random_upgrades(amount: int) -> Array:
	var pool = UpgradeData.upgrades.duplicate()
	var result = []
	var active_pool = []
	for item in pool: if item.get("weight", 0) > 0: active_pool.append(item)
	while result.size() < amount and active_pool.size() > 0:
		var chosen = _get_weighted_random(active_pool)
		result.append(chosen)
		active_pool.erase(chosen)
	return result

func _get_weighted_random(pool: Array) -> Dictionary:
	var total_weight = 0
	for item in pool: total_weight += item["weight"]
	var roll = randi() % total_weight
	var current = 0
	for item in pool:
		current += item["weight"]
		if roll < current: return item
	return pool[0]

func apply_purchase(upgrade_data: Dictionary, target_slot = null):
	if target_slot != null:
		UpgradeSystem.apply_upgrade(upgrade_data, target_slot)
	else:
		UpgradeSystem.apply_upgrade(upgrade_data, "character")
