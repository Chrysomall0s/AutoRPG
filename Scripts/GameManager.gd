# GameManager.gd
extends Node

# Each weapon position now carries its own unique parameters
var equipped_weapons: Array = [
	null,
	null,
	null,
	null, # Empty slot
	null, # Empty slot
	null  # Empty slot
]

var audience_members = []
var battle_over: bool = false
var escaped: bool = false
# Place these variables inside your global auto-load script (e.g., res://Scripts/GameManager.gd)
var map_layout_initialized: bool = false
var current_floor: int = 1
var current_tile_id: int = 4

var persistent_tile_assignments: Dictionary = {}
var persistent_bridge_definitions: Array = []
var cleared_tiles: Array[int] = []


# GameManager.gd Additions
var shop_initialized: bool = false
var persistent_shop_upgrades: Array = []  # Stores item dictionary states and "bought" statuses
var persistent_reroll_cost: int = 10
var persistent_items_bought_this_turn: int = 0

var owned_upgrades: Array = []
var selected_character = ""
var selected_difficulty = 1

# --------------------------
# GLOBAL PLAYER & ENEMY STATS
# --------------------------
var persistent_monster_profiles: Dictionary = {} # Maps tile_id -> Monster Dictionary
var current_enemy_profile: Dictionary = {}       # Currently active monster profile

var player_hp = 100
var player_mp = 100
var enemy_dmg = 4
var enemy_hp = 100

var gold = 100
var max_player_hp := 100
var max_enemy_hp := 50
var enemy_speed := 5 # Ticks required for the enemy to strike back

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
	
func advance_to_next_floor() -> void:
	current_floor += 1
	cleared_tiles.clear()                 
	current_tile_id = 4                    
	print("Floor advanced! Welcome to Floor: ", current_floor)
