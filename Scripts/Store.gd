extends Control

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
	add_child(slot_button_container)

	# Generate the initial shop choices
	current_reroll_cost = base_reroll_cost
	refresh_store_upgrades()

	# Create persistent functional buttons
	create_reroll_button()
	create_button("Play", _play)
	
	update_gold()


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
	button.custom_minimum_size = Vector2(500, 120)

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
	reroll_button = Button.new()
	update_reroll_text()
	reroll_button.custom_minimum_size = Vector2(500, 120)
	reroll_button.pressed.connect(reroll_shop)
	main_button_container.add_child(reroll_button)


func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 120)
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

		# Skip altering style if it's already sold out
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
	for child in slot_button_container.get_children():
		child.queue_free()
		
	var slots = ["Left", "Middle", "Right"]
	if not GameManager.right_slot_unlocked:
		slots = ["Left", "Middle"]
		
	for slot in slots:
		var btn = Button.new()
		
		var current_equip = GameManager.equipped_slots.get(slot)
		if current_equip:
			btn.text = slot + "\n(" + str(current_equip.name) + ")"
		else:
			btn.text = slot + "\n(Empty)"
			
		btn.custom_minimum_size = Vector2(160, 120)
		btn.pressed.connect(func():
			confirm_upgrade_to_slot(slot)
		)
		slot_button_container.add_child(btn)
		
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(160, 120)
	cancel_btn.pressed.connect(cancel_slot_selection)
	slot_button_container.add_child(cancel_btn)


# ---------------------------------
# APPLY UPGRADE LOGIC
# ---------------------------------
func request_upgrade(entry):
	if entry["bought"]: return # Do nothing if already sold out
	
	var upgrade = entry["upgrade"]
	if GameManager.gold < upgrade["cost"]:
		print("Not enough gold")
		return

	if upgrade["is_equip"]:
		pending_upgrade = upgrade
		pending_button_entry = entry # Save the button reference to clear later
		setup_slot_buttons()
		main_button_container.hide()
		slot_button_container.show()
	else:
		GameManager.gold -= upgrade["cost"]
		UpgradeSystem.apply_upgrade(upgrade, "")
		
		# Mark this button empty immediately
		finalize_item_purchase(entry)
		update_gold()


func confirm_upgrade_to_slot(slot_name: String):
	if pending_upgrade == null: return
	
	GameManager.gold -= pending_upgrade["cost"]
	
	# Fix: Save item name as a plain string so UI reads it correctly
	GameManager.equipped_slots[slot_name] = pending_upgrade["name"]
	UpgradeSystem.apply_upgrade(pending_upgrade, slot_name)
	
	# Mark this button empty immediately
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
	entry["button"].modulate = Color(0.4, 0.4, 0.4, 0.6) # Dim it out
	
	items_bought_this_turn += 1
	
	# If they managed to buy all 3, make the next reroll completely free!
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
	gold_label.position = Vector2(20, 20)
	add_child(gold_label)


func _play():
	GameManager.enemy_hp = 100 + (GameManager.selected_difficulty * 20)
	get_tree().change_scene_to_file("res://Scenes/Battle.tscn")
