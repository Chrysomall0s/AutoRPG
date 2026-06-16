# Stats.gd
class_name Stats_Handler

const FloatingTextScene = preload("res://Scenes/floating_text.tscn")


static func execute_weapon(battle_node: Node, target_node: Node, attacker_node: Node, weapon_node: Node, weapon_data: Dictionary, target_stats: Dictionary, attacker_stats: Dictionary):	
	var isShield = weapon_data["friendly"]
	var type = weapon_data["type"]
	var level = weapon_data["level"]
	var attackerREG = GameManager.getpassive3("REG",attacker_stats)
	var targetREG = GameManager.getpassive3("REG",target_stats)
	var final_Recoil_Damage = 0
	var final_Damage = 0
	var attacker_DMG = GameManager.getpassive3("DMG",attacker_stats)
	if !isShield:
		var attacker_DEF = GameManager.getpassive3("DEF",attacker_stats)
		var target_DEF = GameManager.getpassive3("DEF",target_stats)
		final_Damage = attacker_DMG
		match type:
			"DMG":
				final_Damage += attacker_DMG
			"HP":
				var bonus = GameManager.getpassive3("HP",attacker_stats)
				final_Damage += bonus
			"REG":
				final_Damage += attackerREG
			"Gold":
				var bonus = GameManager.getpassive3("Gold",attacker_stats)
				final_Damage += bonus
			"Thorns":
				var bonus = GameManager.getpassive3("Thorns",attacker_stats)
				final_Damage += bonus
			"DEF":
				final_Damage += attacker_DEF
			"Burn":
				var bonus = GameManager.getpassive3("Burn",attacker_stats)
				final_Damage += bonus
			"Pierce":
				var bonus = GameManager.getpassive3("Pierce",attacker_stats)
				final_Damage += bonus
		
		final_Recoil_Damage = GameManager.getpassive3("Thorns",target_stats)	
		
		# Defense
		final_Recoil_Damage = max(0,final_Recoil_Damage-attacker_DEF)
		final_Damage = max(0,final_Damage-target_DEF)

	else:
		match type:
			"DMG":
				GameManager.addtopassive3("DMG",1,attacker_stats)
			"HP":
				final_Recoil_Damage -= attacker_DMG
			"REG":
				GameManager.addtopassive3("REG",1,attacker_stats)
			"Gold":
				GameManager.addtopassive3("MAXGold",1,attacker_stats)
			"Thorns":
				GameManager.addtopassive3("Thorns",1,attacker_stats)
			"DEF":
				GameManager.addtopassive3("DEF",1,attacker_stats)
		
	final_Recoil_Damage -= attackerREG
	GameManager.addtopassive3("HP",-final_Recoil_Damage,attacker_stats)
	show_damage_dealt(battle_node,attacker_node,-final_Recoil_Damage)

	final_Damage -= targetREG
	GameManager.addtopassive3("HP",-final_Damage,target_stats)
	show_damage_dealt(battle_node,target_node,-final_Damage)

	var who_data = target_stats
	var who_sprite = target_node
	if isShield:
		who_data = attacker_stats
		who_sprite = attacker_node
	attacker_node.attack_target(weapon_node, who_sprite.global_position, 0.2)

static func show_damage_dealt(battle_node, target_node, amount):
	var floating_text = FloatingTextScene.instantiate()
	battle_node.add_child(floating_text) # Use the battle_node passed in
	
	floating_text.global_position = target_node.global_position + Vector2(randf_range(-20, 20), +80)
	floating_text.setup(amount,(amount > 0),0)
