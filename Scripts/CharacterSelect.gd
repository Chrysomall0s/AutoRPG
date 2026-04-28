extends Control

var characters = ["Knight", "Archer", "Mage"]

func _ready():
	for character in characters:
		create_button(character, func():
			select_character(character)
		)

func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 120)

	button.pressed.connect(callback)
	$ButtonContainer.add_child(button)

func select_character(character_name):
	GameManager.selected_character = character_name
	get_tree().change_scene_to_file("res://Scenes/DifficultySelect.tscn")
