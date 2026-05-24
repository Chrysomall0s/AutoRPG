extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS (RESOLUTION DYNAMIC)
# =================================================================
@export_group("Text Typography Scaling")
# Base multipliers relative to total screen height
@export var gold_label_font_ratio: float = 0.028   # Header size (~33px at 1200 height)
@export var shop_button_font_ratio: float = 0.022  # Standard item size (~26px at 1200 height)
@export var slot_button_font_ratio: float = 0.018  # Sub-menu button size (~21px at 1200 height)

@export_group("Shop Item UI Layout")
@export var shop_item_width_ratio: float = 0.75   # 75% of screen width (540px at 720 width)
@export var shop_item_height_ratio: float = 0.095 # 9.5% of screen height (~114px at 1200 height)

@export_group("Slot Selection Layout")
@export var slot_button_width_ratio: float = 0.22  # Dynamic width for individual slot items
@export var slot_button_height_ratio: float = 0.09 # Dynamic height for individual slot items

@export_group("Persistent UI Offsets")
@export var gold_label_x_ratio: float = 0.04      # Left padding percentage for the currency label
@export var gold_label_y_ratio: float = 0.02      # Top padding percentage for the currency label
# =================================================================

@onready var gold_label: Label = Label.new()
@onready var main_button_container: VBoxContainer = $ButtonContainer 

var slot_button_container: HBoxContainer 
var upgrade_buttons = []
var pending_upgrade = null 
var pending_button_entry = null # Tracks which specific button is being bought

# Reroll settings
var base_reroll_cost: int = 10
var current_reroll_cost: int = 10
var reroll_button: Button
var items_bought_this_turn: int = 0

var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

func _ready():
	randomize()
	setup_gold_ui()

	# Create the horizontal menu container for slots, keep hidden at first
	slot_button_container = HBoxContainer.new()
	slot_button_container.hide()
	
	# Keep the layout centered on mobile screens
	slot_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_button_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	slot_button_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	# Fix: Explicitly using the proper Godot 4 SizeFlags namespace
	slot_button_container.size_flags_horizontal = 3 # 3 is exactly Expand (2) + Fill (1) combined!	
	add_child(slot_button_container)

	# Generate the initial shop choices
	current_reroll_cost = base_reroll_cost
	refresh_store_upgrades()

	# Create persistent functional buttons
	create_reroll_button()
	create_button("Leave", _play)
	
	update_gold()
	adjust_layout_containers()


func adjust_layout_containers():
	var screen_size = get_viewport_rect().size
	
	# Set position of gold counter safely
	gold_label.position = Vector2(screen_size.x * gold_label_x_ratio, screen_size.y * gold_label_y_ratio)
	
	# Set slot selection positioning box near lower-middle section safely
	slot_button_container.position = Vector2(
		(screen_size.x - slot_button_container.size.x) / 2.0,
		screen_size.y * 0.75
	)


# ---------------------------------
# GET UPGRADES FROM DATA FILE
# ---------------------------------
func get_random_upgrades(amount: int) -> Array:
	var pool = UpgradeData.upgrades.duplicate()
	var result = []

	while result.size() < amount and pool.size() > 0:
		var chosen = get_weighted_random(pool)
		result.append(chosen)
		pool.erase(chosen)

	return result


func get_weighted_random(pool: Array) -> Dictionary:
	var total_weight = 0
	for item in pool:
		total_weight += item["weight"]

	var roll = randi() % total_weight
	var current = 0

	for item in pool:
		current += item["weight"]
		if roll < current:
			return item

	return pool[0]


# ---------------------------------
# BUTTONS & STORE REFRESH
# ---------------------------------
func refresh_store_upgrades():
	# Reset tracking stats for the new roll
	items_bought_this_turn = 0
	current_reroll_cost = base_reroll_cost
	update_reroll_text()

	# Clear out previous buttons from the container & tracking array
	for entry in upgrade_buttons:
		if is_instance_valid(entry["button"]):
			entry["button"].queue_free()
	upgrade_buttons.clear()
	
	# Roll 3 fresh choices and position them at the top
	var selected_upgrades = get_random_upgrades(3)
	for i in range(selected_upgrades.size()):
		var upgrade = selected_upgrades[i]
		create_upgrade_button(upgrade)
		main_button_container.move_child(upgrade_buttons[i]["button"], i)
		
	update_upgrade_colors()


func create_upgrade_button(upgrade):
	var button = Button.new()
	button.text = upgrade["name"] + " (" + str(upgrade["cost"]) + ")"
	
	var screen_size = get_viewport_rect().size
	button.custom_minimum_size = Vector2(
		screen_size.x * shop_item_width_ratio, 
		screen_size.y * shop_item_height_ratio
	)

	# Apply dynamic font scaling
	var dynamic_font_size = int(screen_size.y * shop_button_font_ratio)
	button.add_theme_font_size_override("font_size", dynamic_font_size)

	var entry = {
		"button": button,
		"upgrade": upgrade,
		"bought": false
	}

	button.pressed.connect(func():
		request_upgrade(entry)
	)

	upgrade_buttons.append(entry)
	main_button_container.add_child(button)


func create_reroll_button():
	var screen_size = get_viewport_rect().size
	reroll_button = Button.new()
	update_reroll_text()
	
	reroll_button.custom_minimum_size = Vector2(
		screen_size.x * shop_item_width_ratio, 
		screen_size.y * shop_item_height_ratio
	)
	
	# Apply dynamic font scaling
	var dynamic_font_size = int(screen_size.y * shop_button_font_ratio)
	reroll_button.add_theme_font_size_override("font_size", dynamic_font_size)
	
	reroll_button.pressed.connect(reroll_shop)
	main_button_container.add_child(reroll_button)


