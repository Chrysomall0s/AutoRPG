extends Node

# Updated to return an Array of monster dictionaries
var monsters = {
	"Easy": [
		{
		"icon": "res://Assets/atlas/fruit.tres", "index": 4,
			"passives": [
			{"name": "HP", "level": 12},
			],
			"weapons": ["Staff"],
			"audience": ["Heckler"]
		},
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"passives": [
			{"name": "HP", "level": 12},
			],
			"weapons": ["Club"],
			"audience": ["Heckler"]
		},
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"passives": [
			{"name": "HP", "level": 12},
			],
			"weapons": ["Staff"],
			"audience": ["Heckler"]
		},
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"passives": [
			{"name": "HP", "level": 12},
			],
			"weapons": ["Staff"],
			"audience": ["Heckler"]
		},
	],
	"Normal": [
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"passives": [
			{"name": "HP", "level": 12},
			],
			"weapons": ["Staff"],
			"audience": ["Heckler"]
		},
	],
	"Hard": [
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1
			,"passives":[
			{"name": "HP", "level": 12},
			],
			"weapons": ["Staff"],
			"audience": ["Heckler"]
		},
	],
	"Insane": [
		{
			"icon": "res://Assets/atlas/fruit.tres", "index": 1,
			"passives": [
			{"name": "HP", "level": 12},
			],
			"weapons": ["Staff"],
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
# 1. Add the weapons from your loadout (up to 6)
	for i in range(6):
		if i < weapon_names.size():
			var weapon_input = weapon_names[i] # This can be a String or a Dictionary
			
			if weapon_input == null:
				monster_profile["weapons"].append(null)
			else:
				var weapon_data = get_processed_data(weapon_input)
				if not weapon_data.is_empty():
					var weapon_copy = weapon_data.duplicate()
					
					# FIX: Use weapon_data["name"] instead of the raw input which might be a dictionary
					var w_name_str = weapon_data.get("name", "unknown")
					weapon_copy["unique_id"] = str(i) + "_" + w_name_str + "_" + str(Time.get_ticks_usec())
					
					weapon_copy["level"] = weapon_copy.get("level", 1)
					monster_profile["weapons"].append(weapon_copy)
				else:
					# Fallback
					monster_profile["weapons"].append({"name": str(weapon_input), "level": 1})
		else:
			monster_profile["weapons"].append(null)
	# 2. Populate Passives
	for name in raw_data.get("passives", []):
		var data = get_processed_data(name)
		if data: monster_profile["passives"].append(data.duplicate())

	# 3. Populate Audience
	for name in raw_data.get("audience", []):
		var data = get_processed_data(name)
		if data: monster_profile["audience"].append(data.duplicate())

	return monster_profile
	
func _find_upgrade_by_name(target_name: String) -> Dictionary:
	for upgrade in UpgradeData.upgrades:
		if upgrade.get("name") == target_name:
			return upgrade

	assert(false, "Upgrade not found: %s" % target_name)
	return {}
# Ensure this helper exists in this script or is accessible
func get_processed_data(input) -> Dictionary:
	# If input is just a string, fetch default data
	if input is String:
		return _find_upgrade_by_name(input).duplicate(true)
	
	# If input is a dictionary (has overrides), fetch default and merge
	if input is Dictionary and input.has("name"):
		var base_data = _find_upgrade_by_name(input["name"]).duplicate(true)
		# Merge dictionary: values in input overwrite values in base_data
		for key in input:
			base_data[key] = input[key]
		return base_data
		
	return {}
