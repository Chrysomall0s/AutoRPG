extends Control
var outline_shader = preload("res://Assets/shaders/outline_shader.gdshader")

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

#var stats_container: VBoxContainer
#var stats_label: Label
#var current_page_index: int = 0
#var stat_pages = []
var leave_button: Button
#@export_group("Statsbook Layout")
#@export var statsbook_x_ratio: float = 0.65
#@export var statsbook_y_ratio: float = 0.15
#@export var statsbook_font_ratio: float = 0.02

var stats_page_instance: Node
#
#func build_stat_pages():
    ## 1. Standard Stats Grouping
    #var groups = {}
    #var stats = GameManager.player_profile.get("stats", {})
    #for key in stats.keys():
        #var def = GameManager.stat_registry.get(key, null)
        #if def == null: continue
        #var group_name = def["group"]
        #if not groups.has(group_name): groups[group_name] = []
        #groups[group_name].append(key)
    #
    #stat_pages.clear()
    #
    #for group_name in groups.keys():
        #stat_pages.append({
            #"title": group_name,
            #"stats": groups[group_name]
        #})
#
    ## 2. Add Weapons Page
    #var passives = GameManager.player_profile.get("passives", [])
    #var passive_list = []
    #for p in passives:
        ## Assuming passives are dictionaries with 'name' and 'level'
        #var p_name = p.get("name", "Unknown")
        #var p_lvl = p.get("level", 1)
        #passive_list.append(p_name + " (Lv." + str(p_lvl) + ")")
    #
    #stat_pages.append({
        #"title": "Passive Items",
        #"items": passive_list
    #})
#
   ## 4. Add Audience Page (Sorted and Counted)
    #var audience = GameManager.player_profile.get("audience", [])
    #var audience_counts = {}
    #for member in audience:
        #var a_name = (member.get("name", "Unknown") if typeof(member) == TYPE_DICTIONARY else str(member))
        #audience_counts[a_name] = audience_counts.get(a_name, 0) + 1
        #
    #var sorted_audience = audience_counts.keys()
    #sorted_audience.sort()
    #
    #var audience_list = []
    #for name in sorted_audience:
        #audience_list.append(str(audience_counts[name]) + " " + name)
        #
    #stat_pages.append({"title": "Audience", "items": audience_list})

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
    setup_statsbook_ui()

    #update_stats_display()
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
    #setup_statsbook_ui()
    refresh_character_and_weapons()
    
    await get_tree().process_frame
    adjust_layout_containers()

#func setup_statsbook_ui():
    #var screen_size = get_viewport_rect().size
    #
    #stats_container = VBoxContainer.new()
    #stats_container.position = Vector2(screen_size.x * statsbook_x_ratio, screen_size.y * statsbook_y_ratio)
    #
    ## Optional: Set a fixed width so the container doesn't collapse
    #stats_container.custom_minimum_size = Vector2(screen_size.x * 0.2, screen_size.y * 0.4)
    #
    ## 1. Stats Label (or the new container of rows)
    #stats_label = Label.new()
    #stats_label.name = "StatsLabel"
    #stats_label.add_theme_font_size_override("font_size", int(screen_size.y * statsbook_font_ratio))
    #stats_container.add_child(stats_label)
    #
    ## 2. Flip Button (Always added last to be at the bottom)
    #var flip_button = Button.new()
    #flip_button.name = "FlipButton" # Named for easy identification
    #flip_button.text = "Flip Page"
    #flip_button.add_theme_font_size_override("font_size", int(screen_size.y * statsbook_font_ratio))
    #flip_button.pressed.connect(flip_stats_page)
    #stats_container.add_child(flip_button)
    #
    #add_child(stats_container)
    #update_stats_display()
#func update_stats_display():
    #if not is_instance_valid(stats_container): return
    #
    ## 1. Clear existing rows (keep the header/flip button if they are in there)
    ## Assuming stats_label was the only child, or you want to clear specific generated nodes
    #for child in stats_container.get_children():
        #if child.name != "FlipButton" and child.name != "Header": # Add logic to protect header/buttons
            #child.queue_free()
#
    #var page = stat_pages[current_page_index]
    #
    ## Add Title/Header
    #var title = Label.new()
    #title.name = "Header"
    #title.text = page["title"]
    #stats_container.add_child(title)
