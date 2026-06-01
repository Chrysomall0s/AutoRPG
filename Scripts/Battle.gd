extends Control

const TimeController = preload("res://Scripts/time.gd")
var time_ctrl = TimeController.new()

# =================================================================
# SETTINGS & REFERENCES
# =================================================================
@onready var player_sprite = $Hero 
@onready var enemy_sprite = $Foe
@onready var audience_container = $AudienceContainer

var battle_over := false
var won := false

# =================================================================
# INITIALIZATION
# =================================================================
func _ready():
    add_child(time_ctrl)
    time_ctrl.setup_time_controls(self, 0.06, 0.02, 0.24, 0.15, 0.07)
    
    var screen_size = get_viewport_rect().size
    player_sprite.position = Vector2(screen_size.x * 0.25, screen_size.y * 0.3)
    enemy_sprite.position = Vector2(screen_size.x * 0.75, screen_size.y * 0.3)
    
    if player_sprite.has_method("spawn_weapons"):
        player_sprite.spawn_weapons(GameManager.player_profile.get("weapons", []))
    if enemy_sprite.has_method("spawn_weapons"):
        enemy_sprite.spawn_weapons(GameManager.current_enemy_profile.get("weapons", []))
        
    if audience_container.has_method("populate_audience"):
        audience_container.populate_audience()

# =================================================================
# MAIN LOOP
# =================================================================
func _process(delta):
    if battle_over: return
    
    # 1. Update Floating Animations
    player_sprite.update_weapon_movements(delta, player_sprite.position)
    enemy_sprite.update_weapon_movements(delta, enemy_sprite.position)
    
    # 2. Combat Resolution
    _process_combat_ticks(player_sprite, enemy_sprite, delta)
    _process_combat_ticks(enemy_sprite, player_sprite, delta)
    
    # 3. Draw Health
    player_sprite.draw_health(GameManager.player_hp, GameManager.max_player_hp)
    enemy_sprite.draw_health(GameManager.enemy_hp, GameManager.max_enemy_hp)
    
    if GameManager.enemy_hp <= 0 or GameManager.player_hp <= 0:
        check_game_state()

func _process_combat_ticks(attacker_node, target_node, delta):
    for weapon in attacker_node.weapon_sprites:
        if weapon.get_meta("is_attacking", false): continue
        
        # Decrement local timer
        var timer = weapon.get_meta("cooldown_timer") - delta
        
        if timer <= 0:
            var type = weapon.get_meta("weapon_type", "damage")
            var damage = weapon.get_meta("damage", 10)
            
            if type == "heal":
                # Heal logic
                attacker_node.attack_target(weapon, attacker_node.global_position + Vector2(0, -50), 0.2)
                if attacker_node == player_sprite:
                    GameManager.player_hp = min(GameManager.player_hp + damage, GameManager.max_player_hp)
                else:
                    GameManager.enemy_hp = min(GameManager.enemy_hp + damage, GameManager.max_enemy_hp)
            else:
                # Damage logic
                attacker_node.attack_target(weapon, target_node.global_position, 0.2)
                if attacker_node == player_sprite:
                    GameManager.enemy_hp -= damage
                else:
                    GameManager.player_hp -= damage
            
            # Reset to fixed interval (calculated in spawn_weapons)
            timer = weapon.get_meta("cooldown_max")
            
        weapon.set_meta("cooldown_timer", timer)

# =================================================================
# GAME STATE
# =================================================================
func check_game_state():
    if battle_over: return
    battle_over = true
    won = GameManager.enemy_hp <= 0
    show_win_popup()

func show_win_popup():
    # 1. Use a CanvasLayer to ensure the UI is drawn on top of EVERYTHING
    # and is not affected by camera movement or node positions.
    var canvas = CanvasLayer.new()
    canvas.layer = 100 # Ensure it's on the top layer
    add_child(canvas)
    
    # 2. Create the full-screen overlay inside the CanvasLayer
    var overlay = ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.8)
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(overlay)
    
    # 3. Create a CenterContainer to force content to the middle
    var center_box = CenterContainer.new()
    center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(center_box)
    
    # 4. Create VBoxContainer for layout
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 20)
    center_box.add_child(vbox)
    
    # 5. Create Label and Button
    var result_label = Label.new()
    result_label.text = "YOU WON" if won else "YOU LOST"
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
    if won:
        # Go to store if won
        get_tree().change_scene_to_file("res://Scenes/Store.tscn")
    else:
        # Go to main menu if lost
        get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
