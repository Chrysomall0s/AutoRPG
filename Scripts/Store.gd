extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS
# =================================================================
@export_group("Text Typography Scaling")
@export var gold_label_font_ratio: float = 0.028   
@export var shop_button_font_ratio: float = 0.022  
@export var slot_button_font_ratio: float = 0.022  

@export_group("Shop Item UI Layout")
@export var shop_item_width_ratio: float = 0.30  
@export var shop_item_height_ratio: float = 0.095 

@export_group("Slot Selection Layout")
@export var slot_button_width_ratio: float = 0.30  
@export var slot_button_height_ratio: float = 0.10  

@export_group("Persistent UI Offsets")
@export var gold_label_x_ratio: float = 0.04     
@export var gold_label_y_ratio: float = 0.02     
@export var master_shop_y_ratio: float = 0.53

@export_group("Floating Rainbow Weapons Settings")
@export var rainbow_radius_x: float = 150.0
@export var rainbow_offset := Vector2(-150, -80)
@export var rainbow_radius_y: float = 150.0
@export var rainbow_y_offset: float = 45.0
@export var float_amplitude: float = 4.0
@export var float_wave_speed: float = 2.5
@export var weapon_follow_smoothness: float = 8.0

@onready var gold_label: Label = Label.new()
@onready var player_sprite = $Hero 

var master_shop_container: VBoxContainer
var main_button_container: HBoxContainer 
var utility_button_container: HBoxContainer
var slot_button_container: GridContainer 

var upgrade_buttons = [] 
var base_reroll_cost: int = 10

var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()
var reroll_button: Button

var weapon_sprites: Array[Sprite2D] = []
var floating_time := 0.0

var stats_container: VBoxContainer
var stats_label: Label
var current_page_index: int = 0
var stat_pages = [
    {"title": "Health Stats", "stats": ["hp_current", "max_health", "regeneration"]},
    {"title": "Damage Stats", "stats": ["damage", "critical_hit", "attack_speed"]}
]

@export_group("Statsbook Layout")
@export var statsbook_x_ratio: float = 0.65
@export var statsbook_y_ratio: float = 0.15
@export var statsbook_font_ratio: float = 0.02

func _ready():
    randomize()
    setup_gold_ui()

    master_shop_container = VBoxContainer.new()
    master_shop_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
    master_shop_container.add_theme_constant_override("separation", 25) 
    add_child(master_shop_container)

    main_button_container = HBoxContainer.new()
    main_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
    main_button_container.add_theme_constant_override("separation", 15) 
    master_shop_container.add_child(main_button_container)

    utility_button_container = HBoxContainer.new()
    utility_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
    utility_button_container.add_theme_constant_override("separation", 15)
    master_shop_container.add_child(utility_button_container)

    slot_button_container = GridContainer.new()
    slot_button_container.columns = 3
    slot_button_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    slot_button_container.add_theme_constant_override("h_separation", 15)
    slot_button_container.add_theme_constant_override("v_separation", 15)
    master_shop_container.add_child(slot_button_container)

    if not GameManager.get("shop_initialized"):
        generate_fresh_shop_pool()
        GameManager.shop_initialized = true

    draw_shop_from_persistent_memory()
    create_reroll_button()
    create_button("Leave", _play)
    
    update_gold()
    setup_six_slots_ui()
    setup_statsbook_ui()
    refresh_character_and_weapons()
    
    await get_tree().process_frame
    adjust_layout_containers()

func setup_statsbook_ui():
    var screen_size = get_viewport_rect().size
    
    stats_container = VBoxContainer.new()
    # Position based on ratio
    stats_container.position = Vector2(screen_size.x * statsbook_x_ratio, screen_size.y * statsbook_y_ratio)
    
    stats_label = Label.new()
    # Dynamic font size
    stats_label.add_theme_font_size_override("font_size", int(screen_size.y * statsbook_font_ratio))
    stats_label.custom_minimum_size = Vector2(screen_size.x * 0.15, screen_size.y * 0.3)
    stats_container.add_child(stats_label)
    
    var flip_button = Button.new()
    flip_button.text = "Flip Page"
    flip_button.add_theme_font_size_override("font_size", int(screen_size.y * statsbook_font_ratio))
    flip_button.pressed.connect(flip_stats_page)
    stats_container.add_child(flip_button)
    
    add_child(stats_container)
    update_stats_display()

