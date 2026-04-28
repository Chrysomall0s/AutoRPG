extends Control

var weapons = ["Sword", "Axe", "Spear"]

func _ready():
	for weapon in weapons:
		create_button(weapon, func():
			select_weapon(weapon)
		)

func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 120)

	button.pressed.connect(callback)
	$ButtonContainer.add_child(button)

func select_weapon(weapon_name):
	GameManager.selected_weapon = weapon_name
	get_tree().change_scene_to_file("res://Scenes/Battle.tscn")
