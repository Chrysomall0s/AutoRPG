# GameManager.gd
extends Node
var outline_shader = preload("res://Assets/shaders/outline_shader.gdshader")
const AfterBattleScene = preload("res://Scenes/AfterBattle.tscn")
func go_to_after_battle(result: String):
    battle_over = true
    go_to_after_battle2(result)
    
    var current_scene = get_tree().current_scene
    if not is_instance_valid(current_scene): return
    
    var audience_container = current_scene.find_child("AudienceContainer", true, false)
    if not is_instance_valid(audience_container): return

    # 1. Perform "Goldd" (Immediate)
    for seat in audience_container.get_children():
        if is_instance_valid(seat) and seat.is_filled and seat.amfriendly and seat.has_method("goldd"):
            seat.goldd()

    # 2. Perform "Throw" (Animated with Safety Checks)
    for seat in audience_container.get_children():
        # Check if seat is valid before starting the sequence for this seat
        if not is_instance_valid(current_scene) or not is_instance_valid(seat):
            continue # Skip to the next seat if this one is already gone

        if seat.is_filled and seat.has_method("perform_throw"):
            # Perform the throw twice
            for i in range(2):
                # Check validity again before the wait and before the call
                if not is_instance_valid(seat): break
                
                await get_tree().create_timer(randf_range(0.0, 0.2)).timeout
                
                if is_instance_valid(seat):
                    seat.perform_throw()

    # 3. Final Wait
    await get_tree().create_timer(1.5).timeout
    
func go_to_after_battle2(result: String):
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
var Victories = 0
var Defeats = 0
var DidWin = true
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

var GlobalUpgrades: Array = [null, null, null]


func Reroll():
    # 1. Clear existing slots
    GlobalUpgrades = [null, null, null]

    # 2. Extract potential passives for the "Type" pool
    var passive_pool = []
    for upg in UpgradeData.upgrades:
        if upg["category"] == "passive":
            passive_pool.append(upg)

    # 3. Setup global pool for the items themselves
    var item_pool = []
    for upg in UpgradeData.upgrades:
        if upg.get("weight", 0) > 0:
            item_pool.append(upg.duplicate())

    # 4. Fill 3 slots
    for i in range(3):
        if item_pool.is_empty(): break
        
        # Calculate total weight for current pool
        var total_weight = 0.0
        for item in item_pool: total_weight += item["weight"]
        
        # Weighted roll
        var roll = randf() * total_weight
        var current_sum = 0.0
        
        for idx in range(item_pool.size()):
            current_sum += item_pool[idx]["weight"]
            if roll <= current_sum:
                var selected = item_pool[idx]
                
                # Logic: If it's a weapon, assign a random passive as its type
                if selected["category"] == "weapon" and !passive_pool.is_empty():
                    var random_passive = _get_no_weighted_random(passive_pool)
                    selected["type"] = random_passive["name"]
                    selected["cost"] += random_passive["cost"]
                
                selected["unique_id"] = str(Time.get_ticks_usec()) + "_" + selected.get("name", "item") + "_" + str(i)
                GlobalUpgrades[i] = selected
                item_pool.remove_at(idx) # Prevent duplicate items in one reroll
                break

func _get_no_weighted_random(pool: Array) -> Dictionary:
    var total_w = 0.0
    for p in pool: total_w += 1
    
    var roll = randf() * total_w
    var sum = 0.0
    for p in pool:
        sum += 1
        if roll <= sum: return p
    return pool[0]
# Helper to pick from the passive pool based on weight
func _get_weighted_random(pool: Array) -> Dictionary:
    var total_w = 0.0
    for p in pool: total_w += p["weight"]
    
    var roll = randf() * total_w
    var sum = 0.0
    for p in pool:
        sum += p["weight"]
        if roll <= sum: return p
    return pool[0]
    #reroll GlobalUpgrades

