# =================================================================
# res://Scenes/Shop.gd
# =================================================================
extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS (RESOLUTION DYNAMIC)
# =================================================================
@export_group("Text Typography Scaling")
@export var gold_label_font_ratio: float = 0.028   
@export var shop_button_font_ratio: float = 0.022  
@export var slot_button_font_ratio: float = 0.016  

@export_group("Shop Item UI Layout")
@export var shop_item_width_ratio: float = 0.75   
@export var shop_item_height_ratio: float = 0.095 

@export_group("Slot Selection Layout")
@export var slot_button_width_ratio: float = 0.14  
@export var slot_button_height_ratio: float = 0.09 

@export_group("Persistent UI Offsets")
@export var gold_label_x_ratio: float = 0.04      
@export var gold_label_y_ratio: float = 0.02      
# =================================================================

@onready var gold_label: Label = Label.new()
@onready var main_button_container: VBoxContainer = $ButtonContainer 

var slot_button_container: HBoxContainer 
var upgrade_buttons = []

var base_reroll_cost: int = 10
var current_reroll_cost: int = 10
var reroll_button: Button
var items_bought_this_turn: int = 0

var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

func _ready():
	randomize()
	setup_gold_ui()

	slot_button_container = HBoxContainer.new()
	slot_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_button_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	slot_button_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	slot_button_container.size_flags_horizontal = SizeFlags.SIZE_EXPAND_FILL
	slot_button_container.add_theme_constant_override("separation", 10)
	add_child(slot_button_container)

	current_reroll_cost = base_reroll_cost
	refresh_store_upgrades()

	create_reroll_button()
	create_button("Leave", _play)
	
	update_gold()
	setup_six_slots_ui()
	
	await get_tree().process_frame
	adjust_layout_containers()

func adjust_layout_containers():
	var screen_size = get_viewport_rect().size
	gold_label.position = Vector2(screen_size.x * gold_label_x_ratio, screen_size.y * gold_label_y_ratio)
	slot_button_container.position = Vector2(
		(screen_size.x - slot_button_container.size.x) / 2.0,
		screen_size.y * 0.78
	)

# ---------------------------------
# SHOP CHOICE SELECTION GENERATION
# ---------------------------------
func get_random_upgrades(amount: int) -> Array:
	var pool = UpgradeData.upgrades.duplicate()
	var result = []
	# Remove template items with 0 weight (like Character placeholders)
	var active_pool = []
	for item in pool:
		if item.get("weight", 0) > 0:
			active_pool.append(item)
			
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

# ---------------------------------
# SHOP DRAW INTERFACE
# ---------------------------------
func refresh_store_upgrades():
	items_bought_this_turn = 0
	current_reroll_cost = base_reroll_cost
	update_reroll_text()

	for entry in upgrade_buttons:
		if is_instance_valid(entry["button"]):
			entry["button"].queue_free()
	upgrade_buttons.clear()
	
	var selected_upgrades = get_random_upgrades(3)
	for i in range(selected_upgrades.size()):
		var upgrade = selected_upgrades[i]
		create_upgrade_button(upgrade)
		main_button_container.move_child(upgrade_buttons[i]["button"], i)
		
	update_upgrade_colors()

func create_upgrade_button(upgrade):
	var button = DragShopButton.new(upgrade, self)
	
	# Formulate specific context messaging based on category types
	var action_hint = "\n[Hold & Drag to Slot]"
	if upgrade.get("category") == "passive":
		action_hint = "\n[Tap / Double-Tap to Buy]"
	elif upgrade.get("category") == "weapon_mod":
		action_hint = "\n[Drag to upgrade " + upgrade.get("target_weapon", "") + "]"
		
	button.text = upgrade["name"] + " (" + str(upgrade["cost"]) + " Gold)" + action_hint
	
	var screen_size = get_viewport_rect().size
	button.custom_minimum_size = Vector2(screen_size.x * shop_item_width_ratio, screen_size.y * shop_item_height_ratio)
	button.add_theme_font_size_override("font_size", int(screen_size.y * shop_button_font_ratio))

	var entry = {
		"button": button,
		"upgrade": upgrade,
		"bought": false
	}
	
	button.entry_reference = entry
	upgrade_buttons.append(entry)
	main_button_container.add_child(button)

	# Natively connect pressed signal directly for passive upgrades
	button.pressed.connect(func():
		if upgrade.get("category") == "passive":
			handle_passive_purchase(entry)
	)