func create_button(text, callback):
	var screen_size = get_viewport_rect().size
	var button = Button.new()
	button.text = text
	
	button.custom_minimum_size = Vector2(
		screen_size.x * shop_item_width_ratio, 
		screen_size.y * shop_item_height_ratio
	)
	
	# Apply dynamic font scaling
	var dynamic_font_size = int(screen_size.y * shop_button_font_ratio)
	button.add_theme_font_size_override("font_size", dynamic_font_size)
	
	button.pressed.connect(callback)
	main_button_container.add_child(button)


func update_reroll_text():
	if reroll_button:
		if current_reroll_cost == 0:
			reroll_button.text = "Reroll Shop (FREE!)"
		else:
			reroll_button.text = "Reroll Shop (" + str(current_reroll_cost) + " Gold)"


func update_upgrade_colors():
	for entry in upgrade_buttons:
		var button = entry["button"]
		var upgrade = entry["upgrade"]

		if entry["bought"]: 
			continue

		if GameManager.gold < upgrade["cost"]:
			button.modulate = Color(1, 0.4, 0.4) 
		else:
			button.modulate = Color(1, 1, 1) 
			
	if reroll_button:
		if GameManager.gold < current_reroll_cost:
			reroll_button.modulate = Color(1, 0.4, 0.4)
		else:
			reroll_button.modulate = Color(1, 1, 1)


# ---------------------------------
# REROLL SYSTEM LOGIC
# ---------------------------------
func reroll_shop():
	if GameManager.gold < current_reroll_cost:
		print("Not enough gold to reroll!")
		return
		
	GameManager.gold -= current_reroll_cost
	refresh_store_upgrades()
	update_gold()


# ---------------------------------
# SLOT SELECTION UI
# ---------------------------------
func setup_slot_buttons():
	var screen_size = get_viewport_rect().size
	var target_btn_size = Vector2(
		screen_size.x * slot_button_width_ratio,
		screen_size.y * slot_button_height_ratio
	)
	
	# Extract calculated font metrics
	var dynamic_font_size = int(screen_size.y * slot_button_font_ratio)
	
	for child in slot_button_container.get_children():
		child.queue_free()
		
	var slots = ["Left", "Middle", "Right"]
	if not GameManager.right_slot_unlocked:
		slots = ["Left", "Middle"]
		
	for slot in slots:
		var btn = Button.new()
		
		var current_equip = GameManager.equipped_slots.get(slot)
		if current_equip:
			btn.text = slot + "\n(" + str(current_equip) + ")"
		else:
			btn.text = slot + "\n(Empty)"
			
		btn.custom_minimum_size = target_btn_size
		btn.add_theme_font_size_override("font_size", dynamic_font_size)
		
		btn.pressed.connect(func():
			confirm_upgrade_to_slot(slot)
		)
		slot_button_container.add_child(btn)
		
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = target_btn_size
	cancel_btn.add_theme_font_size_override("font_size", dynamic_font_size)
	
	cancel_btn.pressed.connect(cancel_slot_selection)
	slot_button_container.add_child(cancel_btn)
	
	# Recalculate margins dynamically once children settle
	await get_tree().process_frame
	adjust_layout_containers()


# ---------------------------------
# APPLY UPGRADE LOGIC
# ---------------------------------
func request_upgrade(entry):
	if entry["bought"]: return 
	
	var upgrade = entry["upgrade"]
	if GameManager.gold < upgrade["cost"]:
		print("Not enough gold")
		return

	if upgrade["is_equip"]:
		pending_upgrade = upgrade
		pending_button_entry = entry 
		setup_slot_buttons()
		main_button_container.hide()
		slot_button_container.show()
	else:
		GameManager.gold -= upgrade["cost"]
		UpgradeSystem.apply_upgrade(upgrade, "")
		
		finalize_item_purchase(entry)
		update_gold()


func confirm_upgrade_to_slot(slot_name: String):
	if pending_upgrade == null: return
	
	GameManager.gold -= pending_upgrade["cost"]
	GameManager.equipped_slots[slot_name] = pending_upgrade["name"]
	UpgradeSystem.apply_upgrade(pending_upgrade, slot_name)
	
	if pending_button_entry:
		finalize_item_purchase(pending_button_entry)
	
	pending_upgrade = null
	pending_button_entry = null
	slot_button_container.hide()
	main_button_container.show()
	
	update_gold()


func cancel_slot_selection():
	pending_upgrade = null
	pending_button_entry = null
	slot_button_container.hide()
	main_button_container.show()


func finalize_item_purchase(entry):
	entry["bought"] = true
	entry["button"].text = "-- SOLD OUT --"
	entry["button"].disabled = true
	entry["button"].modulate = Color(0.4, 0.4, 0.4, 0.6) 
	
	items_bought_this_turn += 1
	
	if items_bought_this_turn >= 3:
		current_reroll_cost = 0
		update_reroll_text()


# ---------------------------------
# UTILITY
# ---------------------------------
func update_gold():
	gold_label.text = "Gold: " + str(GameManager.gold)
	update_upgrade_colors()


func setup_gold_ui():
	var screen_size = get_viewport_rect().size
	gold_label.position = Vector2(screen_size.x * gold_label_x_ratio, screen_size.y * gold_label_y_ratio)
	
	var dynamic_font_size = int(screen_size.y * gold_label_font_ratio)
	gold_label.add_theme_font_size_override("font_size", dynamic_font_size)
	
	add_child(gold_label)


func _play():
	GameManager.enemy_hp = 100 + (GameManager.selected_difficulty * 20)
	get_tree().change_scene_to_file("res://Scenes/Map.tscn")
