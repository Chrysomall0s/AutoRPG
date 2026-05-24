extends Control

var weapons = ["Sword", "Bow", "Staff"]

# Preload your scripts
var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()
var UpgradeSystem = preload("res://Scripts/UpgradeSystem.gd").new()

func _ready():
	for weapon in weapons:
		create_button(weapon, func():
			select_weapon(weapon)
		)

func create_button(text, callback):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(720, 120)

	button.pressed.connect(callback)
	$ButtonContainer.add_child(button)

func select_weapon(weapon_name):
	GameManager.selected_weapon = weapon_name
	
	# --- NEW LOGIC TO SLOT INTO MIDDLE ---
	# 1. Find the weapon's dictionary properties inside your upgrade database
	var weapon_data = null
	for upgrade in UpgradeData.upgrades:
		if upgrade["name"] == weapon_name:
			weapon_data = upgrade
			break
			
	# 2. If found, pass it to your upgrade system specifically for the "Middle" slot
	if weapon_data != null:
		UpgradeSystem.apply_upgrade(weapon_data, "Middle")
	else:
		print("Warning: Weapon data not found in UpgradeData pool!")
	# -------------------------------------

	get_tree().change_scene_to_file("res://Scenes/Map.tscn")
