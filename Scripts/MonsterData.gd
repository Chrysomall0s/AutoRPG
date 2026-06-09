extends Node

# Updated to return an Array of monster dictionaries
var monsters = {
	"Easy": [
		{
		"sprite_data": {"texture": "res://Assets/atlas/mush.tres", "frame": 0},
			"stats": {
				"maxhp": 50,
				"hp": 50,
				"dmg": 4,
				"speed": 5,
			},
			"passives": ["Cha1"],
			"weapons": ["Sword"],
			"audience": ["Yellow Fan"]
		},
		{
			"sprite_data": {"texture": "res://Assets/atlas/mush.tres", "frame": 0},
			"stats": {
				"maxhp": 60,
				"hp": 60,
				"dmg": 5,
				"speed": 4,
			},
			"passives": ["Cha2"],
			"weapons": ["Axe"],
			"audience": ["Blue Fan"]
		},
		{
			"sprite_data": {"texture": "res://Assets/atlas/mush.tres", "frame": 0},
			"stats": {
				"maxhp": 60,
				"hp": 120,
				"dmg": 5,
				"speed": 4,
			},
			"passives": ["Cha2"],
			"weapons": ["Axe"],
			"audience": ["Blue Fan"]
		},
		{
			"sprite_data": {"texture": "res://Assets/atlas/mush.tres", "frame": 0},
			"stats": {
				"maxhp": 60,
				"hp": 200,
				"dmg": 5,
				"speed": 4,
			},
			"passives": ["Cha2"],
			"weapons": ["Axe"],
			"audience": ["Blue Fan"]
		},
	],
	"Normal": [
		{
			"sprite_data": {"texture": "res://Assets/atlas/mush.tres", "frame": 0},
			"stats": {
				"maxhp": 50,
				"hp": 50,
				"dmg": 4,
				"speed": 5,
			},
			"passives": ["Cha1"],
			"weapons": ["Sword"],
			"audience": ["Yellow Fan"]
		},
	],
	"Hard": [
		{
			"sprite_data": {"texture": "res://Assets/atlas/mush.tres", "frame": 0},
			"stats": {
				"maxhp": 50,
				"hp": 50,
				"dmg": 4,
				"speed": 5,
			},
			"passives": ["Cha1"],
			"weapons": ["Sword"],
			"audience": ["Yellow Fan"]
		},
	],
	"Insane": [
		{
			"sprite_data": {"texture": "res://Assets/atlas/mush.tres", "frame": 0},
			"stats": {
				"maxhp": 50,
				"hp": 50,
				"dmg": 4,
				"speed": 5,
			},
			"passives": ["Cha1"],
			"weapons": ["Sword"],
			"audience": ["Yellow Fan"]
		},
	],
}


func get_monster(difficulty_key: String, round: int) -> Dictionary:
	if !monsters.has(difficulty_key):
		return {}

	var difficulty_monsters = monsters[difficulty_key]

	if round < 0 or round >= difficulty_monsters.size():
		return {}

	return difficulty_monsters[round]
