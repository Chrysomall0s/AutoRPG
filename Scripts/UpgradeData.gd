# =================================================================
# res://Scripts/UpgradeData.gd
# =================================================================
extends Node

var upgrades = [
	# --- PASSIVE / NORMAL UPGRADES (Applied directly to Hero) ---
	{"name": "up1", "category": "passive", "type": "speed", "value": 2, "weight": 120, "cost": 1, "icon": "res://Assets/atlas/flower.tres","index": 0,  "level": 1},
	{"name": "up2",     "category": "passive", "type": "hp",    "value": 10, "weight": 40,  "cost": 1, "icon": "res://Assets/atlas/flower.tres","index": 1,    "level": 1},
	{"name": "up3",   "category": "passive", "type": "damage", "value": 5, "weight": 30,  "cost": 2, "icon": "res://Assets/atlas/flower.tres","index": 2,  "level": 1},
	{"name": "up4",      "category": "passive", "type": "heal",   "value": 0, "weight": 20,  "cost": 1, "icon": "res://Assets/atlas/flower.tres","index": 3,    "level": 1},
	
	# --- BASE WEAPONS (Equipped into any empty slot or replaces old weapon) ---
	{"name": "Sword","friendly":false, "category": "weapon", "type": "damage","scale": "hp","weight": 20, "cost": 2, "icon":           "res://Assets/atlas/leaf.tres","index": 0, "amount": 10, "speed": 4, "level": 1},
	{"name": "Bow","friendly":false,    "category": "weapon", "type": "damage","scale": "hp","weight": 20, "cost": 2, "icon":           "res://Assets/atlas/leaf.tres","index": 1,   "amount": 8,  "speed": 6, "level": 1},
	{"name": "Staff","friendly":true,  "category": "weapon","type": "heal","scale": "hp", "weight": 2000, "cost": 2, "icon":             "res://Assets/atlas/leaf.tres","index": 2, "amount": 14, "speed": 1, "level": 1},
	{"name": "Axe","friendly":false, "category": "weapon","type": "heal","scale": "hp", "weight": 2000, "cost": 2, "icon": "res://Assets/atlas/leaf.tres","index": 3, "amount" : 1, "speed": 6, "level": 1},
	{"name": "Curse","friendly":false, "category": "weapon","type": "damage","scale": "hp", "weight": 0, "cost": 2, "icon":            "res://Assets/atlas/leaf.tres","index": 4, "amount": 4, "speed": 3, "level": 1},
	
	# --- AUDIENCE UPGRADES ---
	{"name": "Patron", "category": "viewer", "type": "heal",   "value": 5,"weight": 30, "throw_chance": 0.005, "cost": 3, "icon":  "res://Assets/atlas/mush.tres","index": 3, "level": 1},
	{"name": "Hooligan",   "category": "viewer", "type": "damage", "value": 10,"weight": 20, "throw_chance": 0.003, "cost": 3, "icon":  "res://Assets/atlas/mush.tres","index": 7, "level": 1},
	{"name": "Zealot", "category": "viewer", "type": "damage", "value": 50,"weight": 11, "throw_chance": 0.001, "cost": 5, "icon":  "res://Assets/atlas/mush.tres","index": 11, "level": 1},
	{"name": "Heckler", "category": "viewer", "type": "damage", "value": 0,"weight": 24, "throw_chance": 0.000, "cost": 5, "icon":  "res://Assets/atlas/mush.tres","index": 15, "level": 1},
]
