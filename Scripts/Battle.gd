extends Control

const TimeController = preload("res://Scripts/time.gd")

@onready var player_sprite = $Hero
@onready var enemy_sprite = $Foe
@onready var audience_container = $AudienceContainer

@export_group("Run Button Layout")
@export var run_btn_width_ratio: float = 0.80
@export var run_btn_height_ratio: float = 0.09
@export var run_btn_bottom_margin_ratio: float = 0.04
@export_group("Text Typography Scaling")
@export var run_button_font_ratio: float = 0.024

var time_ctrl = TimeController.new()
var battle_timeline: Array = [] 
var elapsed_time: float = 0.0
var battle_over := false

@onready var textureRect = $TextureRect
func fit_to_screen():
    # 1. Disable anchors if you are setting size manually
    textureRect.anchor_left = 0
    textureRect.anchor_top = 0
    textureRect.anchor_right = 0
    textureRect.anchor_bottom = 0
    
    # 2. Set the size to the viewport
    textureRect.size = get_viewport_rect().size
    
    # 3. Ensure the texture stretches to fill that size
    textureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    textureRect.stretch_mode = TextureRect.STRETCH_SCALE
    

func _ready():
    fit_to_screen()
    GameManager.battle_over = false
    add_child(time_ctrl)
    time_ctrl.create_time_buttons(self)
    setup_battlefield()
    
    # Pre-calculate everything before the battle starts
   
    
    player_sprite.activate_battle_mode()
    enemy_sprite.activate_battle_mode()
    
    calculate_timeline() 
    initialize_weapon_timers()
    
    if audience_container.has_method("populate_audience"):
        audience_container.populate_audience()




func setup_battlefield():
    var screen_size = get_viewport_rect().size
    player_sprite.position = Vector2(screen_size.x * 0.25, screen_size.y * 0.5)
    enemy_sprite.position = Vector2(screen_size.x * 0.75, screen_size.y * 0.5)
    player_sprite.refresh_character_and_weapons(GameManager.player_profile)
    enemy_sprite.refresh_character_and_weapons(GameManager.current_enemy_profile)
# Change the variable to an integer to track 'Turns' or 'Ticks'
var current_tick: int = 0
# A simple multiplier to control how many real-world seconds each tick takes
@export var seconds_per_tick: float = 1.0 
var time_since_last_tick: float = 0.0

func get_gcd(a: int, b: int) -> int:
    while b:
        a %= b
        var temp = a
        a = b
        b = temp
    return a

func get_lcm(a: int, b: int) -> int:
    if a == 0 or b == 0: return 0
    return abs(a * b) / get_gcd(a, b)

func calculate_timeline():
    var p_weapons = GameManager.player_profile.get("weapons", []) if GameManager.player_profile.get("weapons") != null else []
    var e_weapons = GameManager.current_enemy_profile.get("weapons", []) if GameManager.current_enemy_profile.get("weapons") != null else []
    
    var all_weaponsss = p_weapons + e_weapons
    
    var all_weapons = []
    for w in all_weaponsss:
        if w != null:
            all_weapons.append(w)
    # 1. Find the cycle length (LCM of all speeds)
    var cycle_length = 1
    for w in all_weapons:
        var speed = int(w["speed"])
        cycle_length = get_lcm(cycle_length, speed)
        
    # 2. Build the pattern for one cycle
    var cycle_pattern = []
    for tick in range(1, cycle_length + 1):
        for weapon in all_weapons:
            var speed = cycle_length / int(weapon["speed"])
            if tick % speed == 0:
                cycle_pattern.append({
                    "type": "weapon",
                    "tick": tick,
                    "weapon": weapon
                })
                
    # 3. Repeat the pattern to fill max_rounds
    # Note: In this system, 'max_rounds' might represent full cycles 
    # or specific tick durations depending on your game needs.
    battle_timeline.append_array(cycle_pattern)

var tickcount = 0   



func find_weapon_node_from_data(data: Dictionary) -> Node:
    # Check player sprites
    var id = data["unique_id"]
    for w in player_sprite.weapon_sprites:
        var index = w.get_meta("slot_index", -1)
        # Check index bounds and data match
        if index != -1 and index < GameManager.player_profile["weapons"].size():
            if GameManager.player_profile["weapons"][index].get("unique_id") == data.get("unique_id"):
                return w

    # Check enemy sprites (ensure this block is at the same indentation level as the first loop)
    for w in enemy_sprite.weapon_sprites:
        var index = w.get_meta("slot_index", -1)
        if index != -1 and index < GameManager.current_enemy_profile["weapons"].size():
            if GameManager.current_enemy_profile["weapons"][index].get("unique_id") == data.get("unique_id"):
                return w
                
    return null
        


