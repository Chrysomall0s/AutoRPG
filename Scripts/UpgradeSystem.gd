# =================================================================
# res://Scripts/UpgradeSystem.gd
# =================================================================
extends Node

## Processes all store items based on their category: passive, weapon, or weapon_mod.
func apply_upgrade(upgrade: Dictionary, target_destination: String):
	# Safely extract the item category type
	var category = upgrade.get("category", "passive")
	
	match category:
		"passive":
			# Target destination is set to "character" via shop layout actions
			process_character_stat_mod(upgrade)
			
		"weapon":
			# Direct weapon slot registration logic.
			# target_destination is the weapon slot index (e.g., "0", "1", "2")
			if target_destination != "character" and target_destination != "":
				var slot_idx = int(target_destination)
				print("Weapon Equipped to Slot ", slot_idx + 1, ": ", upgrade["name"])
				# Note: GameManager.equipped_weapons[slot_idx] assignment 
				# is managed directly inside your main transactions layer.
				
		"weapon_mod":
			# Weapon leveling stat multipliers
			if target_destination != "character" and target_destination != "":
				var slot_idx = int(target_destination)
				print("Weapon in Slot ", slot_idx + 1, " upgraded via ", upgrade["name"])
				# Additional global character buffs can be scaled here if a weapon mod 
				# also scales overall character performance alongside weapon metrics.

## Handles passive items that alter global character attributes permanently
func process_character_stat_mod(upgrade: Dictionary):
	# Safely grab keys using .get() to prevent invalid access crashes if keys are missing
	var stat_type = upgrade.get("type", "")
	var value = upgrade.get("value", 0)
	
	match stat_type:
		"speed":
			if "player_speed" in GameManager:
				GameManager.player_speed += value
				print("Global Player Speed increased by ", value, ". Current: ", GameManager.player_speed)
				
		"hp":
			if "max_player_hp" in GameManager:
				GameManager.max_player_hp += value
				# Heal player by the amount gained so their current hp scales smoothly
				if "player_hp" in GameManager:
					GameManager.player_hp += value
				print("Global Max HP increased by ", value, ". Current: ", GameManager.max_player_hp)
				
		"damage":
			if "player_damage" in GameManager:
				GameManager.player_damage += value
				print("Global Base Player Damage increased by ", value, ". Current: ", GameManager.player_damage)
				
		"heal":
			if "max_player_hp" in GameManager and "player_hp" in GameManager:
				GameManager.player_hp = GameManager.max_player_hp
				print("Player HP completely restored to maximum: ", GameManager.player_hp)
