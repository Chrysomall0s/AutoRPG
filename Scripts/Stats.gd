# Stats.gd
class_name Stats_Handler

const FloatingTextScene = preload("res://Scenes/floating_text.tscn")


static func execute_weapon(battle_node: Node, target_node: Node, attacker_node: Node, weapon_node: Node, weapon_data: Dictionary, target_stats: Dictionary, attacker_stats: Dictionary):	
    var friendly = weapon_data["friendly"]
    var what = weapon_data["type"]
    var howmuch = weapon_data["level"]
    var who_data = target_stats
    var who_sprite = target_node
    if friendly:
        who_data = attacker_stats
        who_sprite = attacker_node
    match what:
        "DMG":
            DealDamage(battle_node,who_sprite, who_data,howmuch)
    commoncalculation(target_stats)
    attacker_node.attack_target(weapon_node, who_sprite.global_position, 0.2)

static func show_damage_dealt(battle_node, target_node, amount):
    var floating_text = FloatingTextScene.instantiate()
    battle_node.add_child(floating_text) # Use the battle_node passed in
    
    floating_text.global_position = target_node.global_position + Vector2(randf_range(-20, 20), -80)
    floating_text.setup(amount,(amount > 0),0)


static func DealDamage(battle_node,who_sprite, target_stats: Dictionary, howmuch: int):    #for thorns up to thorns gets reflected back to the other
    #var thorndamage = min(getpassive3("Thorns", target_stats), howmuch)
    GameManager.addtopassive3("HP",-howmuch,target_stats)
    show_damage_dealt(battle_node,who_sprite,-howmuch)
    
static func commoncalculation(target_stats: Dictionary):
    print("hey")
