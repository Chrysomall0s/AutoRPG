extends Node

# Tracks what is currently equipped in each slot
func apply_upgrade(upgrade: Dictionary, slot_name: String):
	# 1. Pass equipment handling off to GameManager if it's equippable
	if upgrade["is_equip"] and slot_name != "":
		GameManager.equipped_slots[slot_name] = upgrade
	else:
		GameManager.owned_upgrades.append(upgrade)
	# 2. Process stat modifications
	match upgrade["type"]:
		"speed":
			GameManager.player_speed += upgrade["value"]
			
		"hp":
			GameManager.max_player_hp += upgrade["value"]
			
		"damage":
			GameManager.player_damage += upgrade["value"]
			
		"heal":
			GameManager.player_hp = GameManager.max_player_hp

	# 3. Add to global list of owned upgrades
	