func update_stats_display():
    if not is_instance_valid(stats_label): return
    
    var page = stat_pages[current_page_index]
    var text = page["title"] + "\n----------------\n"
    
    for stat_key in page["stats"]:
        var val = GameManager.get(stat_key)
        # Use .replace("_", " ") for cleaner labels
        var label_name = stat_key.replace("_", " ").capitalize()
        text += label_name + ": " + str(val if val != null else 0) + "\n"
    
    stats_label.text = text

func flip_stats_page():
    current_page_index = (current_page_index + 1) % stat_pages.size()
    update_stats_display()

func _process(delta: float) -> void:
    update_weapon_positions(delta)

func adjust_layout_containers():
    var screen_size = get_viewport_rect().size
    gold_label.position = Vector2(screen_size.x * gold_label_x_ratio, screen_size.y * gold_label_y_ratio)
    master_shop_container.position = Vector2(
        (screen_size.x - master_shop_container.size.x) / 2.0,
        screen_size.y * master_shop_y_ratio
    )
    if is_instance_valid(stats_container):
        stats_container.position = Vector2(screen_size.x * statsbook_x_ratio, screen_size.y * statsbook_y_ratio)

# ---------------------------------
# WEAPON ORBIT & REFRESH LOGIC
# ---------------------------------
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
        if delta == 0.0: weapon.position = target_pos
        else: weapon.position = weapon.position.lerp(target_pos, delta * weapon_follow_smoothness)

# ---------------------------------
# SHOP LOGIC
# ---------------------------------
func get_random_upgrades(amount: int) -> Array:
    var pool = UpgradeData.upgrades.duplicate()
    var result = []
    var active_pool = []
    for item in pool:
        if item.get("weight", 0) > 0: active_pool.append(item)
            
    while result.size() < amount and active_pool.size() > 0:
        var chosen = get_weighted_random(active_pool)
        result.append(chosen)
        active_pool.erase(chosen)
    return result

func get_weighted_random(pool: Array) -> Dictionary:
    var total_weight = 0
    for item in pool: total_weight += item["weight"]
    var roll = randi() % total_weight
    var current = 0
    for item in pool:
        current += item["weight"]
        if roll < current: return item
    return pool[0]

func generate_fresh_shop_pool():
    GameManager.persistent_items_bought_this_turn = 0
    GameManager.persistent_reroll_cost = base_reroll_cost
    GameManager.persistent_shop_upgrades.clear()
    var raw_upgrades = get_random_upgrades(3)
    for upgrade in raw_upgrades:
        GameManager.persistent_shop_upgrades.append({"upgrade": upgrade, "bought": false})

func draw_shop_from_persistent_memory():
    for entry in upgrade_buttons:
        if is_instance_valid(entry["button"]): entry["button"].queue_free()
    upgrade_buttons.clear()
    for i in range(GameManager.persistent_shop_upgrades.size()):
        create_upgrade_button(GameManager.persistent_shop_upgrades[i], i)
    update_upgrade_colors()

