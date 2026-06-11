extends Control

var battle_data: Dictionary = {}

var panel: Panel
var title_label: Label
var subtitle_label: Label
var continue_button: Button


func _ready():
	battle_data = GameManager.after_battle_data
	build_ui()
	apply_data()


# =========================
# UI BUILDING
# =========================
func build_ui():
	# full screen container background
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = Panel.new()
	panel.custom_minimum_size = Vector2(600, 400)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# TITLE
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 64)
	vbox.add_child(title_label)

	# SUBTITLE
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(subtitle_label)

	# SPACER
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# BUTTON
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(300, 80)
	continue_button.add_theme_font_size_override("font_size", 28)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(continue_button)


# =========================
# DATA DISPLAY
# =========================
var is_tournament_complete := false
func apply_data():
	var result = battle_data.get("result", "lose")

	if result != "win":
		title_label.text = "DEFEAT"
		subtitle_label.text = "You were overwhelmed..."
		return

	var difficulty = GameManager.selected_difficulty
	var round = GameManager.currentRound

	var MonsterData = preload("res://Scripts/MonsterData.gd").new()
	is_tournament_complete = !MonsterData.has_next_round(difficulty, round)

	if is_tournament_complete:
		title_label.text = "TOURNAMENT CLEARED"
		subtitle_label.text = "All opponents defeated!"
	else:
		title_label.text = "VICTORY"
		subtitle_label.text = "You defeated your opponent!"


# =========================
# BUTTON ACTION
# =========================
func _on_continue_pressed():
	get_tree().paused = false
	Engine.time_scale = 1.0

	var result = GameManager.after_battle_data.get("result", "lose")

	if result == "win":
		if is_tournament_complete:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/Store.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
