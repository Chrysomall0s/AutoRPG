extends Control

@onready var gold_label: Label = Label.new()

var upgrade_buttons = []

var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()


func _ready():
	randomize()

	setup_gold_ui()

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
		apply_upgrade(upgrade)
	)

	# store BOTH button + upgrade
	upgrade_buttons.append({
		"button": button,
		"upgrade": upgrade
	})

	$ButtonContainer.add_child(button)

func update_upgrade_colors():
	for entry in upgrade_buttons:
		var button = entry["button"]
		var upgrade = entry["upgrade"]

		if GameManager.gold < upgrade["cost"]:
			button.modulate = Color(1, 0.4, 0.4) # red
		else:
			button.modulate = Color(1, 1, 1) # normal
			
func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(500, 120)

	button.pressed.connect(callback)
	$ButtonContainer.add_child(button)


# ---------------------------------
# APPLY UPGRADE (USES SYSTEM)
# ---------------------------------
func apply_upgrade(upgrade):
	if GameManager.gold < upgrade["cost"]:
		print("Not enough gold")
		return

	GameManager.gold -= upgrade["cost"]

	UpgradeSystem.apply_upgrade(upgrade)

	update_gold()
	update_upgrade_colors()


func update_gold():
	gold_label.text = "Gold: " + str(GameManager.gold)
	update_upgrade_colors()

func setup_gold_ui():
	gold_label.position = Vector2(20, 20)
	add_child(gold_label)


func _play():
	GameManager.enemy_hp = 100 + (GameManager.selected_difficulty * 20)
	get_tree().change_scene_to_file("res://Scenes/Battle.tscn")
