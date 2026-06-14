extends Node

# =========================================================
# SHOP STATE LOGIC (MOVED OUT OF UI)
# =========================================================

var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()

var base_reroll_cost: int = 1

# ----------------------------
# SHOP GENERATION
# ----------------------------
func reroll() -> void:



	_generate_fresh_shop_pool()
	GameManager.persistent_reroll_cost = base_reroll_cost


func _generate_fresh_shop_pool():
	GameManager.shop_items.clear()

	var raw_upgrades = _get_random_upgrades(3)
	for upgrade in raw_upgrades:
		GameManager.shop_items.append({
			"upgrade": upgrade,
			"bought": false
		})


func _get_random_upgrades(amount: int) -> Array:
	var pool = UpgradeData.upgrades.duplicate()
	var result = []
	var active_pool = []

	for item in pool:
		if item.get("weight", 0) > 0:
			active_pool.append(item)

	while result.size() < amount and active_pool.size() > 0:
		var chosen = _get_weighted_random(active_pool)
		var item_instance = chosen.duplicate(true)
		if item_instance.get("category") == "weapon":
			item_instance["unique_id"] = "shop_" + str(Time.get_ticks_usec()) + "_" + str(randi())
			
		result.append(item_instance)
		active_pool.erase(chosen)

	return result


func _get_weighted_random(pool: Array) -> Dictionary:
	var total_weight = 0
	for item in pool:
		total_weight += item["weight"]

	var roll = randi() % total_weight
	var current = 0

	for item in pool:
		current += item["weight"]
		if roll < current:
			return item

	return pool[0]