#
    ## 2. Render content
    #if page.has("stats"):
        #var stats = GameManager.player_profile.get("stats", {})
        #for stat_key in page["stats"]:
            #var value = stats.get(stat_key, 0)
            #var def = GameManager.stat_registry.get(stat_key, {})
            #var display_name = def.get("name", stat_key)
            #
            ## Use the helper to create the row
            #var icon_path = def.get("iconatlas", "")
            #var icon_idx = def.get("iconindex", 0)
            #create_stat_row(display_name + ": " + str(value), icon_path, icon_idx)
            #
    #elif page.has("items"):
        #for item in page["items"]:
            #create_stat_row(str(item), "", 0) # Items might not have icons
#
#func create_stat_row(text: String, icon_path: String, icon_idx: int):
    #var row = HBoxContainer.new()
    #var screen_size = get_viewport_rect().size
    #var font_size = int(screen_size.y * statsbook_font_ratio)
    #
    ## Icon
    #if icon_path != "":
        #var tex_rect = TextureRect.new()
        #tex_rect.custom_minimum_size = Vector2(font_size, font_size)
        #tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        #tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        #
        #var atlas = AtlasTexture.new()
        #atlas.atlas = load(icon_path)
        ## Adjust these values based on your atlas grid size (e.g., 250)
        #atlas.region = Rect2(Vector2((icon_idx % 4) * 250, (icon_idx / 4) * 250), Vector2(250, 250))
        #tex_rect.texture = atlas
        #row.add_child(tex_rect)
        #
    ## Text
    #var label = Label.new()
    #label.text = text
    #label.add_theme_font_size_override("font_size", font_size)
    #row.add_child(label)
    #
    #stats_container.add_child(row)
#
#func flip_stats_page():
    #current_page_index = (current_page_index + 1) % stat_pages.size()
    #update_stats_display()

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
    #if is_instance_valid(stats_container):
        #stats_container.position = Vector2(screen_size.x * statsbook_x_ratio, screen_size.y * statsbook_y_ratio)

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
    # 1. Clear existing buttons
    for entry in upgrade_buttons:
        if is_instance_valid(entry["button"]):
            entry["button"].queue_free()
    upgrade_buttons.clear()
    
    # 2. Re-create buttons from the updated GameManager.shop_items
    for i in range(GameManager.shop_items.size()):
        create_upgrade_button(GameManager.shop_items[i], i)
    
    # 3. Force a UI update to colors/states
    update_upgrade_colors()

func create_upgrade_button(global_entry: Dictionary, position_index: int):
    var upgrade = global_entry["upgrade"]
    var cat = upgrade.get("category")
    var screen_size = get_viewport_rect().size
    
    # 1. Initialize the button
    var button = DragShopButton.new(self, upgrade, true, {})
    button.custom_minimum_size = Vector2(screen_size.x * shop_item_width_ratio, screen_size.y * shop_item_height_ratio)
    
    # 2. Build the UI
    var hbox = HBoxContainer.new()
    hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    hbox.add_theme_constant_override("separation", 10)
    hbox.add_theme_constant_override("margin_left", 10)
    hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    button.add_child(hbox)
    
    var tex_rect = TextureRect.new()
    var icon_dim = screen_size.y * shop_item_height_ratio * 0.7
    tex_rect.custom_minimum_size = Vector2(icon_dim, icon_dim)
    tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    
    # FIX: ONLY set texture if not bought
    if not global_entry["bought"] and upgrade.has("icon"):
        var atlas = AtlasTexture.new()
        atlas.atlas = load(upgrade["icon"])
        var idx = upgrade.get("index", 0)
        atlas.region = Rect2(Vector2((idx % 4) * 250, (idx / 4) * 250), Vector2(250, 250))
        tex_rect.texture = atlas
        
        var mat = ShaderMaterial.new()
        mat.shader = outline_shader
        mat.set_shader_parameter("level", float(upgrade.get("level", 1.0)))
        tex_rect.material = mat
    else:
        tex_rect.texture = null
    
    hbox.add_child(tex_rect)
    
    # 3. Create Label
    var label = Label.new()
    if !global_entry["bought"]:
        var action_hint = "\n[Drag to Slot]" if cat == "weapon" else "\n[Tap to Buy]"
        if cat == "weapon_mod": action_hint = "\n[Drag to Mod]"
        label.text = upgrade["name"] + " (" + str(upgrade["cost"]) + "G)" + action_hint
    
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", int(screen_size.y * shop_button_font_ratio))
    hbox.add_child(label)
    
    # 4. Inject entry and store
    var entry = {
        "button": button, 
        "global_reference": global_entry, 
        "upgrade": upgrade, 
        "bought": global_entry["bought"]
    }
    button.entry_reference = entry
    upgrade_buttons.append(entry)
    main_button_container.add_child(button)

    # 5. Connect signals
    button.disabled = global_entry["bought"]
    if not global_entry["bought"]:
        button.pressed.connect(func(): 
            if cat == "passive": 
                handle_passive_purchase(entry)
            elif cat == "viewer":
                handle_audience_purchase(entry)
        )
        
