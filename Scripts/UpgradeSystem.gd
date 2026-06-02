# =================================================================
# res://Scripts/UpgradeSystem.gd
# =================================================================
extends Node

func upgradeStats(upgrade: Dictionary):
	# Safely extract the item category type
	var category = upgrade.get("category", "passive")
	var type = upgrade.get("type", "heal")

	match category:
		"viewer":
			GameManager.audience_members.append(upgrade)	
	
	match type:
		"heal":
			_heal
	
static func _damage(amount: float) -> void:
	var stats = GameManager.player_profile["stats"]
	stats["hp"] -= amount
	stats["hp"] = max(stats["hp"], 0)

static func _heal(amount: float) -> void:
	var stats = GameManager.player_profile["stats"]
	stats["hp"] += amount
	stats["hp"] = max(stats["hp"], 0)
			
