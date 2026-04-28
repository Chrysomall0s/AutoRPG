# GameManager.gd
extends Node

var selected_character = ""
var selected_difficulty = 1
var selected_weapon = ""

# --------------------------
# PLAYER STATS
# --------------------------
var player_hp = 100
var player_mp = 100
var player_damage = 10
var spellslot1 = -1;
var spellslot2 = -1;
var spellslot3 = -1;
# --------------------------
# OTHER
# --------------------------
var enemy_hp = 100
var gold = 0
var max_player_hp := 100
var max_enemy_hp := 100
var player_speed := 7
var enemy_speed := 5
# --------------------------
# MODULAR STORE STATS PANEL
# Add new stats here and they
# automatically show in Store
# --------------------------
var store_stats = [
	{
		"label": "Your HP",
		"get_value": func(): return player_hp
	},
	{
		"label": "Your MP",
		"get_value": func(): return player_mp
	},
	{
		"label": "Your Damage",
		"get_value": func(): return player_damage
	},
	{
		"label": "Gold",
		"get_value": func(): return gold
	},
	{
		"label": "Difficulty",
		"get_value": func(): return selected_difficulty
	},
	{
		"label": "Character",
		"get_value": func(): return selected_character
	},
	{
		"label": "Weapon",
		"get_value": func(): return selected_weapon
	}
]
