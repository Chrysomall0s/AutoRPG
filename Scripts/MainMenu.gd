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
@export var audience_center_x_ratio: float = 0.5  
@export var audience_center_y_ratio: float = 0.7  
@export var audience_width_ratio: float = 1.1     
@export var audience_height_ratio: float = 0.4    

@export_subgroup("Audience Grid Details")
@export var audience_columns: int = 11
@export var audience_rows: int = 6
@export var original_sprite_width: float = 44.0   
@export var original_sprite_height: float = 44.0  

@export_group("Hero Preview Position")
@export var hero_display_position_ratio: Vector2 = Vector2(0.5, 0.32) 

@export_group("Floating Rainbow Weapons Settings")
@export var rainbow_radius_x: float = 150.0
@export var rainbow_offset := Vector2(-150, -80)
@export var rainbow_radius_y: float = 150.0
@export var rainbow_y_offset: float = 45.0
@export var float_amplitude: float = 4.0
@export var float_wave_speed: float = 2.5
@export var weapon_follow_smoothness: float = 8.0
# =================================================================

@onready var AudienceScene = preload("res://Scenes/Audience.tscn")
@onready var audience_container = $AudienceContainer

# References your pre-existing scene instance, just like Shop.gd
@onready var player_sprite: Sprite2D = $Hero

# Map selection slots to clean design profile keys
var characters = ["char_slot1", "char_slot2", "char_slot3"]
var run_button: Button
var selected_audience_member: Node = null

# Preload data structures
var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

# Visual Floating Weapons tracking variables
var weapon_sprites: Array[Sprite2D] = []
var floating_time := 0.0

# Split configuration for passives and weapons
var character_starting_loadouts: Dictionary = {
	"char_slot1": {
		"passives": ["Cha1", "Earring"],
		"weapons": ["Sword"] 
	},
	"char_slot2": {
		"passives": ["Cha2", "Gauntlets"],
		"weapons": ["Axe", "Bow"] 
	},
	"char_slot3": {
		"passives": ["Cha1", "Breastplate"],
		"weapons": ["Magic Staff"]
	}
}

func _ready():
	DisplayServer.window_set_size(Vector2i(120*4, 213*4))
	randomize()
	
	spawn_audience()
	setup_hero_preview_position() 
	create_run_button()

func _process(delta: float) -> void:
	update_weapon_positions(delta)

func setup_hero_preview_position():
	var screen_size = get_viewport_rect().size
	
	if is_instance_valid(player_sprite):
		player_sprite.position = Vector2(
			screen_size.x * hero_display_position_ratio.x,
			screen_size.y * hero_display_position_ratio.y
		)
		player_sprite.visible = true
		
		# Refresh core player and weapon nodes on launch
		refresh_character_and_weapons()

# ---------------------------------
# REAL-TIME VISUAL RELOAD SYSTEM
# ---------------------------------
func refresh_character_and_weapons():
	if is_instance_valid(player_sprite) and player_sprite.has_method("load_upgrade_sprites"):
		player_sprite.load_upgrade_sprites()
		
	spawn_floating_weapons()

func spawn_floating_weapons():
	# Wipe old node references cleanly before instantiating replacement variants
	for old_weapon in weapon_sprites:
		if is_instance_valid(old_weapon):
			old_weapon.queue_free()
	weapon_sprites.clear()
	
	if not is_instance_valid(player_sprite): return

	for i in range(GameManager.equipped_weapons.size()):
		var weapon_data = GameManager.equipped_weapons[i]
		if weapon_data == null or typeof(weapon_data) != TYPE_DICTIONARY: 
			continue
		
		var weapon = Sprite2D.new()
		weapon.texture = load(weapon_data.get("icon", "res://icon.svg"))
		weapon.scale = Vector2(0.3, 0.3) 
		add_child(weapon)
		
		weapon.set_meta("slot_index", i)
		weapon.name = weapon_data.get("name", "Weapon")
		
		weapon_sprites.append(weapon)
		
	update_weapon_positions(0.0)

