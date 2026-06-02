# Stats.gd
class_name Stats

static func execute_weapon(type, amount, target_stats: Dictionary, opponent_stats: Dictionary) -> void:
	match type:
		"heal":
			_heal(target_stats, opponent_stats, amount)
		"damage":
			_damage(target_stats,opponent_stats, amount)
		_:
			print("Unknown weapon type: ", type)

static func _damage(target_stats: Dictionary, opponent_stats: Dictionary, amount: float) -> void:
	target_stats["stats"]["hp"] -= amount
	target_stats["stats"]["hp"] = max(target_stats["stats"]["hp"], 0)

static func _heal(target_stats: Dictionary, opponent_stats: Dictionary, amount: float) -> void:
	target_stats["stats"]["hp"] += amount
	target_stats["stats"]["hp"] = min(target_stats["stats"]["hp"], target_stats["stats"]["maxhp"])