func create_reroll_button():
	var screen_size = get_viewport_rect().size
	reroll_button = Button.new()
	update_reroll_text()
	reroll_button.custom_minimum_size = Vector2(screen_size.x * shop_item_width_ratio, screen_size.y * shop_item_height_ratio)
	reroll_button.add_theme_font_size_override("font_size", int(screen_size.y * shop_button_font_ratio))
	reroll_button.pressed.connect(reroll_shop)
	main_button_container.add_child(reroll_button)

func create_button(text, callback):
	var screen_size = get_viewport_rect().size
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(screen_size.x * shop_item_width_ratio, screen_size.y * shop_item_height_ratio)
	button.add_theme_font_size_override("font_size", int(screen_size.y * shop_button_font_ratio))
	button.pressed.connect(callback)
	main_button_container.add_child(button)

func update_reroll_text():
	if reroll_button:
		if current_reroll_cost == 0: reroll_button.text = "Reroll Shop (FREE!)"
		else: reroll_button.text = "Reroll Shop (" + str(current_reroll_cost) + " Gold)"

func update_upgrade_colors():
	for entry in upgrade_buttons:
		var button = entry["button"]
		var upgrade = entry["upgrade"]
		if entry["bought"]: continue
		button.modulate = Color(1, 0.4, 0.4) if GameManager.gold < upgrade["cost"] else Color(1, 1, 1) 
			
	if reroll_button:
		reroll_button.modulate = Color(1, 0.4, 0.4) if GameManager.gold < current_reroll_cost else Color(1, 1, 1)

func reroll_shop():
	if GameManager.gold < current_reroll_cost: return
	GameManager.gold -= current_reroll_cost
	refresh_store_upgrades()
	update_gold()

# ---------------------------------
# 6 MOBILE DRAG & DROP TARGET SLOTS
# ---------------------------------
func setup_six_slots_ui():
	var screen_size = get_viewport_rect().size
	var target_btn_size = Vector2(screen_size.x * slot_button_width_ratio, screen_size.y * slot_button_height_ratio)
	var dynamic_font_size = int(screen_size.y * slot_button_font_ratio)
	
	for child in slot_button_container.get_children():
		child.queue_free()
		
	for i in range(6):
		var slot_btn = DropSlotButton.new(i, self)
		slot_btn.custom_minimum_size = target_btn_size
		slot_btn.add_theme_font_size_override("font_size", dynamic_font_size)
		update_slot_display_text(slot_btn, i)
		slot_button_container.add_child(slot_btn)

func update_slot_display_text(btn: Button, index: int):
	var weapon_data = GameManager.equipped_weapons[index]
	if weapon_data != null and typeof(weapon_data) == TYPE_DICTIONARY and weapon_data.has("name"):
		var lvl = weapon_data.get("level", 1)
		var dmg = weapon_data.get("damage", 10)
		btn.text = "Slot " + str(index + 1) + "\n" + str(weapon_data["name"]) + " (Lvl " + str(lvl) + ")\nDMG: " + str(dmg)
	else:
		btn.text = "Slot " + str(index + 1) + "\n(Empty)"

# ---------------------------------
# CONDITIONAL DROPS & PURCHASES ENGINE
# ---------------------------------
func handle_passive_purchase(entry_ref: Dictionary):
	var upgrade_data = entry_ref["upgrade"]
	if GameManager.gold < upgrade_data["cost"] or entry_ref["bought"]: return
	
	GameManager.gold -= upgrade_data["cost"]
	GameManager.owned_upgrades.append(upgrade_data.duplicate())
	UpgradeSystem.apply_upgrade(upgrade_data, "character")
	
	finalize_item_purchase(entry_ref)
	update_gold()

