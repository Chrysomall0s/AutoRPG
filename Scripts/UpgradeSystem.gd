# UpgradeSystem.gd
extends Node

static func apply_upgrade(upgrade: Dictionary):
	match upgrade["type"]:

		"speed":
			GameManager.player_speed += upgrade["value"]

		"hp":
			GameManager.player_hp += upgrade["value"]

		"damage":
			GameManager.player_damage += upgrade["value"]

		"heal":
			GameManager.player_hp = 100
