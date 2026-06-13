extends Sprite2D

var outline_shader = preload("res://Assets/shaders/outline_shader.gdshader")

@onready var layers: Node2D = $UpgradeLayers
var health_bar: ProgressBar = null

@export_group("Floating Rainbow Settings")
@export var rainbow_radius_x: float = 150.0
@export var rainbow_radius_y: float = 150.0
@export var rainbow_offset: Vector2 = Vector2(0, 0)
@export var rainbow_y_offset: float = -100.0
@export var float_amplitude: float = 4.0
@export var float_wave_speed: float = 2.5
@export var weapon_follow_smoothness: float = 8.0

var weapon_sprites: Array[Sprite2D] = []
var floating_time := 0.0

func _find_upgrade_by_name(target_name: String) -> Dictionary:
    for upgrade in UpgradeData.upgrades:
        if upgrade["name"] == target_name: return upgrade
    return {}

#func _ready() -> void:

func draw_health(target: Dictionary):

    if not health_bar:
        health_bar = ProgressBar.new()
        health_bar.size = Vector2(100, 20)
        health_bar.position = Vector2(-50, 150)
        health_bar.z_index = 4096

        var style_bg = StyleBoxFlat.new()
        style_bg.bg_color = Color.BLACK
        health_bar.add_theme_stylebox_override("background", style_bg)

        var style_fg = StyleBoxFlat.new()
        style_fg.bg_color = Color.GREEN
        health_bar.add_theme_stylebox_override("fill", style_fg)

        add_child(health_bar)

    health_bar.max_value = GameManager.getpassive3("MAXHP",target)
    health_bar.value = GameManager.getpassive3("HP",target)

func spawn_weapons(weapon_data_array: Array):
    weapon_sprites.clear()
    for child in get_children():
        if child.has_meta("slot_index"): child.queue_free()
        
    for i in range(weapon_data_array.size()):
        var data = weapon_data_array[i]
        if not data: continue
        
        var weapon_info = _find_upgrade_by_name(data) if data is String else data
        if weapon_info.is_empty(): continue

        # Reuse the helper function
        var weapon = GameManager._create_weapon_sprite(weapon_info)
        
        # Set slot-specific meta and store
        weapon.set_meta("slot_index", i)
        add_child(weapon)
        weapon_sprites.append(weapon)

# Inside Hero.gd
func activate_battle_mode():
    for weapon in weapon_sprites:
        if weapon.material is ShaderMaterial:
            weapon.material.set_shader_parameter("use_charge_shader", true)
            
func update_weapon_movements(delta: float, _player_pos: Vector2):
    floating_time += delta
    for i in range(weapon_sprites.size()):
        var weapon = weapon_sprites[i]
        if weapon.get_meta("is_attacking", false): continue
        
        var slot_idx = weapon.get_meta("slot_index")
        var angle = float(slot_idx) * (PI / 5.0)
        var float_off = sin(floating_time * float_wave_speed + slot_idx) * float_amplitude
        
        var target = rainbow_offset + Vector2(
            -cos(angle) * rainbow_radius_x, 
            -sin(angle) * rainbow_radius_y + rainbow_y_offset + float_off
        )
        weapon.position = weapon.position.lerp(target, delta * weapon_follow_smoothness)

func attack_target(weapon: Sprite2D, target_pos: Vector2, duration: float):
    weapon.set_meta("is_attacking", true)
    var local_target = to_local(target_pos)
    var tween = create_tween()
    tween.tween_property(weapon, "position", local_target, duration).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(weapon, "position", weapon.get_meta("original_pos", Vector2.ZERO), duration).set_ease(Tween.EASE_OUT)
    tween.finished.connect(func(): weapon.set_meta("is_attacking", false))

func ValueToLevel(profile: Dictionary):
    # Ensure the profile has a "passives" array before trying to iterate
    if not profile.has("passives"):
        return

    # Iterate through the passives array
    for passive in profile["passives"]:
        # Safety check: ensure the item is a dictionary and has both required keys
        if passive is Dictionary:
            if passive.has("level") and passive.has("value"):
                # Set the 'value' to the current 'level'
                passive["value"] = passive["level"]
                
                # Optional: print for debugging
                # print("Updated ", passive.get("name", "unknown"), " value to: ", passive["level"])
    

func refresh_character_and_weapons(profile: Dictionary):
    ValueToLevel(profile)
    if profile.get("icon") != null:
        var texture_path = profile["icon"]
        if ResourceLoader.exists(texture_path):
            self.texture = load(texture_path)
            self.hframes = 4
            self.vframes = 4
            self.frame = profile.get("index", 0) # Default to 0 if "index" is missing
        else:
            push_error("Texture not found at: " + texture_path)
        
    # Since this function is now inside the Hero script, 
    # you can call these methods directly
    load_upgrade_sprites(profile)
    spawn_weapons(profile["weapons"])
    


func load_upgrade_sprites(profile: Dictionary) -> void:
    # Clear existing icons
    for child in layers.get_children():
        child.queue_free()

    var passives = profile.get("passives", [])
    var count = 0
    
    # --- ADDED: Load UpgradeData to resolve names ---
    # -------------------------------------------------

    for item in passives:
        # Resolve string to full dictionary if necessary
        var upgrade = item
        if upgrade is String:
            for data in UpgradeData.upgrades:
                if data["name"] == upgrade:
                    upgrade = data
                    break
        
        # Now 'upgrade' is a dictionary (if found)
        if upgrade is Dictionary and upgrade.has("icon"):
            var sprite = Sprite2D.new()
            
            # --- APPLY SHADER ---
            var mat = ShaderMaterial.new()
            mat.shader = outline_shader
            mat.set_shader_parameter("level", float(upgrade.get("level", 1.0)))
            sprite.material = mat
            # --------------------
            
            var icon_path = upgrade["icon"]
            if ResourceLoader.exists(icon_path):
                var atlas = load(icon_path).duplicate()
                var index = upgrade.get("index", 0)
                var tile_size = Vector2(250, 250)
                
                atlas.region = Rect2(Vector2((index % 4) * tile_size.x, (index / 4) * tile_size.y), tile_size)
                sprite.texture = atlas
                sprite.scale = Vector2(0.2, 0.2)
                
                var row = count / 5
                var col = count % 5
                sprite.position = Vector2(-80, 150) + Vector2(col * 40.0, row * 40.0)
                
                if upgrade.has("layer"):
                    sprite.z_index = clamp(upgrade["layer"], -4096, 4096)
                
                layers.add_child(sprite)
                count += 1
