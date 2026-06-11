extends Node

# Updated to return an Array of monster dictionaries
var monsters = {
	"Easy": [
		{
		"icon": "res://Assets/atlas/fruit.tres", "index": 4,
			"stats": {
				"maxhp": 50,
				"hp": 50,
				"dmg": 4,
				"speed": 5,
			},
			"passives": [],
			"weapons": ["Sword"],
			"audience": ["Heckler"]
		},
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"stats": {
				"maxhp": 60,
				"hp": 60,
				"dmg": 5,
				"speed": 4,
			},
			"passives": [],
			"weapons": ["Axe"],
			"audience": ["Heckler"]
		},
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"stats": {
				"maxhp": 60,
				"hp": 120,
				"dmg": 5,
				"speed": 4,
			},
			"passives": [],
			"weapons": ["Axe"],
			"audience": ["Heckler"]
		},
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"stats": {
				"maxhp": 60,
				"hp": 200,
				"dmg": 5,
				"speed": 4,
			},
			"passives": [],
			"weapons": ["Axe"],
			"audience": ["Heckler"]
		},
	],
	"Normal": [
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"stats": {
				"maxhp": 50,
				"hp": 50,
				"dmg": 4,
				"speed": 5,
			},
			"passives": [],
			"weapons": ["Sword"],
			"audience": ["Heckler"]
		},
	],
	"Hard": [
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1
			,
			"stats": {
				"maxhp": 50,
				"hp": 50,
				"dmg": 4,
				"speed": 5,
			},
			"passives": [],
			"weapons": ["Sword"],
			"audience": ["Heckler"]
		},
	],
	"Insane": [
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"stats": {
				"maxhp": 50,
				"hp": 50,
				"dmg": 4,
				"speed": 5,
			},
			"passives": [],
			"weapons": ["Sword"],
			"audience": ["Heckler"]
		},
	],
}

func has_next_round(difficulty_key: int, round: int) -> bool:
	
	var difficulty_list = monsters[GameManager.get_difficulty_key()]
	return round + 1 < difficulty_list.size()

func get_monster(difficulty_key: String, round: int) -> Dictionary:
	if !monsters.has(difficulty_key):
		assert(false, "Unknown difficulty key: %s" % difficulty_key)

	var difficulty_list = monsters[difficulty_key]

	if round < 0 or round >= difficulty_list.size():
		assert(
			false,
			"Round %d out of range for difficulty '%s' (size=%d)" %
			[round, difficulty_key, difficulty_list.size()]
		)

	var raw_data = difficulty_list[round]
	
	# Create a profile structure identical to the player's
	var monster_profile = {
		"stats": raw_data.get("stats", {}).duplicate(),
		"passives": [],
		"weapons": [],
		"audience": [],
		"icon": raw_data.get("icon"),
		"index": raw_data.get("index", 0)
	}

	# 1. Initialize Weapons (Guaranteed 6 slots)
	var weapon_names = raw_data.get("weapons", [])
	for i in range(6):
		if i < weapon_names.size():
			var w_name = weapon_names[i]
			var full_data = _find_upgrade_by_name(w_name)
			# --- APPLY UNIQUE ID LOGIC HERE ---
			var weapon_entry = full_data.duplicate(true) if !full_data.is_empty() else {"name": w_name, "level": 1}
			# --- APPLY UNIQUE ID LOGIC HERE ---
			# Add a prefix to distinguish enemy weapons from player weapons
			weapon_entry["unique_id"] = "enemy_" + str(i) + "_" + w_name + "_" + str(Time.get_ticks_usec())
			monster_profile["weapons"].append(weapon_entry)
		else:
			monster_profile["weapons"].append(null)

	# 2. Populate Passives
	for name in raw_data.get("passives", []):
		var data = _find_upgrade_by_name(name)
		if data: monster_profile["passives"].append(data.duplicate())

	# 3. Populate Audience
	for name in raw_data.get("audience", []):
		var data = _find_upgrade_by_name(name)
		if data: monster_profile["audience"].append(data.duplicate())

	return monster_profile

# Ensure this helper exists in this script or is accessible
func _find_upgrade_by_name(target_name: String) -> Dictionary:
	var UpgradeData = preload("res://Scripts/UpgradeData.gd").new()

	for upgrade in UpgradeData.upgrades:
		if upgrade.get("name") == target_name:
			return upgrade

	assert(false, "Upgrade not found: %s" % target_name)
	return {}