#func refresh_stats():
    #build_stat_pages()
    #if is_instance_valid(stats_label):
        #update_stats_display()

func handle_audience_purchase(entry_ref: Dictionary):
    var upgrade_data = entry_ref["upgrade"]
    if entry_ref["bought"]: return

    # Ensure the audience list exists
    if not "audience" in GameManager.player_profile:
        GameManager.player_profile["audience"] = []

    # Add directly to audience array
    GameManager.player_profile["audience"].append(upgrade_data)

    # Finalize UI
    finalize_item_purchase(entry_ref)
    update_gold()
    #refresh_stats()

func handle_passive_purchase(entry_ref: Dictionary):
    var upgrade_data = entry_ref["upgrade"]
    if entry_ref["bought"]: return


    if upgrade_data.get("category") == "viewer":
        handle_audience_purchase(entry_ref)
        return
    # Ensure the passives list exists
    if not "passives" in GameManager.player_profile:
        GameManager.player_profile["passives"] = []

    var player_passives = GameManager.player_profile["passives"]
    var found = false

    # Check if we already own this passive by name
    for p in player_passives:
        if p["name"] == upgrade_data["name"]:
            # Increment only the level
            p["level"] += 1
            found = true
            break
    
    # If not found, add it to our inventory as a new entry
    if not found:
        var new_passive = upgrade_data.duplicate()
        new_passive["level"] = 1
        player_passives.append(new_passive)

    # Finalize UI
    finalize_item_purchase(entry_ref)
    update_gold()
    refresh_stats()
    
    player_sprite.load_upgrade_sprites(GameManager.player_profile)

func setup_statsbook_ui():
    var stats_scene = preload("res://Scenes/StatPage.tscn")
    stats_page_instance = stats_scene.instantiate()
    stats_page_instance.position = Vector2(get_viewport_rect().size.x * 0.65, get_viewport_rect().size.y * 0.15)
    add_child(stats_page_instance)

# Update your purchase functions to call the new instance's method
func refresh_stats():
    if is_instance_valid(stats_page_instance):
        stats_page_instance.refresh_stats()

