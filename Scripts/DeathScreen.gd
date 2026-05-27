extends Control

func _ready():
	create_button("Retry", _on_retry_pressed)
	create_button("Main Menu", _on_menu_pressed)

func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 120)

	button.pressed.connect(callback)
	$ButtonContainer.add_child(button)


func _on_retry_pressed():
	# reset player stats
	GameManager.player_hp = 100
	GameManager.enemy_hp = 100

	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _on_menu_pressed():
	# full reset (optional but recommended)
	GameManager.player_hp = 100
	GameManager.enemy_hp = 100

	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
