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
        "sprite_data": {"texture": "res://Assets/atlas/fruit.tres", "frame": 1},
        "stats": 
        {
        "maxhp": 100,
        "hp": 100,
        "maxmp": 100,
        "mp": 100,
        "gold": 100
        },
        "passives": [],
        "weapons": ["Sword"],
        "audience": ["Yellow Fan"]
    },
    "char_slot2": {
        "sprite_data": {"texture": "res://Assets/atlas/fruit.tres", "frame": 0},
        "stats": 
        {
        "maxhp": 100,
        "hp": 100,
        "maxmp": 100,
        "mp": 100,
        "gold": 100
        },
        "passives": ["up3"],
        "weapons": ["Bow", "CurseStaff", "Sword","Sword","Sword","Sword" ],
        "audience": ["Blue Fan", "Yellow Fan","Blue Fan"]
    },
    "char_slot3": {
        "sprite_data": {"texture": "res://Assets/atlas/fruit.tres", "frame": 2},
        "stats": 
        {
        "maxhp": 100,
        "hp": 100,
        "maxmp": 100,
        "mp": 100,
        "gold": 100
        },
        "passives": ["up2","up1","up2","up1","up2","up1","up2","up1","up2","up1","up2","up1","up2","up1","up2","up1"],
        "weapons": ["Staff"],
        "audience": ["Violet Fan"]
    }
}

@export_group("Difficulty Button Layout")
@export var diff_btn_width_ratio: float = 0.247
@export var diff_btn_height_ratio: float = 0.06
@export var diff_btn_y_pos_ratio: float = 0.03 # Position from top

var difficulty_buttons: Array[Button] = []
var difficulty_group: ButtonGroup = ButtonGroup.new() # Shared group for auto-toggling

func _ready():
    DisplayServer.window_set_size(Vector2i(480, 852))
    randomize()
    spawn_audience()
    setup_hero_preview_position() 
    create_run_button()
    create_difficulty_buttons()

func _process(delta: float) -> void:
    player_sprite.update_weapon_movements(delta, player_sprite.position)

func setup_hero_preview_position():
    var screen_size = get_viewport_rect().size
    if is_instance_valid(player_sprite):
        player_sprite.position = screen_size * hero_display_position_ratio
        player_sprite.visible = true
        refresh_character_and_weapons()

func create_difficulty_buttons():
    var difficulties = ["Easy", "Normal", "Hard", "Insane"]
    var screen_size = get_viewport_rect().size
    
    var hbox = HBoxContainer.new()
    hbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
    # Using the ratio to set Y position dynamically
    hbox.position.y = screen_size.y * diff_btn_y_pos_ratio
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    hbox.add_theme_constant_override("separation", 10)
    add_child(hbox)

    # Calculate button size based on ratios
    var btn_size = Vector2(screen_size.x * diff_btn_width_ratio, screen_size.y * diff_btn_height_ratio)

    for i in range(difficulties.size()):
        var btn = Button.new()
        btn.text = difficulties[i]
        btn.custom_minimum_size = btn_size # Apply the calculated size
        
        btn.toggle_mode = true 
        btn.button_group = difficulty_group 
        
        if i == 1: 
            btn.button_pressed = true
            
        btn.pressed.connect(func(): _on_difficulty_selected(i + 1))
        
        hbox.add_child(btn)
        difficulty_buttons.append(btn)

func _on_difficulty_selected(value: int):
    GameManager.selected_difficulty = value
    print("Difficulty set to: ", value)
    # Optional: Update button visuals here to show which is selected

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
                var char_key = characters[seat_index]
                var char_data = character_starting_loadouts[char_key]
                
                # Pass the data so the audience sprite updates
                audience.setup_type(char_data) 
                
                audience.set_filled(true)
                audience.input_event.connect(func(_v, e, _s): 
                    if e is InputEventMouseButton and e.pressed: 
                        _on_audience_clicked(audience, seat_index)
                )
            else:
                audience.set_filled(false)
                audience.input_pickable = false

func _on_audience_clicked(clicked_member, seat_index):
    if is_instance_valid(selected_audience_member): selected_audience_member.set_filled(true)
    selected_audience_member = clicked_member
    selected_audience_member.set_filled(false)
    if seat_index < characters.size(): select_character(characters[seat_index])

func select_character(slot_name: String):
    # Reset the profile to empty
    GameManager.player_profile = {
        "stats": [],
        "passives": [],
        "weapons": [],
        "audience": []
    }
    
    var loadout = character_starting_loadouts.get(slot_name)
    if not loadout: return

    # 1. Populate Weapons
# FIX: Populate Weapons as full Dictionaries
    GameManager.player_profile["weapons"] = []
    for weapon_name in loadout.get("weapons", []):
        var full_weapon_data = _find_upgrade_by_name(weapon_name)
        if not full_weapon_data.is_empty():
            # Add a default level if missing
            var weapon_copy = full_weapon_data.duplicate()
            if not weapon_copy.has("level"): weapon_copy["level"] = 1
            GameManager.player_profile["weapons"].append(weapon_copy)
        else:
            # Fallback if the name doesn't exist in UpgradeData
            GameManager.player_profile["weapons"].append({"name": weapon_name, "level": 1})
            
    # 2. Populate Passives (Find full data first)
    for name in loadout.get("passives", []):
        var data = _find_upgrade_by_name(name)
        if data:
            GameManager.player_profile["passives"].append(data.duplicate())

    # 3. Populate Audience (Find full data first)
    for name in loadout.get("audience", []):
        var data = _find_upgrade_by_name(name)
        if data:
            GameManager.player_profile["audience"].append(data.duplicate())
    
    GameManager.player_profile["sprite_data"] = loadout.get("sprite_data")
    GameManager.player_profile["stats"] = loadout.get("stats", {}).duplicate()
    refresh_character_and_weapons()
    
func refresh_character_and_weapons():
    if is_instance_valid(player_sprite):
        player_sprite.refresh_character_and_weapons(GameManager.player_profile)

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
    run_button.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/store.tscn"))
    add_child(run_button)
