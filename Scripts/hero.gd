extends Sprite2D

@onready var layers: Node2D = $UpgradeLayers
var health_bar: ProgressBar = null

@export_group("Floating Rainbow Settings")
@export var rainbow_radius_x: float = 150.0
@export var rainbow_radius_y: float = 150.0
@export var rainbow_offset: Vector2 = Vector2(0, 0)
@export var rainbow_y_offset: float = 0.0
@export var float_amplitude: float = 4.0
@export var float_wave_speed: float = 2.5
@export var weapon_follow_smoothness: float = 8.0

var weapon_sprites: Array[Sprite2D] = []
var floating_time := 0.0

func _find_upgrade_by_name(target_name: String) -> Dictionary:
    var upgrade_data = preload("res://Scripts/UpgradeData.gd").new()
    for upgrade in upgrade_data.upgrades:
        if upgrade["name"] == target_name: return upgrade
    return {}

func _ready() -> void:
    load_upgrade_sprites()

func draw_health(current_hp: float, max_hp: float):
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
        
    health_bar.max_value = max_hp
    health_bar.value = current_hp

func spawn_weapons(weapon_data_array: Array):
    weapon_sprites.clear()
    for child in get_children():
        if child.has_meta("slot_index"): child.queue_free()
        
    for i in range(weapon_data_array.size()):
        var data = weapon_data_array[i]
        if not data: continue
        
        var weapon_info = data
        if weapon_info is String:
            weapon_info = _find_upgrade_by_name(weapon_info)
        if weapon_info.is_empty(): continue

        var weapon = Sprite2D.new()
        var icon_path = weapon_info.get("icon", "res://icon.svg")
        var atlas = load(icon_path).duplicate()
        
        var index = weapon_info.get("index", 0)
        var tile_size = Vector2(250, 250)
        atlas.region = Rect2(Vector2((index % 4) * tile_size.x, (index / 4) * tile_size.y), tile_size)
        
        weapon.texture = atlas
        add_child(weapon)
        
        # --- WEAPON METADATA ---
        var speed_val = weapon_info.get("speed", 3.0)
        var cooldown_duration = 1.0 / ((10.0 + speed_val) / 10.0)
        
        weapon.set_meta("slot_index", i)
        weapon.set_meta("weapon_type", weapon_info.get("type", "damage"))
        weapon.set_meta("damage", weapon_info.get("damage", 10))
        weapon.set_meta("cooldown_max", cooldown_duration)
        weapon.set_meta("cooldown_timer", randf_range(0.0, cooldown_duration))
        
        weapon_sprites.append(weapon)

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

func load_upgrade_sprites() -> void:
    for child in layers.get_children():
        layers.remove_child(child)
        child.queue_free()

    var passives = GameManager.player_profile.get("passives", [])
    for upgrade in passives:
        if upgrade.get("is_equip", false) == true: continue
        if upgrade.has("icon"):
            var sprite = Sprite2D.new()
            var icon_path = upgrade["icon"]
            if ResourceLoader.exists(icon_path):
                var atlas = load(icon_path).duplicate()
                var index = upgrade.get("index", 0)
                var tile_size = Vector2(250, 250)
                atlas.region = Rect2(Vector2((index % 4) * tile_size.x, (index / 4) * tile_size.y), tile_size)
                sprite.texture = atlas
                sprite.name = upgrade.get("name", "Upgrade")
                sprite.scale = Vector2(4, 4)
                sprite.position = Vector2(0, 250)
                if upgrade.has("layer"):
                    sprite.z_index = clamp(upgrade["layer"], -4096, 4096)
                layers.add_child(sprite)
