# =================================================================
# res://Scripts/MonsterData.gd
# =================================================================
extends Node

var monsters = [
	{
		"name": "Foe2",
		"hp": 30,
		"damage": 6,
		"speed": 4, # Attacks every 4 ticks
		"icon": "res://Assets/Foe2.png"
	},
	{
		"name": "Foe",
		"hp": 65,
		"damage": 12,
		"speed": 6, # Attacks every 6 ticks
		"icon": "res://Assets/Foe.png"
	},
	{
		"name": "Foe1",
		"hp": 40,
		"damage": 9,
		"speed": 3, # Attacks every 3 ticks
		"icon": "res://Assets/Foe1.png"
	}
]

func get_random_monster() -> Dictionary:
	randomize()
	return monsters.pick_random().duplicate()