func _process(delta):
    
    player_sprite.update_weapon_movements(delta, player_sprite.position)
    enemy_sprite.update_weapon_movements(delta, enemy_sprite.position)
    
    if GameManager.battle_over:
        return
    # 1. Update weapon shader progress
    var current_time = tickcount
    
    time_since_last_tick += delta
    var progress2
    var total_duration
    var last_tick
    var next_tick
    var all_weapondata = GameManager.player_profile["weapons"] + GameManager.current_enemy_profile["weapons"]
    
    for weapondata in all_weapondata:
        if weapondata == null: continue
        var weapon = find_weapon_node_from_data(weapondata)
        last_tick = weapon.get_meta("last_activation", 0)
        next_tick = weapon.get_meta("next_activation", 0)
        
        total_duration = (next_tick - last_tick) * seconds_per_tick
        var progress = (current_time - last_tick) * seconds_per_tick / total_duration + time_since_last_tick/ total_duration
        progress2 = progress
        if progress > 2:
            var a = 0
            a += 1
        if total_duration > 0:
            progress = clamp(progress, 0.0, 1.0)
        #progress *= 0.25   
        #progress += 0.7
        if weapon.material is ShaderMaterial:
            weapon.material.set_shader_parameter("charge_progress", progress)

            var index = weapondata["index"]
            weapon.material.set_shader_parameter("index", index) #how_much_down = index/4;

    # 2. Existing Combat Logic (Unchanged)
    if battle_over:
        return
    
    
    
    if time_since_last_tick >= seconds_per_tick:
       
        if progress2 < 0.8:
            var a = 0
            a += 1
        time_since_last_tick = 0.0
        next_event_index += 1
        if(next_event_index == battle_timeline.size()):
            next_event_index = 0
        var event = battle_timeline[next_event_index]
        if event["type"] == "weapon":
            execute_weapon_event(find_weapon_node_from_data(event.weapon), event.weapon)
            
    
       
var next_event_index: int = 0
var last_execution_time: float = 0.0
var time_speed_multiplier: float = 0.00005 # 1.0 is normal, 0.5 is half speed, 0.1 is very slow

func initialize_weapon_timers():
    var p_weapons = GameManager.player_profile.get("weapons", []) if GameManager.player_profile.get("weapons") != null else []
    var e_weapons = GameManager.current_enemy_profile.get("weapons", []) if GameManager.current_enemy_profile.get("weapons") != null else []
    
    var all_weaponsss = p_weapons + e_weapons
    
    var all_weapons_nodes = []
    for w in all_weaponsss:
        if w != null:
            all_weapons_nodes.append(w)
    # We need to map the node to its data dictionary
    # Assuming your weapon nodes have a way to access their underlying data
    # (If not, you may need to pass the data dict during setup_battlefield)
    for weapon in all_weapons_nodes:
        # Assuming you have a way to retrieve the data associated with this sprite
        # If your data is stored in GameManager, find it by ID or index
        var weapon_sprite = find_weapon_node_from_data(weapon)
        
        if weapon:
            var ticks_until_next = get_ticks_until_next_fire(weapon)
            weapon_sprite.set_meta("last_activation", 0) # Start at 0
            weapon_sprite.set_meta("next_activation", ticks_until_next)
      
func get_ticks_until_next_fire(weapon: Dictionary) -> int:
    # 1. Find the current position in the cycle
    # Since the timeline repeats based on the LCM calculated in calculate_timeline,
    # we use modulo to find where we are in the pattern.

    # Re-calculate cycle_length or store it as a class variable 
    # (Storing it as a class variable is more efficient)
    
    # Assuming you store cycle_length during calculate_timeline:
    var cT = tickcount % battle_timeline.size()
    
    # 2. Search for the next occurrence
    # We check through the timeline to find the next entry for this specific weapon
    var j = cT
    for i in range(battle_timeline.size()):
        j+=1
        if j == battle_timeline.size():
            j=0
        var event = battle_timeline[j]
        
        # Check if this is the weapon we are looking for
        if event.weapon["unique_id"] == weapon["unique_id"]:
            # We need an event that happens at a tick GREATER than current tickcount
            var dif = abs(j - cT)
            if(dif==2):
                print_debug("hey")
            if j > cT:
                return dif
            
            # If the weapon fires again in the next cycle, we account for that
            # The gap is (cycle_length - current_tick_in_cycle) + next_tick_in_cycle
            return battle_timeline.size() - dif
            
    return -1
 
func execute_weapon_event(weapon, weapon_data: Dictionary):
    var attacker_node = weapon.get_parent()
    var target_node = enemy_sprite if attacker_node == player_sprite else player_sprite
    var attacker_stats = GameManager.player_profile if attacker_node == player_sprite else GameManager.current_enemy_profile
    var target_stats = GameManager.current_enemy_profile if attacker_node == player_sprite else GameManager.player_profile
    tickcount += 1
    var ticks_until_next = get_ticks_until_next_fire(weapon_data)
    if(ticks_until_next > 6):
        print_debug("hey")
    weapon.set_meta("last_activation", tickcount)

    weapon.set_meta("next_activation", tickcount + ticks_until_next)
    # Apply stats
    Stats_Handler.execute_weapon(self, target_node, attacker_node, weapon, weapon_data, target_stats, attacker_stats)
    
    # UI Refresh
    player_sprite.draw_health(GameManager.player_profile)
    enemy_sprite.draw_health(GameManager.current_enemy_profile)
    
    await get_tree().create_timer(0.8).timeout
    weapon.set_meta("last_fired_tick", current_tick)

    check_game_state()

func check_game_state():
    if battle_over: return
    if GameManager.getpassive("HP")<= 0:
        battle_over = false
        GameManager.go_to_after_battle("lose")
    if GameManager.getpassive2("HP")<= 0:
        battle_over = true
        GameManager.go_to_after_battle("win")
            
# =================================================================
# GAME STATE & TOURNAMENT LOGIC
# =================================================================


#func advance_or_finish_tournament():
    #var diff_key = GameManager.get_difficulty_key()
    #var next_round = GameManager.currentRound + 1
    #var next_enemy = MonsterData.get_monster(diff_key, next_round)
#
    #if next_enemy != {}:
        #GameManager.currentRound = next_round
        #GameManager.current_enemy_profile = next_enemy
        #get_tree().reload_current_scene()
    #else:
        #GameManager.unlock_difficulty_mastery()
        #go_to_after_battle("win")
