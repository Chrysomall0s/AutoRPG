extends Control

@onready var gold_label: Label = Label.new()
@onready var main_button_container: VBoxContainer = $ButtonContainer 

var slot_button_container: HBoxContainer 
var upgrade_buttons = []
var pending_upgrade = null 

var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

func _ready():
	randomize()
	setup_gold_ui()

	# Create the horizontal menu container for slots, keep hidden at first
	slot_button_container = HBoxContainer.new()
	slot_button_container.hide()
	add_child(slot_button_container)

	var selected_upgrades = get_random_upgrades(3)
	for upgrade in selected_upgrades:
		create_upgrade_button(upgrade)

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
# BUTTONS
# ---------------------------------
func create_upgrade_button(upgrade):
	var button = Button.new()
	button.text = upgrade["name"] + " (" + str(upgrade["cost"]) + ")"
	button.custom_minimum_size = Vector2(500, 120)

	button.pressed.connect(func():
		request_upgrade(upgrade)
	)

	upgrade_buttons.append({
		"button": button,
		"upgrade": upgrade
	})
	main_button_container.add_child(button)


func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 120)
	button.pressed.connect(callback)
	main_button_container.add_child(button)


func update_upgrade_colors():
	for entry in upgrade_buttons:
		var button = entry["button"]
		var upgrade = entry["upgrade"]

		if GameManager.gold < upgrade["cost"]:
			button.modulate = Color(1, 0.4, 0.4) 
		else:
			button.modulate = Color(1, 1, 1) 

# ---------------------------------
# SLOT SELECTION UI (UPDATED)
# ---------------------------------
func setup_slot_buttons():
	# Clear out old buttons first so they don't stack up
	for child in slot_button_container.get_children():
		child.queue_free()
		
	var slots = ["Left", "Middle", "Right"]
	if not GameManager.right_slot_unlocked:
		slots = ["Left", "Middle"]
		
	for slot in slots:
		var btn = Button.new()
		
		# Check GameManager to see what's equipped
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
		
	# Re-add the cancel button at the end
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(160, 120)
	cancel_btn.pressed.connect(cancel_slot_selection)
	slot_button_container.add_child(cancel_btn)

# ---------------------------------
# APPLY UPGRADE LOGIC
# ---------------------------------
func request_upgrade(upgrade):
	if GameManager.gold < upgrade["cost"]:
		print("Not enough gold")
		return

	# Check if the upgrade requires choosing a slot
	if upgrade["is_equip"]:
		pending_upgrade = upgrade
		setup_slot_buttons()
		main_button_container.hide()
		slot_button_container.show()
	else:
		# Instant item (like Helmet/Heal) -> process it immediately
		GameManager.gold -= upgrade["cost"]
		UpgradeSystem.apply_upgrade(upgrade, "") # No slot needed
		update_gold()
		update_upgrade_colors()


func confirm_upgrade_to_slot(slot_name: String):
	if pending_upgrade == null: return
	
	GameManager.gold -= pending_upgrade["cost"]
	UpgradeSystem.apply_upgrade(pending_upgrade, slot_name)
	
	pending_upgrade = null
	slot_button_container.hide()
	main_button_container.show()
	
	update_gold()
	update_upgrade_colors()


func cancel_slot_selection():
	pending_upgrade = null
	slot_button_container.hide()
	main_button_container.show()


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