func create_upgrade_button(global_entry: Dictionary, position_index: int):
    var upgrade = global_entry["upgrade"]
    var button = DragShopButton.new(upgrade, self)
    
    var cat = upgrade.get("category")
    var action_hint = "\n[Drag to Slot]" if cat == "weapon" else "\n[Tap to Buy]"
    if cat == "weapon_mod": action_hint = "\n[Drag to Mod]"
        
    button.text = upgrade["name"] + " (" + str(upgrade["cost"]) + "G)" + action_hint
    
    var screen_size = get_viewport_rect().size
    button.custom_minimum_size = Vector2(screen_size.x * shop_item_width_ratio, screen_size.y * shop_item_height_ratio)
    button.add_theme_font_size_override("font_size", int(screen_size.y * shop_button_font_ratio))
    button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    
    var entry = {"button": button, "global_reference": global_entry, "upgrade": upgrade, "bought": global_entry["bought"]}
    button.entry_reference = entry
    upgrade_buttons.append(entry)
    main_button_container.add_child(button)

    if global_entry["bought"]:
        button.text = "-- SOLD OUT --"; button.disabled = true
    else:
        button.pressed.connect(func():
            if cat == "passive" or cat == "viewer": handle_passive_purchase(entry)
        )

func handle_passive_purchase(entry_ref: Dictionary):
    var upgrade_data = entry_ref["upgrade"]
    if GameManager.gold < upgrade_data["cost"] or entry_ref["bought"]: return
    GameManager.gold -= upgrade_data["cost"]
    
    if upgrade_data.get("category") == "viewer":
        GameManager.audience_members.append(upgrade_data.duplicate())
    else:
        GameManager.owned_upgrades.append(upgrade_data.duplicate())
        UpgradeSystem.apply_upgrade(upgrade_data, "character")
    
    finalize_item_purchase(entry_ref)
    update_gold()
    refresh_character_and_weapons()

func handle_drag_drop_purchase(upgrade_data: Dictionary, target_slot_index: int, entry_ref: Dictionary):
    if GameManager.gold < upgrade_data["cost"]: return
    var category = upgrade_data.get("category", "")
    var existing = GameManager.equipped_weapons[target_slot_index]
    
    if category == "weapon":
        GameManager.gold -= upgrade_data["cost"]
        GameManager.equipped_weapons[target_slot_index] = upgrade_data.duplicate()
        UpgradeSystem.apply_upgrade(upgrade_data, str(target_slot_index))
    elif category == "weapon_mod":
        if existing == null or existing.get("name") != upgrade_data.get("target_weapon"): return
        GameManager.gold -= upgrade_data["cost"]
        existing["level"] += 1
        existing["damage"] += upgrade_data.get("damage_bonus", 0)
        UpgradeSystem.apply_upgrade(upgrade_data, str(target_slot_index))
        
    finalize_item_purchase(entry_ref)
    update_gold()
    setup_six_slots_ui()
    refresh_character_and_weapons()

func finalize_item_purchase(entry):
    entry["bought"] = true
    entry["global_reference"]["bought"] = true
    entry["button"].text = "-- SOLD OUT --"; entry["button"].disabled = true
    GameManager.persistent_items_bought_this_turn += 1
    if GameManager.persistent_items_bought_this_turn >= 3:
        GameManager.persistent_reroll_cost = 0
        update_reroll_text()

# ---------------------------------
# UI HELPERS
# ---------------------------------
func create_reroll_button():
    var screen_size = get_viewport_rect().size
    reroll_button = Button.new()
    update_reroll_text()
    reroll_button.custom_minimum_size = Vector2(screen_size.x * shop_item_width_ratio, screen_size.y * shop_item_height_ratio)
    reroll_button.add_theme_font_size_override("font_size", int(screen_size.y * shop_button_font_ratio))
    reroll_button.pressed.connect(reroll_shop)
    utility_button_container.add_child(reroll_button)

func create_button(text, callback):
    var screen_size = get_viewport_rect().size
    var button = Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(screen_size.x * shop_item_width_ratio, screen_size.y * shop_item_height_ratio)
    button.add_theme_font_size_override("font_size", int(screen_size.y * shop_button_font_ratio))
    button.pressed.connect(callback)
    utility_button_container.add_child(button)

func update_reroll_text():
    if reroll_button:
        if GameManager.persistent_reroll_cost == 0: reroll_button.text = "Reroll\n(FREE!)"
        else: reroll_button.text = "Reroll Shop\n(" + str(GameManager.persistent_reroll_cost) + " Gold)"

