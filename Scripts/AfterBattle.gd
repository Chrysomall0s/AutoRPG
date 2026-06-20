extends Control

var atlas_tex = preload("res://Assets/atlas/flower.tres")

const IDX_GOLD = 3
const IDX_GRAY = 2
const IDX_HEART = 0
const IDX_BROKEN = 1

var battle_data: Dictionary
var trophy_container: HBoxContainer
var heart_container: HBoxContainer
var central_icon: TextureRect
var continue_button: Button

var status_label: Label # Define this as a class variable
var leave_button: Button # Add this
func _ready():
	battle_data = GameManager.after_battle_data
	setup_layout()
	call_deferred("display_results")

func _create_atlas_frame(index: int) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = atlas_tex
	var region_size = 250
	atlas.region = Rect2(Vector2((index % 4) * region_size, (index / 4) * region_size), Vector2(region_size, region_size))
	return atlas

func setup_layout():
	var screen_size = get_viewport_rect().size
	var margin = screen_size.x * 0.05
	
	# Dynamic Sizing Calculations
	var btn_width = screen_size.x * 0.66  # 2/3 width
	var btn_height = screen_size.y * 0.12 # Relative height
	var icon_size = screen_size.y * 0.25  # Central icon size
	var item_size = screen_size.y * 0.08  # Trophies/Hearts size

	# 1. Background Overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = margin
	overlay.offset_top = margin
	overlay.offset_right = -margin
	overlay.offset_bottom = -margin
	overlay.color = Color(0, 0, 0, 0.6) 
	add_child(overlay)

	# 2. Main Content Container
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin_container)

	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	v_box.add_theme_constant_override("separation", screen_size.y * 0.03)
	margin_container.add_child(v_box)

	# Status Label (2/3 width)
	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(btn_width, btn_height)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", int(screen_size.y * 0.04))
	v_box.add_child(status_label)

	# Trophies
	trophy_container = HBoxContainer.new()
	trophy_container.alignment = BoxContainer.ALIGNMENT_CENTER
	v_box.add_child(trophy_container)

	# Central Icon
	central_icon = TextureRect.new()
	central_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	central_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	central_icon.custom_minimum_size = Vector2(icon_size, icon_size)
	v_box.add_child(central_icon)
	
	# Hearts
	heart_container = HBoxContainer.new()
	heart_container.alignment = BoxContainer.ALIGNMENT_CENTER
	v_box.add_child(heart_container)

	# Huge Continue Button
	continue_button = Button.new()
	continue_button.text = "CONTINUE"
	continue_button.custom_minimum_size = Vector2(btn_width, btn_height)
	continue_button.add_theme_font_size_override("font_size", int(screen_size.y * 0.05))
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(_on_continue_pressed)
	v_box.add_child(continue_button)

	# NEW: Leave Tournament Button
	leave_button = Button.new()
	leave_button.text = "LEAVE TOURNAMENT"
	leave_button.custom_minimum_size = Vector2(btn_width, btn_height)
	leave_button.add_theme_font_size_override("font_size", int(screen_size.y * 0.04))
	leave_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	leave_button.pressed.connect(_on_leave_pressed)
	v_box.add_child(leave_button)
	# Update item sizes in display_results loop as well:
	# Use 'item_size' for trophy_container and heart_container children

func _on_leave_pressed():
	# Reset game state if necessary before leaving
	GameManager.Defeats = 0
	GameManager.Victories = 0
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func display_results():
	var won = battle_data.get("result") == "win"
	
	# Set the label text
	if won:
		match GameManager.Victories:
			1: status_label.text = "Victory! Just the first step of many."
			2: status_label.text = "Two in a row! You're getting the hang of it."
			3: status_label.text = "Three wins! Making it look easy."
			4: status_label.text = "Four victories! A solid streak."
			5: status_label.text = "Halfway there! Keep that momentum going."
			6: status_label.text = "Six wins! You are becoming a force to be reckoned with."
			7: status_label.text = "One more before the finaly!."
			8: status_label.text = "Final showdown! Show them what you've got!"
			9: status_label.text = "You did it you won the tournament!"
			_: status_label.text = "Another victory for your collection!"
	else:
		match GameManager.Defeats:
			1: status_label.text = "Everybody loses sometimes. Shake it off!"
			2: status_label.text = "Watch out! one more loss and you're out!"
			3: status_label.text = "You've been knocked out of the tournament!"
			_: status_label.text = "A tough loss, but the journey continues."
	
	# Populate Trophies
	for i in range(9):
		var tex = TextureRect.new()
		tex.texture = _create_atlas_frame(IDX_GRAY if i < GameManager.Victories else IDX_GOLD)
		tex.custom_minimum_size = Vector2(80, 80)
		trophy_container.add_child(tex)
		tex.force_update_transform()
		tex.pivot_offset = tex.size / 2.0
		
		if won:
			tex.scale = Vector2.ZERO
			create_tween().tween_property(tex, "scale", Vector2.ONE, 0.5).set_delay(i * 0.05).set_trans(Tween.TRANS_BACK)

	# Populate Hearts (Animation removed)
	for i in range(3):
		var tex = TextureRect.new()
		# If defeat, show broken heart for the last index, otherwise show heart
		tex.texture = _create_atlas_frame(IDX_BROKEN if i < GameManager.Defeats else IDX_HEART)
		tex.custom_minimum_size = Vector2(80, 80)
		heart_container.add_child(tex)

	# Central Icon
	central_icon.texture = _create_atlas_frame(IDX_GRAY if GameManager.DidWin else IDX_BROKEN)
	central_icon.custom_minimum_size = Vector2(300, 300)
	central_icon.force_update_transform()
	central_icon.pivot_offset = central_icon.size / 2.0
	
	var tween = create_tween().set_loops()
	tween.tween_property(central_icon, "rotation_degrees", 15, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(central_icon, "rotation_degrees", -15, 1.0).set_trans(Tween.TRANS_SINE)

func _on_continue_pressed():
	var won = GameManager.Defeats == 3 ||   GameManager.Victories == 9
	if !won:
		get_tree().change_scene_to_file("res://Scenes/Store.tscn")
	else:
		GameManager.Defeats = 0
		GameManager.Victories = 0
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
