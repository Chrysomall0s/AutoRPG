extends Node

@export_group("Button Layout Settings")
@export var x_gap_ratio: float = 0.05
@export var y_gap_ratio: float = -0.07
@export var button_w_ratio: float = 0.08
@export var button_h_ratio: float = 0.08
@export var base_y_offset: float = 0.0
@export var base_x_offset: float = 0.05

var atlas_tex: Texture2D = preload("res://Assets/atlas/settings.tres")
var atlas_tex2: Texture2D = preload("res://Assets/atlas/icon2.tres")
# =================================================================
# PUBLIC API
# =================================================================

# Update the public API to support 5 buttons
func create_time_buttons(parent: Control):
    _generate_row(parent, 0, [0, 1, 2, 3, 4], ["Pause", "Slow", "Normal", "Fast", "Extra"])

func create_difficulty_buttons(parent: Control):
    _generate_row(parent, 1, [4, 5, 6, 7, 16], ["Easy", "Normal", "Hard", "Insane", "Impossible"])

func create_shop_buttons(parent: Control):
    _generate_row(parent, 2, [19, 20, 21, 22, 23], ["Reroll", "", "", "", "Go"])
# Update the lookup function
func _get_callback_for_row(row: int, index: int) -> Callable:
    if row == 0:
        var funcs = [pausespeed, slowspeed, normalspeed, fastspeed, extraspeed]
        return funcs[index]
    elif row == 1:
        var funcs = [easydifficulty, normaldifficulty, harddifficulty, insanedifficulty, impossibledifficulty]
        return funcs[index]
    else: # Row 2 (Shop)
        var funcs = [reroll_shop, buy_item_one, buy_item_two, buy_item_three, go_to_battle]
        return funcs[index]

# New callbacks
func extraspeed(): _on_surrender_pressed()
func impossibledifficulty(): _on_play_pressed()

#func create_time_buttons(parent: Control):
    #_generate_row(parent, 0, 0, ["Pause", "Slow", "Normal", "Fast"])
#
#func create_difficulty_buttons(parent: Control):
    #_generate_row(parent, 1, 4, ["Easy", "Normal", "Hard", "Insane"])

# =================================================================
# INTERNAL LOGIC
# =================================================================

func _generate_row(parent: Control, row_index: int, atlas_indices: Array, labels: Array):
    var screen = parent.get_viewport_rect().size
    var num_buttons = labels.size()
    
    # 1. Calculate the width of one gap (based on x_gap_ratio)
    var gap_width = screen.x * x_gap_ratio
    
    # 2. Calculate available width after subtracting all gaps
    # We want gaps at start, between buttons, and at the end (total = num_buttons + 1)
    var total_gap_width = gap_width * (num_buttons + 1)
    var available_width = screen.x - total_gap_width
    
    # 3. Calculate button width
    var btn_w = available_width / num_buttons
    var btn_h = screen.y * button_h_ratio
    
    var y_pos = (row_index * (btn_h + (screen.y * y_gap_ratio))) + (screen.y * base_y_offset)
    
    var group = ButtonGroup.new()
    
    for i in range(num_buttons):
            var x_pos = gap_width + (i * (btn_w + gap_width))
            
            # Use the array index instead of adding 'i' to a start index
            var current_atlas_index = atlas_indices[i] 
            
            var btn = _create_btn(parent, labels[i], row_index, i, Vector2(x_pos, y_pos), current_atlas_index, group)
            btn.custom_minimum_size = Vector2(btn_w, btn_h)
            if i == 1: btn.button_pressed = true

func _create_btn(parent: Control, text: String, row: int, index: int, pos: Vector2, atlas_index: int, group: ButtonGroup) -> Button:
    var screen_size = parent.get_viewport_rect().size
    var btn = Button.new()
    
    var empty_style = StyleBoxEmpty.new()
    btn.add_theme_stylebox_override("normal", empty_style)
    btn.add_theme_stylebox_override("hover", empty_style)
    btn.add_theme_stylebox_override("pressed", empty_style)
    btn.add_theme_stylebox_override("focus", empty_style) # Removes the outline box when selected
    btn.add_theme_stylebox_override("disabled", empty_style)
    
    btn.toggle_mode = true
    btn.button_group = group
    btn.custom_minimum_size = Vector2(screen_size.x * button_w_ratio, screen_size.y * button_h_ratio)
    btn.position = pos
    parent.add_child(btn)

    var sprite = TextureRect.new()
    sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
    # Force texture to fit the button and stay centered
    sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    sprite.texture = _create_atlas_frame(atlas_index)
    btn.add_child(sprite)

    var label = Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.position = Vector2(0, btn.custom_minimum_size.y * 0.7)
    label.size.x = btn.custom_minimum_size.x
    label.add_theme_font_size_override("font_size", int(screen_size.y * 0.015))
    btn.add_child(label)

    btn.toggled.connect(func(toggled_on):
        sprite.texture = _create_atlas_frame(atlas_index + (8 if toggled_on else 0))
        if toggled_on: _get_callback_for_row(row, index).call()
    )
    return btn

# Callback functions
func pausespeed(): Engine.time_scale = 0.0
func slowspeed(): Engine.time_scale = 0.5
func normalspeed(): Engine.time_scale = 2.0
func fastspeed(): Engine.time_scale = 8.0
func easydifficulty(): GameManager.selected_difficulty = 0
func normaldifficulty(): GameManager.selected_difficulty = 0
func harddifficulty(): GameManager.selected_difficulty = 0
func insanedifficulty(): GameManager.selected_difficulty = 0
func reroll_shop(): 
    GameManager.Reroll() 
    var hero = get_tree().current_scene.find_child("Hero", true, false)
    
    if hero and hero.has_method("refresh_character_and_weapons"):
        hero.refresh_character_and_weapons(GameManager.player_profile)
    else:
        print("Hero node not found or missing refresh method")
func buy_item_one(): print("Buying slot 1...")
func buy_item_two(): print("Buying slot 2...")
func buy_item_three(): print("Buying slot 3...")
func go_to_battle(): _play()

func _play():
    var diff_key = GameManager.get_difficulty_key() # or logic to choose "easy", "normal", etc.
    
    # Returns an Array: [monster1_dict, monster2_dict, monster3_dict]
    GameManager.current_enemy_profile = MonsterData.get_monster(diff_key, GameManager.currentRound)
    GameManager.currentRound += 1
    
    # Store the entire wave in the manager
    get_tree().change_scene_to_file("res://Scenes/Battle.tscn")

func _on_play_pressed():
     # Double check that a character is actually selected

        if GameManager.selectedCharacter != -1:

            GameManager.currentRound = 0

            get_tree().change_scene_to_file("res://Scenes/Store.tscn")

        else:

            print("Action blocked: No character selected.") 

func _on_surrender_pressed():
    # Ensure 'battle_over' is defined in this script
    if get("battle_over") == true: return
    
    GameManager.battle_over = true
    GameManager.go_to_after_battle("lose")

func _create_atlas_frame(index: int) -> AtlasTexture:
    var atlas = AtlasTexture.new()
    
    # Logic: If index is 8 or higher, subtract 8 to reset range 
    # and use atlas_tex2 instead of atlas_tex
    if index >= 16:
        atlas.atlas = atlas_tex2
        index -= 16
    else:
        atlas.atlas = atlas_tex
        
    var region_size = 250
    # Calculates X and Y coordinates based on the adjusted index
    atlas.region = Rect2(
        Vector2((index % 4) * region_size, (index / 4) * region_size), 
        Vector2(region_size, region_size)
    )
    return atlas