# Adds an item to the first available null slot
func add_to_global_upgrades(item_data: Dictionary) -> bool:
    for i in range(GlobalUpgrades.size()):
        if GlobalUpgrades[i] == null:
            GlobalUpgrades[i] = item_data
            print("Added to global slot: ", i)
            return true
    print("No free global slots!")
    return false

# Removes an item by index
func remove_from_global_upgrades(index: int):
    if index >= 0 and index < GlobalUpgrades.size():
        GlobalUpgrades[index] = null

# Swaps two items in the global slots
func swap_global_upgrades(idx_a: int, idx_b: int):
    var temp = GlobalUpgrades[idx_a]
    GlobalUpgrades[idx_a] = GlobalUpgrades[idx_b]
    GlobalUpgrades[idx_b] = temp

var audience_mastery := {}
var selectedCharacter: int = 0
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
    mat.set_shader_parameter("use_charge_shader", true)
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

static func CleanName(stat_name: String) -> String:
    return stat_name.replace("MAX", "")

static func ReadString(stat_name: String) -> String:
    return "value" if stat_name.contains("MAX") else "level"

static func addtopassive3(stat_name: String, amount: float,target_stats: Dictionary) -> void:
    return addtopassiveREV(stat_name,amount, target_stats)

static func getpassive3(stat_name: String,target_stats: Dictionary) -> float:
    return getpassiveREV(stat_name, target_stats)
    
static func getpassive2(stat_name: String) -> float:
    return getpassiveREV(stat_name, GameManager.current_enemy_profile)

static func addtopassive2(stat_name: String, amount: float) -> void:
    return addtopassiveREV(stat_name,amount, GameManager.current_enemy_profile)

static func getpassive(stat_name: String) -> float:
    return getpassiveREV(stat_name, GameManager.player_profile)

static func addtopassive(stat_name: String, amount: float) -> void:
    return addtopassiveREV(stat_name,amount, GameManager.player_profile)

static func addpassive(stat_name: String,target_stats: Dictionary) -> Dictionary:
    var stat = ReadString(stat_name)
    stat_name = CleanName(stat_name)
    var base_data = UpgradeData.get_upgrade_by_name(stat_name)
    
    if base_data.is_empty():
        push_error("Passive not found: " + stat_name)
        return {}

    var new_passive = base_data.duplicate()
    new_passive[stat] = 0 
    target_stats["passives"].append(new_passive)
    return new_passive

static func removepassive(stat_name: String,target_stats: Dictionary) -> void:
    var passives = target_stats["passives"]
    for i in range(passives.size() - 1, -1, -1):
        if passives[i]["name"] == stat_name:
            passives.remove_at(i)

static func _find_passive_dataREV(stat_name: String,target_stats: Dictionary):
    # Safety: Ensure player_profile exists before trying to access it
    if not target_stats.has("passives"):
        return null
        
    for p in target_stats["passives"]:
        if p.get("name") == stat_name: # .get() is safer than ["name"]
            return p
    return null
        
static func addtopassiveREV(stat_name: String, amount: float,target_stats: Dictionary) -> void:
    var stat = ReadString(stat_name)
    stat_name = CleanName(stat_name)
    var passives = _find_passive_dataREV(stat_name,target_stats)
    # If it doesn't exist, create it
    if passives == null:
        passives = addpassive(stat_name,target_stats)
        
    # Update the level
    passives[stat] += amount
    # Remove if level drops to or below 0
    #if passives[stat] <= 0:
        #removepassive(stat_name,target_stats)

static func getpassiveREV(stat_name: String,target_stats: Dictionary) -> float:
    var stat = ReadString(stat_name)
    stat_name = CleanName(stat_name)
    var passives = _find_passive_dataREV(stat_name,target_stats)
    return float(passives.get(stat, 0.0)) if passives != null else 0.0

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
var persistent_reroll_cost: int = 1

var selected_difficulty = 0