func update_weapon_positions(delta: float):
	if not is_instance_valid(player_sprite): return
	
	floating_time += delta
	for i in range(weapon_sprites.size()):
		var weapon = weapon_sprites[i]
		if not is_instance_valid(weapon): continue
			
		var slot_idx = weapon.get_meta("slot_index")
		var angle = float(slot_idx) * (PI / 5.0)
		var float_offset = sin(floating_time * float_wave_speed + slot_idx) * float_amplitude
		
		var target_pos = player_sprite.position + rainbow_offset + Vector2(
			-cos(angle) * rainbow_radius_x, 
			-sin(angle) * rainbow_radius_y + rainbow_y_offset + float_offset
		)
		
		if delta == 0.0:
			weapon.position = target_pos
		else:
			weapon.position = weapon.position.lerp(target_pos, delta * weapon_follow_smoothness)

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

	var character_seats: Array[Vector2i] = [
		Vector2i(3, 2),  # Seat Position for Slot 1
		Vector2i(5, 2),  # Seat Position for Slot 2
		Vector2i(7, 2)   # Seat Position for Slot 3
	]

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

			var current_coord = Vector2i(x, y)
			var seat_index = character_seats.find(current_coord)
			
			if seat_index != -1:
				audience.set_filled(true)
				setup_audience_click_detection(audience, seat_index)
			else:
				audience.set_filled(false)
				if "input_pickable" in audience:
					audience.input_pickable = false

func setup_audience_click_detection(audience_node: Node, seat_index: int):
	if "input_pickable" in audience_node:
		audience_node.input_pickable = true
		audience_node.input_event.connect(func(_viewport, event, _shape_idx):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_audience_clicked(audience_node, seat_index)
		)
	else:
		if audience_node.has_signal("gui_input"):
			audience_node.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_audience_clicked(audience_node, seat_index)
			)
			
func _on_audience_clicked(clicked_member: Node, seat_index: int):
	if is_instance_valid(selected_audience_member):
		selected_audience_member.set_filled(true)

	selected_audience_member = clicked_member
	selected_audience_member.set_filled(false)
	
	if seat_index < characters.size():
		var assigned_char = characters[seat_index]
		select_character(assigned_char)

# ---------------------------------
# CHARACTER LOADING PROCESS
# ---------------------------------
func select_character(slot_name: String):
	GameManager.selected_character = slot_name
	
	# 1. RESET PASSIVES: Wipe global item list back to baseline clean state
	GameManager.owned_upgrades = []
	
	# 2. RESET WEAPONS: Wipe inventory slots array back to empty
	GameManager.equipped_weapons = [null, null, null, null, null, null]
	
	# Fetch loadout setup dictionaries safely
	var loadout = character_starting_loadouts.get(slot_name, {"passives": [], "weapons": []})
	var passives_to_give = loadout.get("passives", [])
	var weapons_to_give = loadout.get("weapons", [])
	
	# 3. PROCESS PASSIVES
	for target_item_name in passives_to_give:
		var item_data = null
		for upgrade in UpgradeData.upgrades:
			if upgrade["name"] == target_item_name:
				item_data = upgrade
				break
				
		if item_data != null:
			GameManager.owned_upgrades.append(item_data.duplicate())
			UpgradeSystem.apply_upgrade(item_data, "character")

	# 4. PROCESS WEAPONS
	for weapon_idx in range(weapons_to_give.size()):
		if weapon_idx >= 6: break
		
		var target_weapon_name = weapons_to_give[weapon_idx]
		var weapon_data = null
		
		for upgrade in UpgradeData.upgrades:
			if upgrade["name"] == target_weapon_name:
				weapon_data = upgrade
				break
				
		if weapon_data != null:
			GameManager.equipped_weapons[weapon_idx] = weapon_data.duplicate()
			UpgradeSystem.apply_upgrade(weapon_data, str(weapon_idx))

	# 5. Sync data singletons
	if GameManager.has_method("reload_player_stats"):
		GameManager.reload_player_stats()
		
	# 6. REDRAW RENDERING & FLOATING ORBITS
	refresh_character_and_weapons()
			
	print("Loadout reset complete. Applied Passives: ", passives_to_give, " | Weapons: ", weapons_to_give)

# ---------------------------------
# DYNAMIC RUN BUTTON SYSTEM
# ---------------------------------
func create_run_button():
	var screen_size = get_viewport_rect().size
	
	run_button = Button.new()
	run_button.text = "Run"
	
	var btn_size = Vector2(
		screen_size.x * run_btn_width_ratio,
		screen_size.y * run_btn_height_ratio
	)
	run_button.custom_minimum_size = btn_size
	run_button.size = btn_size
	
	var x_pos = (screen_size.x - btn_size.x) / 2.0
	var y_pos = screen_size.y - btn_size.y - (screen_size.y * run_btn_bottom_margin_ratio)
	run_button.position = Vector2(x_pos, y_pos)
	
	var font_sz = int(screen_size.y * run_button_font_ratio)
	run_button.add_theme_font_size_override("font_size", font_sz)
	
	run_button.pressed.connect(_on_run_pressed)
	add_child(run_button)

func _on_run_pressed():
	if selected_audience_member == null:
		print("Please click on an audience member first!")
		return
		
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
