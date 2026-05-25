# GameManager.gd
extends Node

# Each weapon position now carries its own unique parameters
var equipped_weapons: Array = [
	{ "name": "Basic Dagger", "icon": "res://icon.svg", "damage": 8, "speed": 6 },
	{ "name": "Iron Sword",   "icon": "res://icon.svg", "damage": 15, "speed": 3 },
	{ "name": "Magic Wand",   "icon": "res://icon.svg", "damage": 12, "speed": 4 },
	null, # Empty slot
	null, # Empty slot
	null  # Empty slot
]

var owned_upgrades: Array = []
var selected_character = ""
var selected_difficulty = 1

# --------------------------
# GLOBAL PLAYER & ENEMY STATS
# --------------------------
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
var current_tile_id: int = 4              
var cleared_tiles: Array[int] = []         
var current_floor: int = 1                

func advance_to_next_floor() -> void:
	current_floor += 1
	cleared_tiles.clear()                 
	current_tile_id = 4                   
	print("Floor advanced! Welcome to Floor: ", current_floor)
