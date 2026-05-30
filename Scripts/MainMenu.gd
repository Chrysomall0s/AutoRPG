extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS
# =================================================================
@export_group("Text Typography Scaling")
@export var run_button_font_ratio: float = 0.024

@export_group("Run Button Layout")
@export var run_btn_width_ratio: float = 0.80
@export var run_btn_height_ratio: float = 0.09
@export var run_btn_bottom_margin_ratio: float = 0.04

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
@onready var player_sprite: Sprite2D = $Hero

var characters = ["char_slot1", "char_slot2", "char_slot3"]
var run_button: Button
var selected_audience_member: Node = null

var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

var weapon_sprites: Array[Sprite2D] = []
var floating_time := 0.0

var character_starting_loadouts: Dictionary = {
	"char_slot1": {
		"passives": ["Cha1", "Earring"],
		"weapons": ["Sword"],
		"audience": ["Yellow Fan"]
	},
	"char_slot2": {
		"passives": ["Cha2", "Gauntlets"],
		"weapons": ["Bow", "CurseStaff"],
		"audience": ["Blue Fan", "Yellow Fan"]
	},
	"char_slot3": {
		"passives": ["Cha1", "Breastplate"],
		"weapons": ["Staff"],
		"audience": ["Violet Fan"]
	}
}

func _ready():
	DisplayServer.window_set_size(Vector2i(480, 852))
	randomize()
	spawn_audience()
	setup_hero_preview_position() 
	create_run_button()

func _process(delta: float) -> void:
	update_weapon_positions(delta)

func setup_hero_preview_position():
	var screen_size = get_viewport_rect().size
	if is_instance_valid(player_sprite):
		player_sprite.position = screen_size * hero_display_position_ratio
		player_sprite.visible = true
		refresh_character_and_weapons()

func refresh_character_and_weapons():
	if is_instance_valid(player_sprite) and player_sprite.has_method("load_upgrade_sprites"):
		player_sprite.load_upgrade_sprites()
	spawn_floating_weapons()

func spawn_floating_weapons():
	for old_weapon in weapon_sprites:
		if is_instance_valid(old_weapon): old_weapon.queue_free()
	weapon_sprites.clear()
	
	if not is_instance_valid(player_sprite): return
	for i in range(GameManager.equipped_weapons.size()):
		var weapon_data = GameManager.equipped_weapons[i]
		if weapon_data == null or typeof(weapon_data) != TYPE_DICTIONARY: continue
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
		weapon.position = weapon.position.lerp(target_pos, delta * weapon_follow_smoothness) if delta > 0 else target_pos

func spawn_audience():
	var screen_size = get_viewport_rect().size
	var zone_size = Vector2(screen_size.x * audience_width_ratio, screen_size.y * audience_height_ratio)
	var zone_center = Vector2(screen_size.x * audience_center_x_ratio, screen_size.y * audience_center_y_ratio)
	var zone_top_left = zone_center - (zone_size / 2.0)
	var spacing_x = zone_size.x / audience_columns
	var spacing_y = zone_size.y / audience_rows
	var uniform_scale = min((spacing_x / original_sprite_width) * 0.9, (spacing_y / original_sprite_height) * 0.9)

	var character_seats = [Vector2i(3, 2), Vector2i(5, 2), Vector2i(7, 2)]

	for y in range(audience_rows):
		for x in range(audience_columns):
			var audience = AudienceScene.instantiate()
			audience_container.add_child(audience)
			audience.scale = Vector2(uniform_scale, uniform_scale)
			audience.position = zone_top_left + Vector2((x * spacing_x) + (spacing_x * 0.5 if y % 2 == 1 else 0.0), y * spacing_y)
			
			var seat_index = character_seats.find(Vector2i(x, y))
			if seat_index != -1:
				audience.set_filled(true)
				audience.input_event.connect(func(_v, e, _s): if e is InputEventMouseButton and e.pressed: _on_audience_clicked(audience, seat_index))
			else:
				audience.set_filled(false)
				audience.input_pickable = false

func _on_audience_clicked(clicked_member, seat_index):
	if is_instance_valid(selected_audience_member): selected_audience_member.set_filled(true)
	selected_audience_member = clicked_member
	selected_audience_member.set_filled(false)
	if seat_index < characters.size(): select_character(characters[seat_index])

func select_character(slot_name: String):
	GameManager.selected_character = slot_name
	GameManager.owned_upgrades = []
	GameManager.equipped_weapons = [null, null, null, null, null, null]
	GameManager.audience_members = [
		"Empty Fan","Empty Fan","Empty Fan","Empty Fan","Empty Fan",
		"Empty Fan","Empty Fan","Empty Fan","Empty Fan","Empty Fan",
		"Empty Fan","Empty Fan","Empty Fan","Empty Fan","Empty Fan",
		"Empty Fan","Empty Fan","Empty Fan","Empty Fan","Empty Fan",
		"Empty Fan","Empty Fan","Empty Fan","Empty Fan","Empty Fan",
		"Empty Fan","Empty Fan","Empty Fan","Empty Fan","Empty Fan",
		"Empty Fan","Empty Fan","Empty Fan","Empty Fan","Empty Fan",
	]
	
	var loadout = character_starting_loadouts.get(slot_name, {"passives": [], "weapons": [], "audience": []})
	
	for name in loadout.get("passives", []):
		var data = _find_upgrade_by_name(name)
		if data:
			GameManager.owned_upgrades.append(data.duplicate())
			UpgradeSystem.apply_upgrade(data, "character")

	for i in range(loadout.get("weapons", []).size()):
		var data = _find_upgrade_by_name(loadout.weapons[i])
		if data:
			GameManager.equipped_weapons[i] = data.duplicate()
			UpgradeSystem.apply_upgrade(data, str(i))
			
	for name in loadout.get("audience", []):
		var data = _find_upgrade_by_name(name)
		if data: GameManager.audience_members.append(data.duplicate())

	if GameManager.has_method("reload_player_stats"): GameManager.reload_player_stats()
	refresh_character_and_weapons()
	print("Loadout set for: ", slot_name)

func _find_upgrade_by_name(target_name: String) -> Dictionary:
	for upgrade in UpgradeData.upgrades:
		if upgrade["name"] == target_name: return upgrade
	return {}

func create_run_button():
	var screen_size = get_viewport_rect().size
	run_button = Button.new()
	run_button.text = "Run"
	var btn_size = Vector2(screen_size.x * run_btn_width_ratio, screen_size.y * run_btn_height_ratio)
	run_button.custom_minimum_size = btn_size
	run_button.position = Vector2((screen_size.x - btn_size.x) / 2.0, screen_size.y - btn_size.y - (screen_size.y * run_btn_bottom_margin_ratio))
	run_button.add_theme_font_size_override("font_size", int(screen_size.y * run_button_font_ratio))
	run_button.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/map.tscn"))
	add_child(run_button)
