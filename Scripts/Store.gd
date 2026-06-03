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
var stat_pages = []
var leave_button: Button
@export_group("Statsbook Layout")
@export var statsbook_x_ratio: float = 0.65
@export var statsbook_y_ratio: float = 0.15
@export var statsbook_font_ratio: float = 0.02

func build_stat_pages():
    var groups = {}
    var stats = GameManager.player_profile.get("stats", {})
    
    for key in stats.keys():
        var def = GameManager.stat_registry.get(key, null)
        if def == null:
            continue
        
        var group_name = def["group"]
        
        if not groups.has(group_name):
            groups[group_name] = []
        
        groups[group_name].append(key)
    
    stat_pages.clear()
    
    for group_name in groups.keys():
        stat_pages.append({
            "title": group_name,
            "stats": groups[group_name]
        })

func create_leave_button():
    var screen_size = get_viewport_rect().size
    
    leave_button = Button.new()
    leave_button.text = "Leave"
    leave_button.pressed.connect(_play)

    leave_button.custom_minimum_size = Vector2(
        screen_size.x * shop_item_width_ratio,
        screen_size.y * shop_item_height_ratio
    )

    leave_button.add_theme_font_size_override(
        "font_size",
        int(screen_size.y * shop_button_font_ratio)
    )

    add_child(leave_button)

    # IMPORTANT: wait 1 frame so size is valid
    await get_tree().process_frame

    # Center it at top
    leave_button.position = Vector2(
        (screen_size.x - leave_button.size.x) * 0.5,
        screen_size.y * 0.02
    )
    
func get_gold() -> int:
    return GameManager.player_profile["stats"]["gold"]

func spend_gold(amount: int) -> bool:
    if GameManager.player_profile["stats"]["gold"] < amount:
        return false
    GameManager.player_profile["stats"]["gold"] -= amount
    return true

func add_gold(amount: int) -> void:
    GameManager.player_profile["stats"]["gold"] += amount

func _ready():
    randomize()
    setup_gold_ui()
    build_stat_pages()
    update_stats_display()
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
    create_leave_button()
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
    var stats = GameManager.player_profile.get("stats", {})
    
    var text = page["title"] + "\n----------------\n"
    
    for stat_key in page["stats"]:
        var value = stats.get(stat_key, 0)
        var def = GameManager.stat_registry.get(stat_key, {})
        
        var display_name = def.get("name", stat_key)
        
        text += display_name + ": " + str(value) + "\n"
    
    stats_label.text = text

func flip_stats_page():
    current_page_index = (current_page_index + 1) % stat_pages.size()
    update_stats_display()

func _process(delta: float) -> void:
    # 3. Delegate the movement calculations to the Hero node
    if is_instance_valid(player_sprite) and player_sprite.has_method("update_weapon_movements"):
        player_sprite.update_weapon_movements(delta, player_sprite.position)

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
    # 1. Refresh the UI slots so the text matches the new weapon data
    setup_six_slots_ui()
    player_sprite.refresh_character_and_weapons(GameManager.player_profile)

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
    GameManager.persistent_reroll_cost = base_reroll_cost
    GameManager.shop_items.clear()
    var raw_upgrades = get_random_upgrades(3)
    for upgrade in raw_upgrades:
        GameManager.shop_items.append({"upgrade": upgrade, "bought": false})

func draw_shop_from_persistent_memory():
    for entry in upgrade_buttons:
        if is_instance_valid(entry["button"]): entry["button"].queue_free()
    upgrade_buttons.clear()
    for i in range(GameManager.shop_items.size()):
        create_upgrade_button(GameManager.shop_items[i], i)
    update_upgrade_colors()

