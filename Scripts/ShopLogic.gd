extends Node

# =========================================================
# SHOP STATE LOGIC (MOVED OUT OF UI)
# =========================================================

var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

var base_reroll_cost: int = 10


# ----------------------------
# SHOP GENERATION
# ----------------------------
func reroll() -> void:
	if GameManager.player_profile["stats"]["gold"] < GameManager.persistent_reroll_cost:
		return

	GameManager.player_profile["stats"]["gold"] -= GameManager.persistent_reroll_cost

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
		result.append(chosen)
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


# ----------------------------
# WEAPON EQUIPMENT
# ----------------------------
func equip_weapon(weapon: Dictionary, slot_index: int) -> void:
	var weapons = GameManager.player_profile.get("weapons", [])

	while weapons.size() <= slot_index:
		weapons.append(null)

	weapons[slot_index] = weapon.duplicate()


func unequip_weapon(slot_index: int) -> void:
	var weapons = GameManager.player_profile.get("weapons", [])
	if slot_index < weapons.size():
		weapons[slot_index] = null


func use_upgrade_on_weapon(upgrade: Dictionary, slot_index: int) -> void:
	var weapons = GameManager.player_profile.get("weapons", [])

	if slot_index >= weapons.size():
		return

	var weapon = weapons[slot_index]
	if weapon == null:
		return

	if upgrade.get("category") == "weapon_mod":
		weapon["level"] = weapon.get("level", 1) + 1
		weapon["damage"] = weapon.get("damage", 0) + upgrade.get("damage_bonus", 0)

		UpgradeSystem.apply_upgrade(upgrade, str(slot_index))


# ----------------------------
# PASSIVE UPGRADES
# ----------------------------
func buy_passive_upgrade(upgrade: Dictionary) -> bool:
	var cost = upgrade.get("cost", 0)

	if GameManager.player_profile["stats"]["gold"] < cost:
		return false

	GameManager.player_profile["stats"]["gold"] -= cost

	var profile = GameManager.player_profile

	if upgrade.get("category") == "viewer":
		if not profile.has("audience_members"):
			profile["audience_members"] = []
		profile["audience_members"].append(upgrade.duplicate())
	else:
		if not profile.has("passives"):
			profile["passives"] = []
		profile["passives"].append(upgrade.duplicate())

		UpgradeSystem.upgradeStats(upgrade.duplicate())

	return true