func handle_drag_drop_purchase(upgrade_data: Dictionary, target_slot_index: int, entry_ref: Dictionary):
    var weapons = GameManager.player_profile.get("weapons", [])
    var existing_weapon = weapons[target_slot_index] if target_slot_index < weapons.size() else null
    var category = upgrade_data.get("category", "")
    
    if category == "weapon":
        if get_gold() < upgrade_data["cost"]: return
        
        # FIX: Check if the weapon is the same as the one already equipped
        if existing_weapon != null and existing_weapon.get("name") == upgrade_data.get("name"):
            # LEVEL UP: Increase level, don't swap
            existing_weapon["level"] = existing_weapon.get("level") + upgrade_data.get("level")
            # Still need to "buy" it (remove from shop)
            finalize_item_purchase(entry_ref)
            
        # CASE: Different weapon or empty slot - Perform Swap or Equip
        else:
            if existing_weapon != null:
                # Place old weapon back into the shop's data reference
                entry_ref["global_reference"]["upgrade"] = existing_weapon
                entry_ref["global_reference"]["bought"] = false
            else:
                # Normal empty slot purchase
                finalize_item_purchase(entry_ref)
                
            # Place new weapon into the slot
            GameManager.player_profile["weapons"][target_slot_index] = upgrade_data.duplicate(true)
        
        spend_gold(upgrade_data["cost"])
        
    elif category == "weapon_mod":
        # Keep your existing logic for mods
        if existing_weapon and existing_weapon.get("name") == upgrade_data.get("target_weapon"):
            if get_gold() < upgrade_data["cost"]: return
            spend_gold(upgrade_data["cost"])
            ShopSystem.use_upgrade_on_weapon(upgrade_data, target_slot_index)
            finalize_item_purchase(entry_ref)
        else:
            return

    # Refresh everything
    draw_shop_from_persistent_memory()
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
        var slot_btn = DragShopButton.new(self, {"index": i}, false)
        slot_btn.custom_minimum_size = Vector2(screen_size.x * slot_button_width_ratio, screen_size.y * slot_button_height_ratio)
        
        var hbox = HBoxContainer.new()
        hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
        hbox.add_theme_constant_override("separation", 10)
        hbox.add_theme_constant_override("margin_left", 10)
        hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
        slot_btn.add_child(hbox)
        
        var tex_rect = TextureRect.new()
        var icon_dim = screen_size.y * slot_button_height_ratio * 0.7
        tex_rect.custom_minimum_size = Vector2(icon_dim, icon_dim)
        tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        hbox.add_child(tex_rect)
        
        var label = Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_OFF
        label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        label.add_theme_font_size_override("font_size", int(screen_size.y * slot_button_font_ratio))
        hbox.add_child(label)
        
        var weapon_data = weapons[i] if i < weapons.size() else null

        if typeof(weapon_data) == TYPE_DICTIONARY and weapon_data.has("icon"):
            var atlas = AtlasTexture.new()
            var path = weapon_data.get("icon", "res://icon.svg")
            atlas.atlas = load(path)
            var idx = weapon_data.get("index", 0)
            atlas.region = Rect2(Vector2((idx % 4) * 250, (idx / 4) * 250), Vector2(250, 250))
            tex_rect.texture = atlas
            # --- APPLY SHADER ---
            var mat = ShaderMaterial.new()
            mat.shader = outline_shader
            # Use the weapon's level
            mat.set_shader_parameter("level", float(weapon_data.get("level", 1.0)))
            tex_rect.material = mat
            # --------------------
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
        label_node.text =   str(w_name)
    else: 
        label_node.text =  "(Empty)"
        
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
    var diff_key = GameManager.get_difficulty_key() # or logic to choose "easy", "normal", etc.
    
    # Returns an Array: [monster1_dict, monster2_dict, monster3_dict]
    GameManager.current_enemy_profile = MonsterData.get_monster(diff_key, GameManager.currentRound)
    GameManager.currentRound += 1
    
    # Store the entire wave in the manager
    get_tree().change_scene_to_file("res://Scenes/Battle.tscn")
# ---------------------------------
# CLASSES
# ---------------------------------
class DragShopButton extends Button:
    var shop_main: Node
    var data: Dictionary # Holds either upgrade info OR weapon index/info
    var is_shop_item: bool = false
    var entry_reference: Dictionary # Only used if is_shop_item is true
    
    var outline_shader = preload("res://Assets/shaders/outline_shader.gdshader")

    func _init(main_scene: Node, item_data: Dictionary, is_shop: bool, entry_ref: Dictionary = {}):
        shop_main = main_scene
        data = item_data
        is_shop_item = is_shop
        entry_reference = entry_ref

    func _get_drag_data(_at_position):
        # 1. Logic for Shop Items (Dragging OUT of shop)
        if is_shop_item:
            var cat = data.get("category", "")
            if cat == "passive" or cat == "viewer" or entry_reference["bought"] or shop_main.get_gold() < data["cost"]:
                return null
            return {"type": "purchase", "upgrade": data, "entry": entry_reference}

        # 2. Logic for Inventory Slots (Rearranging/Dragging OUT of slots)
        var weapons = GameManager.player_profile.get("weapons", [])
        var idx = data.get("index")
        if idx == null or idx >= weapons.size() or weapons[idx] == null:
            return null
        return {"type": "rearrange", "from_index": idx}

    func _can_drop_data(_pos, drop_data) -> bool:
        if drop_data.get("type") == "rearrange" and is_shop_item:
        # Check if this shop slot is currently "Empty" (meaning it's already bought)
        # entry_reference["bought"] is true if the item was bought/sold out
            return true
        
        # 1. Get the weapons list safely
        var weapons = GameManager.player_profile.get("weapons", [])
        var target_idx = data.get("index")
        
        # Ensure the target index is actually within the bounds of the array
        if target_idx == null or target_idx >= weapons.size():
            return false

        # 2. Get the existing weapon, allowing for it to be null (empty slot)
        var existing = weapons[target_idx]

        # 3. Determine what is being held
        if drop_data.get("type") == "purchase":
            var upgrade = drop_data["upgrade"]
            
            # Now we can safely check categories without crashing on null
            var is_weapon = upgrade.get("category") == "weapon"
            var is_mod = upgrade.get("category") == "weapon_mod"
            
            # Only allow mods if there is an existing weapon (and it's not null)
            if is_mod:
                return existing != null
            
            return is_weapon
            
        if drop_data.get("type") == "rearrange":
            return true 
            
        return false

    func _drop_data(_pos, drop_data):
        if drop_data.get("type") == "rearrange" and is_shop_item:
        # We need to know if we are selling (to empty) or swapping (to occupied)
            if entry_reference["bought"]:
                shop_main.sell_weapon(drop_data["from_index"], entry_reference)
            elif entry_reference["upgrade"].get("category") == "weapon":
                shop_main.swap_weapon_with_shop(drop_data["from_index"], entry_reference)
        elif drop_data.get("type") == "purchase":
            shop_main.handle_drag_drop_purchase(drop_data["upgrade"], data["index"], drop_data["entry"])
        elif drop_data.get("type") == "rearrange":
            shop_main.handle_rearrange_weapons(drop_data["from_index"], data["index"])


