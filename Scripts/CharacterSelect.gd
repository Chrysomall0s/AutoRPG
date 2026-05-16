extends Control

var characters = ["Character1", "Character2"]

# Preload your scripts
var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()


func _ready():
	for character in characters:
		create_button(character, func():
			select_character(character)
		)

func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(720, 120)

	button.pressed.connect(callback)
	$ButtonContainer.add_child(button)

func select_character(character_name):
	GameManager.selected_character = character_name
	var weapon_data = null
	for upgrade in UpgradeData.upgrades:
		if upgrade["name"] == character_name:
			weapon_data = upgrade
			break
			
	# 2. If found, pass it to your upgrade system specifically for the "Middle" slot
	if weapon_data != null:
		UpgradeSystem.apply_upgrade(weapon_data,"")
	get_tree().change_scene_to_file("res://Scenes/DifficultySelect.tscn")
