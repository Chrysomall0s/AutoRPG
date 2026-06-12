extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS
# =================================================================
@export_group("Text Typography Scaling")
@export var run_button_font_ratio: float = 0.024

var current_character_index: int = 0

@export_group("Run Button Layout")
@export var run_btn_width_ratio: float = 0.80
@export var run_btn_height_ratio: float = 0.09
@export var run_btn_bottom_margin_ratio: float = 0.04

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
        "icon": "res://Assets/atlas/fruit.tres", "index": 1,
        "stats":
        {},
        "passives": [],
        "weapons": ["Club",{"name": "Staff", "level": 5, "speed": 10.0}],
        "audience": ["Zealot"]
    },
    "char_slot2": {
        "icon": "res://Assets/atlas/fruit.tres", "index": 0,
        "stats":
        {},
        "passives": [{"name": "up3", "level": 30}],
        "weapons": ["Club" ],
        "audience": ["Patron", "Hooligan","Hooligan"]
    },
    "char_slot3": {
        "icon": "res://Assets/atlas/fruit.tres", "index": 2,
        "stats":
        {},
        "passives": ["up2","up1"],
        "weapons": ["Staff"],
        "audience": ["Patron"]
    }
}

const TimeController = preload("res://Scripts/time.gd")
var time_ctrl = TimeController.new()

var stats_page_instance: Node

func setup_statsbook_ui():
    var stats_scene = preload("res://Scenes/StatPage.tscn")
    stats_page_instance = stats_scene.instantiate()
    stats_page_instance.position = Vector2(get_viewport_rect().size.x * 0.65, get_viewport_rect().size.y * 0.15)
    add_child(stats_page_instance)

# Update your purchase functions to call the new instance's method
func refresh_stats():
    if is_instance_valid(stats_page_instance):
        stats_page_instance.refresh_stats()

var atlas_tex: Texture2D = preload("res://Assets/atlas/settings.tres")

func create_nav_buttons():
    # Increase this value to make the buttons and icons larger
    var button_size = Vector2(128, 128) 
    var slow_icon_index = 1 
    
    # --- Left Button (Horizontally Flipped) ---
    var btn_left = Button.new()
    btn_left.flat = true
    btn_left.custom_minimum_size = button_size
    btn_left.pressed.connect(func(): change_character(-1))
    add_child(btn_left)
    
    var sprite_left = TextureRect.new()
    sprite_left.texture = _create_atlas_frame(slow_icon_index)
    sprite_left.flip_h = true # Horizontally flipped
    sprite_left.set_anchors_preset(Control.PRESET_FULL_RECT)
    sprite_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    sprite_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    btn_left.add_child(sprite_left)
    
    # --- Right Button (Normal) ---
    var btn_right = Button.new()
    btn_right.flat = true
    btn_right.custom_minimum_size = button_size
    btn_right.pressed.connect(func(): change_character(1))
    add_child(btn_right)
    
    var sprite_right = TextureRect.new()
    sprite_right.texture = _create_atlas_frame(slow_icon_index)
    # No flip for the right button
    sprite_right.set_anchors_preset(Control.PRESET_FULL_RECT)
    sprite_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    sprite_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    btn_right.add_child(sprite_right)
    
    # Adjust positions to account for larger size
    btn_left.position = player_sprite.position + Vector2(-200, -64)
    btn_right.position = player_sprite.position + Vector2(100, -64)

# Re-use your helper function to get the texture slice
func _create_atlas_frame(index: int) -> AtlasTexture:
    var atlas = AtlasTexture.new()
    atlas.atlas = atlas_tex
    var region_size = 250
    atlas.region = Rect2(Vector2((index % 4) * region_size, (index / 4) * region_size), Vector2(region_size, region_size))
    return atlas

func change_character(direction: int):
    current_character_index = wrapi(current_character_index + direction, 0, characters.size())
    update_character_display()

func update_character_display():
    GameManager.selectedCharacter = current_character_index
    select_character(characters[current_character_index])
    refresh_stats()
    if audience_container.has_method("populate_audience"):
        audience_container.populate_audience()
    # If you want, you can trigger a visual update in AudienceManager here
    # to highlight the seat corresponding to 'current_character_index'

