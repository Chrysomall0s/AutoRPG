# GameManager.gd
extends Node

var stat_registry = {
	"hp": {
		"name": "Health",
		"group": "Health Stats"
	},
	"maxhp": {
		"name": "Max Health",
		"group": "Health Stats"
	},
	"mp": {
		"name": "Mana",
		"group": "Resources"
	},
	"maxmp": {
		"name": "Max Mana",
		"group": "Resources"
	},
	"damage": {
		"name": "Damage",
		"group": "Combat Stats"
	},
	"crit": {
		"name": "Critical Hit",
		"group": "Combat Stats"
	},
	"attack_speed": {
		"name": "Attack Speed",
		"group": "Combat Stats"
	}
}

# --- Profiles ---
var player_profile = {
	"stats": {
		"maxhp": 100,
		"hp": 100,
		"maxmp": 100,
		"mp": 100,
		"gold": 100,
		"crit": 5,
		"attack_speed": 2
	},
	"passives": [],
	"weapons": [],
	"audience": []
}

var current_enemy_profile = {
	"stats": {
		"maxhp": 50,
		"hp": 50,
		"dmg": 4,
		"speed": 5,
	},
	"passives": ["Cha1"],
	"weapons": ["Sword"],
	"audience": ["Yellow Fan"]
}

var battle_over: bool = false
var escaped: bool = false
# Place these variables inside your global auto-load script (e.g., res://Scripts/GameManager.gd)

# GameManager.gd Additions
var shop_initialized: bool = false
var shop_items: Array = []  # Stores item dictionary states and "bought" statuses
var persistent_reroll_cost: int = 10

var selected_difficulty = 1
# --------------------------
# MAP PERSISTENCE STATS 
# --------------------------           
# GameManager.gd
var seat_priority_order: Array[Vector2i] = []

func initialize_seating(cols: int, rows: int):
	var center_x = cols / 2.0
	for y in range(rows):
		for x in range(1, cols - 1): # Skip edges
			seat_priority_order.append(Vector2i(x, y))
			
	# Sort: Front rows (high Y) first, then middle seats (low X distance)
	seat_priority_order.sort_custom(func(a, b):
		if a.y != b.y: return a.y > b.y
		return abs(a.x - center_x) < abs(b.x - center_x)
	)
