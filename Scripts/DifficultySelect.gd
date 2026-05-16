extends Control

func _ready():
	for i in range(1, 6):
		create_button("Difficulty " + str(i), func():
			select_difficulty(i)
		)

func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(720, 120)

	button.pressed.connect(callback)
	$ButtonContainer.add_child(button)

func select_difficulty(level):
	GameManager.selected_difficulty = level
	get_tree().change_scene_to_file("res://Scenes/WeaponSelect.tscn")