func create_upgrade_button(global_entry: Dictionary, position_index: int):
    var upgrade = global_entry["upgrade"]
    var cat = upgrade.get("category")
    var screen_size = get_viewport_rect().size
    
    var button = DragShopButton.new(upgrade, self)
    button.custom_minimum_size = Vector2(screen_size.x * shop_item_width_ratio, screen_size.y * shop_item_height_ratio)
    
    var hbox = HBoxContainer.new()
    hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    hbox.add_theme_constant_override("separation", 15)
    hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    button.add_child(hbox)
    
    # Larger Icon (occupies 80% of button height)
    var tex_rect = TextureRect.new()
    var icon_dim = screen_size.y * shop_item_height_ratio * 0.8
    tex_rect.custom_minimum_size = Vector2(icon_dim, icon_dim)
    tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    
    if upgrade.has("icon"):
        var atlas = AtlasTexture.new()
        atlas.atlas = load(upgrade["icon"])
        var idx = upgrade.get("index", 0)
        atlas.region = Rect2(Vector2((idx % 4) * 250, (idx / 4) * 250), Vector2(250, 250))
        tex_rect.texture = atlas
    hbox.add_child(tex_rect)
    
    # Larger Text
    var label = Label.new()
    var action_hint = "\n[Drag to Slot]" if cat == "weapon" else "\n[Tap to Buy]"
    if cat == "weapon_mod": action_hint = "\n[Drag to Mod]"
    label.text = upgrade["name"] + " (" + str(upgrade["cost"]) + "G)" + action_hint
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", int(screen_size.y * shop_button_font_ratio))
    hbox.add_child(label)
    
    var entry = {"button": button, "global_reference": global_entry, "upgrade": upgrade, "bought": global_entry["bought"]}
    button.entry_reference = entry
    upgrade_buttons.append(entry)
    main_button_container.add_child(button)

    if global_entry["bought"]:
        button.text = "-- SOLD OUT --"; button.disabled = true
    else:
        button.pressed.connect(func(): if cat == "passive" or cat == "viewer": handle_passive_purchase(entry))

func refresh_stats():
    build_stat_pages()
    if is_instance_valid(stats_label):
        update_stats_display()

func handle_passive_purchase(entry_ref: Dictionary):
    var upgrade_data = entry_ref["upgrade"]

    if entry_ref["bought"]:
        return

    var success = ShopSystem.buy_passive_upgrade(upgrade_data)
    if not success:
        return

    finalize_item_purchase(entry_ref)
    update_gold()
    refresh_character_and_weapons()
    refresh_stats()

func handle_drag_drop_purchase(upgrade_data: Dictionary, target_slot_index: int, entry_ref: Dictionary):

    var weapons = GameManager.player_profile.get("weapons", [])

    if target_slot_index >= weapons.size():
        return

    if get_gold() < upgrade_data["cost"]:
        return

    var category = upgrade_data.get("category", "")

    if category == "weapon":
        spend_gold(upgrade_data["cost"])
        ShopSystem.equip_weapon(upgrade_data, target_slot_index)

    elif category == "weapon_mod":
        var existing = weapons[target_slot_index]
        if existing and existing.get("name") == upgrade_data.get("target_weapon"):
            spend_gold(upgrade_data["cost"])
            ShopSystem.use_upgrade_on_weapon(upgrade_data, target_slot_index)
        else:
            return

    finalize_item_purchase(entry_ref)
    update_gold()
    setup_six_slots_ui()
    refresh_character_and_weapons()

func finalize_item_purchase(entry):
    entry["bought"] = true
    entry["global_reference"]["bought"] = true
    
    var btn = entry["button"]
    btn.disabled = true
    
    # Access the HBoxContainer (first child of the button)
    var hbox = btn.get_child(0)
    if hbox and hbox is HBoxContainer:
        # Clear the Icon (first child of HBox)
        var tex_rect = hbox.get_child(0)
        if tex_rect and tex_rect is TextureRect:
            tex_rect.texture = null
            
        # Clear the Text (second child of HBox)
        var label = hbox.get_child(1)
        if label and label is Label:
            label.text = "" 
            
    # Optional: If you want the "SOLD OUT" text to remain, 
    # but remove the weapon info text, you could set btn.text = "-- SOLD OUT --"
    # instead of clearing the label.
    
    if GameManager.shop_items[0]["bought"] and \
       GameManager.shop_items[1]["bought"] and \
       GameManager.shop_items[2]["bought"]:
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
        button.modulate = Color(1, 0.4, 0.4) if get_gold() < upgrade["cost"] else Color(1, 1, 1) 
    if reroll_button:
        reroll_button.modulate = Color(1, 0.4, 0.4) if get_gold() < GameManager.persistent_reroll_cost else Color(1, 1, 1)

func reroll_shop():
    ShopSystem.reroll()
    draw_shop_from_persistent_memory()
    update_gold()
    update_reroll_text()

