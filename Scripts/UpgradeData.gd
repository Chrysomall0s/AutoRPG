# =================================================================
# res://Scripts/UpgradeData.gd
# =================================================================
extends Node

static var upgrades = [
	# --- PASSIVE / NORMAL UPGRADES (Applied directly to Hero) ---
	{"name": "Gold", "category": "passive", "value": 1, "weight": 0, "cost": 1, "icon": "res://Assets/atlas/icon.tres","index": 0,  "level": 1},
	{"name": "HP", "category": "passive", "value": 1, "weight": 6, "cost": 1, "icon": "res://Assets/atlas/icon.tres","index": 1,  "level": 1},
	{"name": "DMG", "category": "passive", "value": 1, "weight": 7, "cost": 1, "icon": "res://Assets/atlas/icon.tres","index": 9,  "level": 1},
	{"name": "Thorns", "category": "passive", "value": 1, "weight": 13,  "cost": 1, "icon": "res://Assets/atlas/icon.tres","index": 7,    "level": 1},
	{"name": "REG",   "category": "passive", "value": 1, "weight": 30,  "cost": 2, "icon": "res://Assets/atlas/icon.tres","index": 3,  "level": 1},
	{"name": "DEF",      "category": "passive",  "value": 1, "weight": 20,  "cost": 1, "icon": "res://Assets/atlas/icon.tres","index": 2,    "level": 1},
	#{"name": "Burn",      "category": "passive",  "value": 1, "weight": 20,  "cost": 1, "icon": "res://Assets/atlas/icon.tres","index": 4,    "level": 1},
	
	# --- BASE WEAPONS (Equipped into any empty slot or replaces old weapon) ---
	{"name": "Club","friendly":true, "category": "weapon", "type": "DMG","weight": 100, "cost": 2, "icon":           "res://Assets/atlas/icon.tres","index": 12, "amount": 10, "speed": 4, "level": 0},
	{"name": "Staff","friendly":false,    "category": "weapon", "type": "DMG","weight": 100, "cost": 2, "icon":           "res://Assets/atlas/icon.tres","index": 14,   "amount": 8,  "speed": 6, "level": 0},
	
	# --- AUDIENCE UPGRADES ---
	{"name": "Patron", "category": "viewer", "type": "heal",   "value": 5,"weight": 30, "throw_chance": 0.005, "cost": 3, "icon":  "res://Assets/atlas/fruit.tres","index": 12, "level": 0},
	{"name": "Hooligan",   "category": "viewer", "type": "damage", "value": 10,"weight": 20, "throw_chance": 0.003, "cost": 3, "icon":  "res://Assets/atlas/fruit.tres","index": 7, "level": 0},
	{"name": "Zealot", "category": "viewer", "type": "damage", "value": 50,"weight": 11, "throw_chance": 0.001, "cost": 5, "icon":  "res://Assets/atlas/fruit.tres","index": 11, "level": 0},
	{"name": "Heckler", "category": "viewer", "type": "damage", "value": 0,"weight": 24, "throw_chance": 0.000, "cost": 5, "icon":  "res://Assets/atlas/fruit.tres","index": 15, "level": 0},
]

static func get_upgrade_by_name(target_name: String) -> Dictionary:
	for upgrade in upgrades:
		if upgrade["name"] == target_name:
			return upgrade
	return {}