func handle_drag_drop_purchase(upgrade_data: Dictionary, target_slot_index: int, entry_ref: Dictionary):
	if GameManager.gold < upgrade_data["cost"]:
		print("Not enough gold!")
		return
		
	var category = upgrade_data.get("category", "")
	var existing_weapon = GameManager.equipped_weapons[target_slot_index]
	
	if category == "weapon":
		# Direct placement overwrite transaction
		GameManager.gold -= upgrade_data["cost"]
		GameManager.equipped_weapons[target_slot_index] = upgrade_data.duplicate()
		UpgradeSystem.apply_upgrade(upgrade_data, str(target_slot_index))
		
	elif category == "weapon_mod":
		# Validate that the slot actually contains the correct weapon type
		if existing_weapon == null or typeof(existing_weapon) != TYPE_DICTIONARY:
			print("Cannot apply modifier to an empty slot!")
			return
			
		if existing_weapon.get("name") != upgrade_data.get("target_weapon"):
			print("Weapon mod target mismatch!")
			return
			
		# Execute Level Up Modifications directly on the existing weapon
		GameManager.gold -= upgrade_data["cost"]
		existing_weapon["level"] = existing_weapon.get("level", 1) + 1
		existing_weapon["damage"] = existing_weapon.get("damage", 10) + upgrade_data.get("damage_bonus", 0)
		existing_weapon["speed"] = max(1, existing_weapon.get("speed", 3) + upgrade_data.get("speed_bonus", 0))
		
		print(existing_weapon["name"], " leveled up to Level: ", existing_weapon["level"])
		UpgradeSystem.apply_upgrade(upgrade_data, str(target_slot_index))
		
	finalize_item_purchase(entry_ref)
	update_gold()
	setup_six_slots_ui()

func finalize_item_purchase(entry):
	entry["bought"] = true
	entry["button"].text = "-- SOLD OUT --"
	entry["button"].disabled = true
	entry["button"].modulate = Color(0.4, 0.4, 0.4, 0.6) 
	
	items_bought_this_turn += 1
	if items_bought_this_turn >= 3:
		current_reroll_cost = 0
		update_reroll_text()

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
	get_tree().change_scene_to_file("res://Scenes/Map.tscn")

# =================================================================
# MOBILE SUB-CLASSES WITH VALIDATION FILTER CODES
# =================================================================
class DragShopButton extends Button:
	var upgrade_data: Dictionary
	var shop_main: Node
	var entry_reference: Dictionary
	
	func _init(data: Dictionary, main_scene: Node):
		upgrade_data = data
		shop_main = main_scene
		
	func _get_drag_data(_at_position: Vector2) -> Variant:
		# Block drag loops for passives (bought instantly via touch clicking)
		if upgrade_data.get("category") == "passive": return null
		if entry_reference["bought"] or GameManager.gold < upgrade_data["cost"]: return null
			
		var preview = TextureRect.new()
		preview.texture = load(upgrade_data.get("icon", "res://icon.svg"))
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.custom_minimum_size = Vector2(80, 80)
		preview.modulate = Color(1, 1, 1, 0.7)
		
		set_drag_preview(preview)
		return {"upgrade": upgrade_data, "entry": entry_reference}

class DropSlotButton extends Button:
	var slot_index: int
	var shop_main: Node
	
	func _init(idx: int, main_scene: Node):
		slot_index = idx
		shop_main = main_scene
		
	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		if typeof(data) != TYPE_DICTIONARY or not data.has("upgrade"): return false
		
		var upgrade = data["upgrade"]
		var category = upgrade.get("category", "")
		var existing = GameManager.equipped_weapons[slot_index]
		
		# Rule A: Weapons can be dropped into any slot
		if category == "weapon": return true
		
		# Rule B: Mods must target an occupied slot with a matching weapon name
		if category == "weapon_mod":
			if existing != null and typeof(existing) == TYPE_DICTIONARY:
				return existing.get("name") == upgrade.get("target_weapon")
				
		return false
		
	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		shop_main.handle_drag_drop_purchase(data["upgrade"], slot_index, data["entry"])