func setup_six_slots_ui():
    for child in slot_button_container.get_children(): child.queue_free()
    
    var weapons = GameManager.player_profile.get("weapons", [])
    var screen_size = get_viewport_rect().size
    
    for i in range(6):
        var slot_btn = DropSlotButton.new(i, self)
        slot_btn.custom_minimum_size = Vector2(screen_size.x * slot_button_width_ratio, screen_size.y * slot_button_height_ratio)
        
        var hbox = HBoxContainer.new()
        hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
        hbox.add_theme_constant_override("separation", 15)
        hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
        slot_btn.add_child(hbox)
        
        # Icon setup
        var tex_rect = TextureRect.new()
        var icon_dim = screen_size.y * slot_button_height_ratio * 0.8
        tex_rect.custom_minimum_size = Vector2(icon_dim, icon_dim)
        tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        hbox.add_child(tex_rect)
        
        # Label setup
        var label = Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.add_theme_font_size_override("font_size", int(screen_size.y * slot_button_font_ratio))
        hbox.add_child(label)
        
        var weapon_data = weapons[i] if i < weapons.size() else null

        if typeof(weapon_data) == TYPE_DICTIONARY and weapon_data.has("icon"):
            var atlas = AtlasTexture.new()
        # Ensure the path exists or use a fallback
            var path = weapon_data.get("icon", "res://icon.svg")
            atlas.atlas = load(path)
            var idx = weapon_data.get("index", 0)
            atlas.region = Rect2(Vector2((idx % 4) * 250, (idx / 4) * 250), Vector2(250, 250))
            tex_rect.texture = atlas
        else:
            tex_rect.texture = null
    
        update_slot_display_text(label, i)
        slot_button_container.add_child(slot_btn)
        
func update_slot_display_text(label_node: Label, index: int):
    var weapons_list = GameManager.player_profile.get("weapons", [])
    
    var w_name = "(Empty)"
    var w_lvl = 1
    
    if index < weapons_list.size() and weapons_list[index] != null:
        var weapon_data = weapons_list[index]
        if typeof(weapon_data) == TYPE_DICTIONARY:
            w_name = weapon_data.get("name", "Unknown")
            w_lvl = weapon_data.get("level", 1)
        elif typeof(weapon_data) == TYPE_STRING:
            w_name = weapon_data
        label_node.text = "Slot " + str(index + 1) + "\n" + str(w_name) + " (Lvl " + str(w_lvl) + ")"
    else: 
        label_node.text = "Slot " + str(index + 1) + "\n(Empty)"
        
    label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    # Ensure font size is consistently applied
    label_node.add_theme_font_size_override("font_size", int(get_viewport_rect().size.y * slot_button_font_ratio))
    
func update_gold():
    gold_label.text = "Gold: " + str(get_gold())
    update_upgrade_colors()

func setup_gold_ui():
    var screen_size = get_viewport_rect().size
    gold_label.position = Vector2(screen_size.x * gold_label_x_ratio, screen_size.y * gold_label_y_ratio)
    gold_label.add_theme_font_size_override("font_size", int(screen_size.y * gold_label_font_ratio))
    add_child(gold_label)

func _play():
    get_tree().change_scene_to_file("res://Scenes/Battle.tscn")

# ---------------------------------
# CLASSES
# ---------------------------------
class DragShopButton extends Button:
    var upgrade_data: Dictionary
    var shop_main: Node # This holds the reference to your main script
    var entry_reference: Dictionary
    
    func _init(data, main_scene): 
        upgrade_data = data
        shop_main = main_scene
        
    func _get_drag_data(_at_position):
        var cat = upgrade_data.get("category", "")
        # Use shop_main.get_gold() instead of just get_gold()
        if cat == "passive" or cat == "viewer" or entry_reference["bought"] or shop_main.get_gold() < upgrade_data["cost"]: 
            return null
            
        var preview = TextureRect.new()
        preview.texture = load(upgrade_data.get("icon", "res://icon.svg"))
        preview.custom_minimum_size = Vector2(80, 80); set_drag_preview(preview)
        return {"upgrade": upgrade_data, "entry": entry_reference}
        
class DropSlotButton extends Button:
    var slot_index: int
    var shop_main: Node
    
    # Provide default values so .new() can be called without arguments
    func _init(idx: int = -1, main_scene: Node = null):
        slot_index = idx
        shop_main = main_scene
        
    func setup(idx: int, main_scene: Node):
        slot_index = idx
        shop_main = main_scene

    func _can_drop_data(_pos, data) -> bool:
        if typeof(data) != TYPE_DICTIONARY: return false
        var upgrade = data["upgrade"]
        var cat = upgrade.get("category", "")
        if cat == "weapon": return true
        if cat == "weapon_mod":
            var weapons = GameManager.player_profile.get("weapons", [])
            var existing = weapons[slot_index] if slot_index < weapons.size() else null
            return existing != null and existing.get("name") == upgrade.get("target_weapon")
        return false
        
    func _drop_data(_pos, data): 
        shop_main.handle_drag_drop_purchase(data["upgrade"], slot_index, data["entry"])