func _ready():

    GameManager.player_profile = {
        "stats": DEFAULT_STATS.duplicate(),
        "passives": [],
        "weapons": [null, null, null, null, null, null],
        "audience": [],
        "icon": null
    }
    GameManager.selectedCharacter = -1
    DisplayServer.window_set_size(Vector2i(480, 852))
    add_child(time_ctrl)
    time_ctrl.create_difficulty_buttons(self)
    randomize()
    setup_hero_preview_position()
    create_run_button()
     # Explicitly set to "unselected"
    setup_statsbook_ui()
    create_nav_buttons() # Add this
    update_character_display()
    
func _process(delta: float) -> void:
    player_sprite.update_weapon_movements(delta, player_sprite.position)

func setup_hero_preview_position():
    var screen_size = get_viewport_rect().size
    if is_instance_valid(player_sprite):
        player_sprite.position = screen_size * hero_display_position_ratio
        player_sprite.visible = true
        refresh_character_and_weapons()
        
const DEFAULT_STATS := {
    "maxhp": 100,
    "hp": 100,
    "maxmp": 100,
    "mp": 100,
    "gold": 100,
    "dmg": 5,
}
     
func select_character(slot_name: String):
    # Reset profile
    GameManager.current_enemy_profile = {
        "stats": {},
        "passives": [],
        "weapons": [], # We will fill this below
        "audience": []
    }
    GameManager.player_profile = {
        "stats": {},
        "passives": [],
        "weapons": [], # We will fill this below
        "audience": []
    }
    
    var loadout = character_starting_loadouts.get(slot_name)
    if not loadout: return

    # --- NEW WEAPON INITIALIZATION LOGIC ---
    var weapon_names = loadout.get("weapons", [])
    var final_weapons = []
    
    # 1. Add the weapons from your loadout (up to 6)
    for i in range(6):
        if i < weapon_names.size():
            var weapon_input = weapon_names[i] # This can be a String or a Dictionary
            
            if weapon_input == null:
                final_weapons.append(null)
            else:
                var weapon_data = get_processed_data(weapon_input)
                if not weapon_data.is_empty():
                    var weapon_copy = weapon_data.duplicate()
                    
                    # FIX: Use weapon_data["name"] instead of the raw input which might be a dictionary
                    var w_name_str = weapon_data.get("name", "unknown")
                    weapon_copy["unique_id"] = str(i) + "_" + w_name_str + "_" + str(Time.get_ticks_usec())
                    
                    weapon_copy["level"] = weapon_copy.get("level", 1)
                    final_weapons.append(weapon_copy)
                else:
                    # Fallback
                    final_weapons.append({"name": str(weapon_input), "level": 1})
        else:
            final_weapons.append(null)
            
    GameManager.player_profile["weapons"] = final_weapons
    # 2. Populate Passives (Find full data first)
    for name in loadout.get("passives", []):
        var data = get_processed_data(name)
        if data:
            GameManager.player_profile["passives"].append(data.duplicate())

    # 3. Populate Audience (Find full data first)
    for name in loadout.get("audience", []):
        var data = get_processed_data(name)
        if data:
            GameManager.player_profile["audience"].append(data.duplicate())
    
    GameManager.player_profile["icon"] = loadout.get("icon")
    GameManager.player_profile["index"] = loadout.get("index", 0) # Defaults to 0 if missing
    GameManager.player_profile["stats"] = DEFAULT_STATS.duplicate()
    GameManager.player_profile["stats"].merge(loadout.get("stats", {}), true)
    refresh_character_and_weapons()
    
func refresh_character_and_weapons():
    if is_instance_valid(player_sprite):
        player_sprite.refresh_character_and_weapons(GameManager.player_profile)

func get_processed_data(input) -> Dictionary:
    # If input is just a string, fetch default data
    if input is String:
        return _find_upgrade_by_name(input).duplicate(true)
    
    # If input is a dictionary (has overrides), fetch default and merge
    if input is Dictionary and input.has("name"):
        var base_data = _find_upgrade_by_name(input["name"]).duplicate(true)
        # Merge dictionary: values in input overwrite values in base_data
        for key in input:
            base_data[key] = input[key]
        return base_data
        
    return {}

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
    run_button.pressed.connect(func():
        # Double check that a character is actually selected
        if GameManager.selectedCharacter != -1:
            GameManager.currentRound = 0
            get_tree().change_scene_to_file("res://Scenes/Store.tscn")
        else:
            print("Action blocked: No character selected.")
    )
    add_child(run_button)
