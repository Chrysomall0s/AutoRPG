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
	{"name": "Sword", "category": "weapon", "type": "damage","weight": 20, "cost": 2, "icon": "res://Assets/Weapons/Sword.png", "damage": 10, "speed": 4, "level": 1},
	{"name": "Bow",   "category": "weapon", "type": "damage","weight": 20, "cost": 2, "icon": "res://Assets/Weapons/Bow.png",   "damage": 8,  "speed": 6, "level": 1},
	{"name": "Staff", "category": "weapon","type": "heal", "weight": 20, "cost": 2, "icon": "res://Assets/Weapons/Staff.png", "heal_value": 14, "speed": 3, "level": 1},
	
	# --- WEAPON MODS / UPGRADES (Must be dropped on matching weapon type to level up) ---
	{"name": "Whetstone",      "category": "weapon_mod", "target_weapon": "Sword", "damage_bonus": 5, "speed_bonus": 0, "weight": 30, "cost": 1, "icon": "res://icon.svg"},
	{"name": "Reinforced Bowstring", "category": "weapon_mod", "target_weapon": "Bow",   "damage_bonus": 3, "speed_bonus": 1, "weight": 30, "cost": 1, "icon": "res://icon.svg"},
	{"name": "Focus Crystal",  "category": "weapon_mod", "target_weapon": "Staff", "damage_bonus": 6, "speed_bonus": 0, "weight": 30, "cost": 1, "icon": "res://icon.svg"}
]
