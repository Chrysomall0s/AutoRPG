extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS (RESOLUTION DYNAMIC)
# =================================================================
@export_group("Text Typography Scaling")
@export var run_button_font_ratio: float = 0.024   # Font size for the Run button (~29px)

@export_group("Run Button Layout")
@export var run_btn_width_ratio: float = 0.80     # Width of the Run button (80% of screen)
@export var run_btn_height_ratio: float = 0.09    # Height of the Run button (9% of screen)
@export var run_btn_bottom_margin_ratio: float = 0.04 # Space from the bottom edge (4%)

@export_group("Audience Stadium Positioning")
# Coordinates are percentages of your screen size (0.0 to 1.0)
@export var audience_center_x_ratio: float = 0.5  # Centered horizontally (50% of screen)
@export var audience_center_y_ratio: float = 0.7  # Placed down in lower-middle half
@export var audience_width_ratio: float = 1.1     # Total crowd spans 110% of screen width
@export var audience_height_ratio: float = 0.4    # Total crowd spans 40% of screen height

@export_subgroup("Audience Grid Details")
@export var audience_columns: int = 11
@export var audience_rows: int = 6
@export var original_sprite_width: float = 44.0   # Base width pixel size of your asset texture
@export var original_sprite_height: float = 44.0  # Base height pixel size of your asset texture
# =================================================================

@onready var AudienceScene = preload("res://Scenes/Audience.tscn")
@onready var audience_container = $AudienceContainer

var characters = ["Character1", "Character2"]
var run_button: Button
var selected_audience_member: Node = null

# Preload data dependencies
var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

func _ready():
	DisplayServer.window_set_size(Vector2i(120*4, 213*4))

	randomize()
	
	# Spawn interactive crowd
	spawn_audience()
	
	# Create and place the dynamic bottom run button
	create_run_button()

# ---------------------------------
# INTERACTIVE AUDIENCE GENERATION
# ---------------------------------
func spawn_audience():
	var screen_size = get_viewport_rect().size
	
	var zone_size = Vector2(
		screen_size.x * audience_width_ratio,
		screen_size.y * audience_height_ratio
	)
	var zone_center = Vector2(
		screen_size.x * audience_center_x_ratio,
		screen_size.y * audience_center_y_ratio
	)
	var zone_top_left = zone_center - (zone_size / 2.0)
	
	var spacing_x = zone_size.x / audience_columns
	var spacing_y = zone_size.y / audience_rows

	var scale_x = (spacing_x / original_sprite_width) * 0.9
	var scale_y = (spacing_y / original_sprite_height) * 0.9
	var uniform_scale = min(scale_x, scale_y)

	for y in range(audience_rows):
		for x in range(audience_columns):
			var audience = AudienceScene.instantiate()
			audience_container.add_child(audience)
			
			audience.scale = Vector2(uniform_scale, uniform_scale)

			var offset_x = 0.0
			if y % 2 == 1:
				offset_x = spacing_x * 0.5

			audience.position = Vector2(
				zone_top_left.x + (x * spacing_x) + offset_x,
				zone_top_left.y + (y * spacing_y)
			)

			# Ensure the audience node can process input events cleanly
			setup_audience_click_detection(audience)
			
			# Configuration: Borders (first and last column) empty, fill the inside completely
			if x == 0 or x == audience_columns - 1:
				audience.set_filled(false)
			else:
				audience.set_filled(true)


func setup_audience_click_detection(audience_node: Node):
	# 1. Enable picking on the Area2D so it listens for mouse clicks
	if "input_pickable" in audience_node:
		audience_node.input_pickable = true
		
		# 2. Connect directly to Godot's built-in area input event signal
		audience_node.input_event.connect(func(_viewport, event, _shape_idx):
			# Look for a left mouse click or screen touch press
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_audience_clicked(audience_node)
		)
	else:
		# Safety fallback in case some nodes aren't Area2Ds
		if audience_node.has_signal("gui_input"):
			audience_node.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_audience_clicked(audience_node)
			)
			
func _on_audience_clicked(clicked_member: Node):
	# If a member was hidden before, restore them to visibility
	if is_instance_valid(selected_audience_member):
		selected_audience_member.visible = true

	selected_audience_member = clicked_member
	
	# Make the selected audience member disappear
	selected_audience_member.visible = false
	
	# Pick a random character profile on click
	var random_char = characters.pick_random()
	select_character(random_char)

# ---------------------------------
# CHARACTER LOADING PROCESS
# ---------------------------------
func select_character(character_name: String):
	GameManager.selected_character = character_name
	var weapon_data = null
	
	for upgrade in UpgradeData.upgrades:
		if upgrade["name"] == character_name:
			weapon_data = upgrade
			break
			
	if weapon_data != null:
		UpgradeSystem.apply_upgrade(weapon_data, "")
	print("Selected Character Profile via Audience click: ", character_name)

# ---------------------------------
# DYNAMIC RUN BUTTON SYSTEM
# ---------------------------------
func create_run_button():
	var screen_size = get_viewport_rect().size
	
	run_button = Button.new()
	run_button.text = "Run"
	
	# Size constraints mapped directly via Inspector ratios
	var btn_size = Vector2(
		screen_size.x * run_btn_width_ratio,
		screen_size.y * run_btn_height_ratio
	)
	run_button.custom_minimum_size = btn_size
	run_button.size = btn_size
	
	# Position horizontally centered and snapped safely above the bottom margin threshold
	var x_pos = (screen_size.x - btn_size.x) / 2.0
	var y_pos = screen_size.y - btn_size.y - (screen_size.y * run_btn_bottom_margin_ratio)
	run_button.position = Vector2(x_pos, y_pos)
	
	# Typography scale
	var font_sz = int(screen_size.y * run_button_font_ratio)
	run_button.add_theme_font_size_override("font_size", font_sz)
	
	run_button.pressed.connect(_on_run_pressed)
	add_child(run_button)


func _on_run_pressed():
	if selected_audience_member == null:
		print("Please click on an audience member first!")
		return
		
	# Advance directly to the game screen route
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
