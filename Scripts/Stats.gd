# Stats.gd
class_name Stats_Handler

const FloatingTextScene = preload("res://Scenes/floating_text.tscn")


static func execute_weapon(battle_node: Node, target_node: Node, attacker_node: Node, weapon_node: Node, weapon_data: Dictionary, target_stats: Dictionary, attacker_stats: Dictionary):	
	var isShield = weapon_data["friendly"]
	var type = weapon_data["type"]
	var level = weapon_data["level"]
	
	if !isShield:
		var attacker_DMG = GameManager.getpassive3("DMG",attacker_stats)
		
		var final_Damage = attacker_DMG
		match type:
			"DMG":
				final_Damage += attacker_DMG
				
		GameManager.addtopassive3("HP",-final_Damage,target_stats)
	else:
		match type:
			"DMG":
				GameManager.addtopassive3("DMG",1,attacker_stats)
		

	var who_data = target_stats
	var who_sprite = target_node
	if isShield:
		who_data = attacker_stats
		who_sprite = attacker_node
	attacker_node.attack_target(weapon_node, who_sprite.global_position, 0.2)

static func show_damage_dealt(battle_node, target_node, amount):
	var floating_text = FloatingTextScene.instantiate()
	battle_node.add_child(floating_text) # Use the battle_node passed in
	
	floating_text.global_position = target_node.global_position + Vector2(randf_range(-20, 20), -80)
	floating_text.setup(amount,(amount > 0),0)
