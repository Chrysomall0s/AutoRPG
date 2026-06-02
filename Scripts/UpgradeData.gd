# =================================================================
# res://Scripts/UpgradeData.gd
# =================================================================
extends Node

var upgrades = [
	# --- PASSIVE / NORMAL UPGRADES (Applied directly to Hero) ---
	{"name": "Breastplate", "category": "passive", "type": "speed", "value": 2, "weight": 120, "cost": 1, "icon": "res://Assets/Mods/Armour/Breastplate.png", "layer": 6000},
	{"name": "Earring",     "category": "passive", "type": "hp",    "value": 10, "weight": 40,  "cost": 1, "icon": "res://Assets/Mods/Armour/Earring.png",     "layer": 6000},
	{"name": "Gauntlets",   "category": "passive", "type": "damage", "value": 5, "weight": 30,  "cost": 2, "icon": "res://Assets/Mods/Armour/Gauntlets.png",   "layer": 6000},
	{"name": "Helmet",      "category": "passive", "type": "heal",   "value": 0, "weight": 20,  "cost": 1, "icon": "res://Assets/Mods/Armour/Helmet.png",      "layer": 6000},
	
	# --- BASE WEAPONS (Equipped into any empty slot or replaces old weapon) ---
	{"name": "Sword","friendly":false, "category": "weapon", "type": "damage","weight": 20, "cost": 2, "icon":           "res://Assets/atlas/leaf.tres","index": 0, "amount": 10, "speed": 4, "level": 1},
	{"name": "Bow","friendly":false,    "category": "weapon", "type": "damage","weight": 20, "cost": 2, "icon":           "res://Assets/atlas/leaf.tres","index": 1,   "amount": 8,  "speed": 6, "level": 1},
	{"name": "Staff","friendly":true,  "category": "weapon","type": "heal", "weight": 20, "cost": 2, "icon":             "res://Assets/atlas/leaf.tres","index": 2, "amount": 14, "speed": 3, "level": 1},
	{"name": "CurseStaff","friendly":false, "category": "weapon","type": "cursedamage", "weight": 20, "cost": 2, "icon": "res://Assets/atlas/leaf.tres","index": 3, "amount" : 1, "speed": 3, "level": 1},
	{"name": "Curse","friendly":false, "category": "weapon","type": "damage", "weight": 0, "cost": 2, "icon":            "res://Assets/atlas/leaf.tres","index": 4, "amount": 4, "speed": 3, "level": 1},
	
	# --- WEAPON MODS / UPGRADES (Must be dropped on matching weapon type to level up) ---
	{"name": "Cha1", "category": "passive", "type": "speed", "value": 0, "weight": 0, "cost": 0, "icon": "res://Assets/atlas/fruit.tres","index": 0, "layer": 6000},
	{"name": "Cha2", "category": "passive", "type": "speed", "value": 0, "weight": 0, "cost": 0, "icon": "res://Assets/atlas/fruit.tres","index": 1, "layer": 6000},

	# --- AUDIENCE UPGRADES ---
	{"name": "Yellow Fan", "category": "viewer", "type": "heal",   "value": 5,"weight": 3, "throw_chance": 0.005, "cost": 3, "icon": "res://Assets/Viewers/Yellow.png"},
	{"name": "Blue Fan",   "category": "viewer", "type": "damage", "value": 10,"weight": 2, "throw_chance": 0.003, "cost": 3, "icon": "res://Assets/Viewers/Blue.png"},
	{"name": "Violet Fan", "category": "viewer", "type": "damage", "value": 50,"weight": 1, "throw_chance": 0.001, "cost": 5, "icon": "res://Assets/Viewers/Violet.png"},
	{"name": "Empty Fan", "category": "viewer", "type": "damage", "value": 0,"weight": 0, "throw_chance": 0.000, "cost": 5, "icon": "res://Assets/Viewers/Emptyfan.png"},
]
