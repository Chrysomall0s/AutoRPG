# GameManager.gd
extends Node
var outline_shader = preload("res://Assets/shaders/outline_shader.gdshader")

const AfterBattleScene = preload("res://Scenes/AfterBattle.tscn")
func go_to_after_battle(result: String):
    GameManager.after_battle_data = {
        "result": result,
        "round": GameManager.currentRound,
        "player": GameManager.player_profile,
        "enemy": GameManager.current_enemy_profile
    }

    var after = AfterBattleScene.instantiate()

    # optional: make it fullscreen UI layer
    var canvas = CanvasLayer.new()
    canvas.layer = 100

    canvas.add_child(after)
    get_tree().current_scene.add_child(canvas)

    # pause gameplay behind it
    get_tree().paused = true

# --- Profiles ---
var player_profile = {
    "stats": {},
    "passives": [],
    "weapons": [],
    "audience": []
}
var current_enemy_profile = {
    "stats": {},
    "passives": [],
    "weapons": [],
    "audience": []
}

var audience_mastery := {}
var selectedCharacter: int = 0
var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
# Inside GameManager.gd
# Inside GameManager.gd
# Use "Node" instead of "Control" to accept both Sprite2D and TextureRect
func add_weapon_type_overlay(parent_node: Node, weapon_type: String, value):
    # 1. Find the item data in UpgradeData
    var item_data = null
    for upgrade in UpgradeData.upgrades:
        if upgrade["name"] == weapon_type:
            item_data = upgrade
            break
    
    # If no data found, or no icon defined, exit
    if not item_data or not item_data.has("icon"):
        return

    # 2. Extract info from the found item
    var atlas_path = item_data["icon"]
    var overlay_index = item_data.get("index", 0)

    var region = Rect2(Vector2((overlay_index % 4) * 250, (overlay_index / 4) * 250), Vector2(250, 250))
    
    # Get the base reference size (e.g., your design resolution)
    var screen_size = get_viewport().get_visible_rect().size
    var reference_width = 1400.0
    var scale_factor = screen_size.x / reference_width *0.4

    # --- HANDLE SPRITE2D (Hero.gd) ---
    if parent_node is Sprite2D:
        var overlay = Sprite2D.new()
        var atlas = load(atlas_path).duplicate()
        atlas.region = region
        overlay.texture = atlas
        
        # Scale position and size relative to the screen
        overlay.position = Vector2(0, -20 * scale_factor)
        overlay.scale = Vector2(0.5 * scale_factor, 0.5 * scale_factor)
        parent_node.add_child(overlay)

    # --- HANDLE TEXTURERECT (Store.gd) ---
    elif parent_node is TextureRect:
        var overlay = TextureRect.new()
        overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        
        var atlas = AtlasTexture.new()
        atlas.atlas = load(atlas_path)
        atlas.region = region
        overlay.texture = atlas
        
        # Use relative sizing based on screen width
        var icon_size = 90 * scale_factor
        overlay.custom_minimum_size = Vector2(icon_size, icon_size)
        
        # Center calculation relative to the dynam0ic size(
        overlay.position = Vector2(icon_size * (0.1+value), icon_size * (0.3+value))
        
        parent_node.add_child(overlay)

func _create_weapon_sprite(weapon_info: Dictionary) -> Sprite2D:
    var weapon = Sprite2D.new()
    
    # Setup Material
    var mat = ShaderMaterial.new()
    mat.shader = outline_shader
    var lvl = weapon_info.get("level", 1.0)
    mat.set_shader_parameter("level", float(lvl))
    mat.set_shader_parameter("use_charge_shader", false)
    weapon.material = mat
    
    # Setup Texture
    var icon_path = weapon_info.get("icon")
    var atlas = load(icon_path).duplicate()
    var index = weapon_info.get("index", 0)
    var tile_size = Vector2(250, 250)
    atlas.region = Rect2(Vector2((index % 4) * tile_size.x, (index / 4) * tile_size.y), tile_size)
    weapon.texture = atlas
    
    # Add Type Overlay
    add_weapon_type_overlay(weapon, weapon_info.get("type", ""),0)
        
    # Setup Metadata
    var speed_val = weapon_info.get("speed", 3.0)
    var cooldown_duration = 1.0 / ((10.0 + speed_val) / 10.0)
    
    weapon.set_meta("weapon_type", weapon_info.get("type"))
    weapon.set_meta("amount", weapon_info.get("amount"))
    weapon.set_meta("friendly", weapon_info.get("friendly"))
    weapon.set_meta("cooldown_max", cooldown_duration)
    weapon.set_meta("cooldown_timer", randf_range(0.0, cooldown_duration))
    
    return weapon

func unlock_difficulty_mastery():
    if !audience_mastery.has(selected_difficulty):
       audience_mastery[selected_difficulty] = {}
    audience_mastery[selected_difficulty][selectedCharacter] = true

var difficulties = ["Easy", "Normal", "Hard", "Insane"]

static func _find_passive_data3(stat_name: String,target_stats: Dictionary) -> Dictionary:
    for passive in target_stats["passives"]:
        if passive.get("name") == stat_name:
            return passive
    return {} # Return empty if not found

static func addtopassive3(stat_name: String, amount: float,target_stats: Dictionary) -> void:
    var passives = _find_passive_data3(stat_name,target_stats)
    passives["level"] += amount

static func getpassive3(stat_name: String,target_stats: Dictionary) -> float:
    var passives = _find_passive_data3(stat_name,target_stats)
    # Check if the stat exists to avoid a "Key not found" error
    if passives.has("level"):
        return float(passives["level"])
    
    return 0.0

static func _find_passive_data2(stat_name: String) -> Dictionary:
    for passive in GameManager.current_enemy_profile["passives"]:
        if passive.get("name") == stat_name:
            return passive
    return {} # Return empty if not found

static func addtopassive2(stat_name: String, amount: float) -> void:
    var passives = _find_passive_data2(stat_name)
    passives["level"] += amount

static func getpassive2(stat_name: String) -> float:
    var passives = _find_passive_data2(stat_name)
    # Check if the stat exists to avoid a "Key not found" error
    if passives.has("level"):
        return float(passives["level"])
    
    return 0.0

static func _find_passive_data(stat_name: String) -> Dictionary:
    for passive in GameManager.player_profile["passives"]:
        if passive.get("name") == stat_name:
            return passive
    return {} # Return empty if not found

static func addtopassive(stat_name: String, amount: float) -> void:
    var passives = _find_passive_data(stat_name)
    passives["level"] += amount

static func getpassive(stat_name: String) -> float:
    var passives = _find_passive_data(stat_name)
    # Check if the stat exists to avoid a "Key not found" error
    if passives.has("level"):
        return float(passives["level"])
    
    return 0.0

func get_difficulty_key() -> String:
    if selected_difficulty < 0 or selected_difficulty >= difficulties.size():
        return "Easy" # fallback safety
    return difficulties[selected_difficulty]
var after_battle_data
var currentRound: int = 0
var battle_over: bool = false
var escaped: bool = false
# Place these variables inside your global auto-load script (e.g., res://Scripts/GameManager.gd)

# GameManager.gd Additions
var shop_initialized: bool = false
var shop_items: Array = []  # Stores item dictionary states and "bought" statuses
var persistent_reroll_cost: int = 10

var selected_difficulty = 1
