extends Control

const TimeController = preload("res://Scripts/time.gd")
const FloatingTextScene = preload("res://Scenes/floating_text.tscn")

@onready var player_sprite = $Hero
@onready var enemy_sprite = $Foe
@onready var audience_container = $AudienceContainer

var time_ctrl = TimeController.new()
var battle_timeline: Array = [] 
var elapsed_time: float = 0.0
var battle_over := false

func _ready():
    add_child(time_ctrl)
    time_ctrl.create_time_buttons(self)
    
    setup_battlefield()
    
    # Pre-calculate everything before the battle starts
    calculate_timeline(60) 
    
    if audience_container.has_method("populate_audience"):
        audience_container.populate_audience()

func setup_battlefield():
    var screen_size = get_viewport_rect().size
    player_sprite.position = Vector2(screen_size.x * 0.25, screen_size.y * 0.3)
    enemy_sprite.position = Vector2(screen_size.x * 0.75, screen_size.y * 0.3)
    player_sprite.refresh_character_and_weapons(GameManager.player_profile)
    enemy_sprite.refresh_character_and_weapons(GameManager.current_enemy_profile)
# Change the variable to an integer to track 'Turns' or 'Ticks'
var current_tick: int = 0
# A simple multiplier to control how many real-world seconds each tick takes
@export var seconds_per_tick: float = 1.0 
var time_since_last_tick: float = 0.0

func calculate_timeline(max_rounds: int):
    var all_weapons = player_sprite.weapon_sprites + enemy_sprite.weapon_sprites
    
    # Sort weapons by their 'speed' so faster weapons go first in the sequence
    all_weapons.sort_custom(func(a, b): 
        return float(a.get_meta("speed", 1.0)) > float(b.get_meta("speed", 1.0))
    )
    
    # Build the sequence
    for i in range(max_rounds):
        for weapon in all_weapons:
            battle_timeline.append({
                "type": "weapon",
                "tick": i, # This is the Turn Number
                "weapon": weapon
            })

func _process(delta):
    player_sprite.update_weapon_movements(delta, player_sprite.position)
    enemy_sprite.update_weapon_movements(delta, enemy_sprite.position)

    if battle_over or next_event_index >= battle_timeline.size():
        return
    
    time_since_last_tick += delta
    
    # Wait until 'seconds_per_tick' has passed
    if time_since_last_tick >= seconds_per_tick:
        time_since_last_tick = 0.0
        
        # Execute the next event in the sequence
        var event = battle_timeline[next_event_index]
        if event.type == "weapon":
            execute_weapon_event(event.weapon)
            
        next_event_index += 1
var next_event_index: int = 0
var last_execution_time: float = 0.0
var time_speed_multiplier: float = 0.00005 # 1.0 is normal, 0.5 is half speed, 0.1 is very slow
            
func execute_weapon_event(weapon):
    var attacker_node = weapon.get_parent()
    var target_node = enemy_sprite if attacker_node == player_sprite else player_sprite
    var attacker_stats = GameManager.player_profile if attacker_node == player_sprite else GameManager.current_enemy_profile
    var target_stats = GameManager.current_enemy_profile if attacker_node == player_sprite else GameManager.player_profile
    
    # Apply stats
    Stats.execute_weapon(weapon.get_meta("weapon_type"), weapon.get_meta("amount"), target_stats, attacker_stats)
    
    # Visuals
    var floating_text = FloatingTextScene.instantiate()
    add_child(floating_text)
    
    floating_text.global_position = target_node.global_position + Vector2(randf_range(-20, 20), -80)
    if (weapon.get_meta("friendly")):
            floating_text.global_position = attacker_node.global_position + Vector2(randf_range(-20, 20), -80)
    floating_text.setup(abs(weapon.get_meta("amount")), weapon.get_meta("friendly"), 0)
    
    var attack_pos = attacker_node.global_position + Vector2(0, -50) if weapon.get_meta("friendly") else target_node.global_position
    attacker_node.attack_target(weapon, attack_pos, 0.2)
    
    # UI Refresh
    player_sprite.draw_health(GameManager.player_profile["stats"])
    enemy_sprite.draw_health(GameManager.current_enemy_profile["stats"])
    
    await get_tree().create_timer(0.8).timeout
    
    check_game_state()

func check_game_state():
    if battle_over: return
    if GameManager.player_profile["stats"]["hp"] <= 0 or GameManager.current_enemy_profile["stats"]["hp"] <= 0:
        battle_over = true
        if GameManager.current_enemy_profile["stats"]["hp"] <= 0:
            advance_or_finish_tournament()
        else:
            show_loss_popup()
# =================================================================
# GAME STATE & TOURNAMENT LOGIC
# =================================================================

func advance_or_finish_tournament():
    var diff_key = GameManager.get_difficulty_key()
    var next_round = GameManager.currentRound + 1
    var next_enemy = MonsterData.get_monster(diff_key, next_round)

    if next_enemy != {}:
        GameManager.currentRound = next_round
        GameManager.current_enemy_profile = next_enemy
        get_tree().reload_current_scene()
    else:
        GameManager.unlock_difficulty_mastery()
        show_tournament_win()

func show_tournament_win():
    var canvas = CanvasLayer.new()
    canvas.layer = 100
    add_child(canvas)

    var overlay = ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.8)
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(overlay)

    var center = CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(center)

    var vbox = VBoxContainer.new()
    center.add_child(vbox)

    var label = Label.new()
    label.text = "YOU WON THE TOURNAMENT"
    label.add_theme_font_size_override("font_size", 64)
    vbox.add_child(label)

    var btn = Button.new()
    btn.text = "Return to Menu"
    btn.pressed.connect(func():
        Engine.time_scale = 1
        get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
    )
    vbox.add_child(btn)
    Engine.time_scale = 0

func show_loss_popup():
    var canvas = CanvasLayer.new()
    canvas.layer = 100
    add_child(canvas)

    var overlay = ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.8)
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(overlay)

    var center_box = CenterContainer.new()
    center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(center_box)

    var vbox = VBoxContainer.new()
    center_box.add_child(vbox)

    var result_label = Label.new()
    result_label.text = "YOU LOST"
    result_label.add_theme_font_size_override("font_size", 64)
    vbox.add_child(result_label)

    var continue_btn = Button.new()
    continue_btn.text = "Return to Menu"
    continue_btn.custom_minimum_size = Vector2(200, 60)
    continue_btn.pressed.connect(func():
        Engine.time_scale = 1
        get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
    )
    vbox.add_child(continue_btn)
    Engine.time_scale = 0

func show_win_popup():
    var canvas = CanvasLayer.new()
    canvas.layer = 100
    add_child(canvas)
    
    var overlay = ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.8)
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(overlay)
    
    var center_box = CenterContainer.new()
    center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(center_box)
    
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 20)
    center_box.add_child(vbox)
    
    var result_label = Label.new()
    result_label.text = "YOU WON"
    result_label.add_theme_font_size_override("font_size", 64)
    vbox.add_child(result_label)
    
    var continue_btn = Button.new()
    continue_btn.text = "Continue"
    continue_btn.custom_minimum_size = Vector2(200, 60)
    continue_btn.pressed.connect(_on_continue_pressed)
    vbox.add_child(continue_btn)
    Engine.time_scale = 0

func _on_continue_pressed():
    Engine.time_scale = 1
    # Go to store if won, otherwise return to menu
    get_tree().change_scene_to_file("res://Scenes/Store.tscn")
