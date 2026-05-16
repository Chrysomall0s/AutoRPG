extends Control

func _ready():
	DisplayServer.window_set_size(Vector2i(120*4, 213*4))
	create_button("Play", _on_play_pressed)
	create_button("Settings", _on_settings_pressed)

func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(720, 120)

	button.pressed.connect(callback)
	$ButtonContainer.add_child(button)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Scenes/CharacterSelect.tscn")

func _on_settings_pressed():
	print("Settings later")