# Replace your existing sell_weapon with this version
func sell_weapon(slot_index: int, shop_entry: Dictionary):
    var weapons = GameManager.player_profile.get("weapons", [])
    if slot_index < 0 or slot_index >= weapons.size():
        return
        
    var weapon_to_sell = weapons[slot_index]
    if weapon_to_sell == null:
        return
        
    # 1. Give money back
    var refund = int(weapon_to_sell.get("cost", 0) * 0.5)
    add_gold(refund)
    
    # 2. Move weapon back to shop slot
    shop_entry["global_reference"]["upgrade"] = weapon_to_sell
    shop_entry["global_reference"]["bought"] = false 
    
    # 3. Clear inventory
    GameManager.player_profile["weapons"][slot_index] = null
    
    # 4. Refresh
    draw_shop_from_persistent_memory()
    update_gold()
    setup_six_slots_ui() 
    refresh_character_and_weapons()

# ADD THIS FUNCTION to Store.gd to handle the swap
func swap_weapon_with_shop(inventory_index: int, shop_entry: Dictionary):
    var weapons = GameManager.player_profile.get("weapons", [])
    var inventory_weapon = weapons[inventory_index]
    var shop_weapon = shop_entry["global_reference"]["upgrade"]
    
    # 1. Put shop weapon into inventory
    GameManager.player_profile["weapons"][inventory_index] = shop_weapon
    
    # 2. Put inventory weapon into shop slot
    shop_entry["global_reference"]["upgrade"] = inventory_weapon
    shop_entry["global_reference"]["bought"] = false
    
    # 3. Refresh
    draw_shop_from_persistent_memory()
    setup_six_slots_ui()
    refresh_character_and_weapons()
        
func process_weapon_interaction(source_item: Dictionary, target_slot_index: int):
    var weapons = GameManager.player_profile.get("weapons", [])
    var target_weapon = weapons[target_slot_index] if target_slot_index < weapons.size() else null
    
    # CASE: Same Type -> LEVEL UP
    if target_weapon != null and target_weapon.get("name") == source_item.get("name"):
        target_weapon["level"] = target_weapon.get("level") + source_item.get("level")
        print("Leveled up: " + target_weapon["name"])
        return true # Interaction successful
        
    # CASE: Replace/Swap
    else:
        # If we have a target, we move it to where the source came from (if applicable)
        # This implementation simplifies to: Swap current target with source
        weapons[target_slot_index] = source_item
        # Note: If dragging from shop, you handle source removal elsewhere
        return false

# Place this in your main Store.gd script, NOT inside the classes
func handle_rearrange_weapons(from_index: int, to_index: int):
    var weapons = GameManager.player_profile.get("weapons", [])
    
    # 1. Validate indices
    if from_index < 0 or from_index >= weapons.size() or \
       to_index < 0 or to_index >= weapons.size():
        return
        
    var source_weapon = weapons[from_index]
    var target_weapon = weapons[to_index]

    # 2. Logic: Level up if same, Swap if different
    if source_weapon != null and target_weapon != null and source_weapon.get("name") == target_weapon.get("name"):
        # Same weapon: Level up the target, nullify the source
        target_weapon["level"] = target_weapon.get("level") + source_weapon.get("level")
        weapons[from_index] = null
        print("Leveled up: " + target_weapon["name"])
        
    else:
        # Different (or one is empty): Perform a standard swap
        var temp = weapons[from_index]
        weapons[from_index] = weapons[to_index]
        weapons[to_index] = temp
    
    # 3. Update the UI
    setup_six_slots_ui()
    refresh_character_and_weapons()