func update_upgrade_colors():
    for entry in upgrade_buttons:
        var button = entry["button"]
        var upgrade = entry["upgrade"]
        if entry["bought"]: continue
        button.modulate = Color(1, 0.4, 0.4) if GameManager.gold < upgrade["cost"] else Color(1, 1, 1) 
    if reroll_button:
        reroll_button.modulate = Color(1, 0.4, 0.4) if GameManager.gold < GameManager.persistent_reroll_cost else Color(1, 1, 1)

func reroll_shop():
    if GameManager.gold < GameManager.persistent_reroll_cost: return
    GameManager.gold -= GameManager.persistent_reroll_cost
    generate_fresh_shop_pool()
    draw_shop_from_persistent_memory()
    update_gold()
    update_reroll_text()

func setup_six_slots_ui():
    for child in slot_button_container.get_children(): child.queue_free()
    for i in range(6):
        var slot_btn = DropSlotButton.new(i, self)
        var screen_size = get_viewport_rect().size
        slot_btn.custom_minimum_size = Vector2(screen_size.x * slot_button_width_ratio, screen_size.y * slot_button_height_ratio)
        slot_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        slot_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        update_slot_display_text(slot_btn, i)
        slot_button_container.add_child(slot_btn)

func update_slot_display_text(btn: Button, index: int):
    var base_font_size = int(get_viewport_rect().size.y * slot_button_font_ratio)
    var weapon_data = GameManager.equipped_weapons[index]
    if weapon_data != null and typeof(weapon_data) == TYPE_DICTIONARY:
        btn.text = "Slot " + str(index + 1) + "\n" + str(weapon_data["name"]) + "\nLvl: " + str(weapon_data.get("level", 1))
    else: btn.text = "Slot " + str(index + 1) + "\n(Empty)"
    btn.add_theme_font_size_override("font_size", base_font_size)

func update_gold():
    gold_label.text = "Gold: " + str(GameManager.gold)
    update_upgrade_colors()

func setup_gold_ui():
    var screen_size = get_viewport_rect().size
    gold_label.position = Vector2(screen_size.x * gold_label_x_ratio, screen_size.y * gold_label_y_ratio)
    gold_label.add_theme_font_size_override("font_size", int(screen_size.y * gold_label_font_ratio))
    add_child(gold_label)

func _play():
    GameManager.enemy_hp = 100 + (GameManager.selected_difficulty * 20)
    get_tree().change_scene_to_file("res://Scenes/map.tscn")

# ---------------------------------
# CLASSES
# ---------------------------------
class DragShopButton extends Button:
    var upgrade_data: Dictionary
    var shop_main: Node
    var entry_reference: Dictionary
    func _init(data, main_scene): upgrade_data = data; shop_main = main_scene
    func _get_drag_data(_at_position):
        var cat = upgrade_data.get("category", "")
        # Filtered to block viewer dragging
        if cat == "passive" or cat == "viewer" or entry_reference["bought"] or GameManager.gold < upgrade_data["cost"]: return null
        var preview = TextureRect.new()
        preview.texture = load(upgrade_data.get("icon", "res://icon.svg"))
        preview.custom_minimum_size = Vector2(80, 80); set_drag_preview(preview)
        return {"upgrade": upgrade_data, "entry": entry_reference}

class DropSlotButton extends Button:
    var slot_index: int
    var shop_main: Node
    func _init(idx, main_scene): slot_index = idx; shop_main = main_scene
    func _can_drop_data(_pos, data) -> bool:
        if typeof(data) != TYPE_DICTIONARY: return false
        var upgrade = data["upgrade"]
        var cat = upgrade.get("category", "")
        if cat == "weapon": return true
        if cat == "weapon_mod":
            var existing = GameManager.equipped_weapons[slot_index]
            return existing != null and existing.get("name") == upgrade.get("target_weapon")
        return false
    func _drop_data(_pos, data): shop_main.handle_drag_drop_purchase(data["upgrade"], slot_index, data["entry"])
