extends Node

@export_group("Button Layout Settings")
@export var x_gap_ratio: float = 0.05
@export var y_gap_ratio: float = -0.07
@export var button_w_ratio: float = 0.08
@export var button_h_ratio: float = 0.08
@export var base_y_offset: float = 0.0
@export var base_x_offset: float = 0.05

var atlas_tex: Texture2D = preload("res://Assets/atlas/settings.tres")

# =================================================================
# PUBLIC API
# =================================================================

func create_time_buttons(parent: Control):
	_generate_row(parent, 0, 0, ["Pause", "Slow", "Normal", "Fast"])

func create_difficulty_buttons(parent: Control):
	_generate_row(parent, 1, 4, ["Easy", "Normal", "Hard", "Insane"])

# =================================================================
# INTERNAL LOGIC
# =================================================================

func _generate_row(parent: Control, row_index: int, atlas_start_index: int, labels: Array):
	var screen = parent.get_viewport_rect().size
	var num_buttons = labels.size()
	
	# 1. Calculate the width of one gap (based on x_gap_ratio)
	var gap_width = screen.x * x_gap_ratio
	
	# 2. Calculate available width after subtracting all gaps
	# We want gaps at start, between buttons, and at the end (total = num_buttons + 1)
	var total_gap_width = gap_width * (num_buttons + 1)
	var available_width = screen.x - total_gap_width
	
	# 3. Calculate button width
	var btn_w = available_width / num_buttons
	var btn_h = screen.y * button_h_ratio
	
	var y_pos = (row_index * (btn_h + (screen.y * y_gap_ratio))) + (screen.y * base_y_offset)
	
	var group = ButtonGroup.new()
	
	for i in range(num_buttons):
		# Position: Start with gap + sum of previous buttons and gaps
		var x_pos = gap_width + (i * (btn_w + gap_width))
		
		# Create button with dynamic width
		var btn = _create_btn(parent, labels[i], row_index, i, Vector2(x_pos, y_pos), atlas_start_index + i, group)
		
		# Update the width dynamically
		btn.custom_minimum_size = Vector2(btn_w, btn_h)
		
		if i == 1: btn.button_pressed = true

func _create_btn(parent: Control, text: String, row: int, index: int, pos: Vector2, atlas_index: int, group: ButtonGroup) -> Button:
	var screen_size = parent.get_viewport_rect().size
	var btn = Button.new()
	btn.toggle_mode = true
	btn.button_group = group
	btn.custom_minimum_size = Vector2(screen_size.x * button_w_ratio, screen_size.y * button_h_ratio)
	btn.position = pos
	parent.add_child(btn)

	var sprite = TextureRect.new()
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Force texture to fit the button and stay centered
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = _create_atlas_frame(atlas_index)
	btn.add_child(sprite)

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, btn.custom_minimum_size.y * 0.7)
	label.size.x = btn.custom_minimum_size.x
	label.add_theme_font_size_override("font_size", int(screen_size.y * 0.015))
	btn.add_child(label)

	btn.toggled.connect(func(toggled_on):
		sprite.texture = _create_atlas_frame(atlas_index + (8 if toggled_on else 0))
		if toggled_on: _get_callback_for_row(row, index).call()
	)
	return btn

func _get_callback_for_row(row: int, index: int) -> Callable:
	if row == 0:
		var funcs = [pausespeed, slowspeed, normalspeed, fastspeed]
		return funcs[index]
	else:
		var funcs = [easydifficulty, normaldifficulty, harddifficulty, insanedifficulty]
		return funcs[index]

# Callback functions
func pausespeed(): Engine.time_scale = 0.0
func slowspeed(): Engine.time_scale = 0.5
func normalspeed(): Engine.time_scale = 2.0
func fastspeed(): Engine.time_scale = 8.0
func easydifficulty(): GameManager.selected_difficulty = 1
func normaldifficulty(): GameManager.selected_difficulty = 2
func harddifficulty(): GameManager.selected_difficulty = 3
func insanedifficulty(): GameManager.selected_difficulty = 4

func _create_atlas_frame(index: int) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = atlas_tex
	var region_size = 250
	atlas.region = Rect2(Vector2((index % 4) * region_size, (index / 4) * region_size), Vector2(region_size, region_size))
	return atlas
