extends Node
var weapon_sprites: Array[Sprite2D] = []
var floating_time := 0.0



func spawn_weapons(parent: Node, player_sprite: Node2D, offset: Vector2, radius_x: float, radius_y: float, y_offset: float):
	for old in weapon_sprites: if is_instance_valid(old): old.queue_free()
	weapon_sprites.clear()
	for i in range(GameManager.equipped_weapons.size()):
		var data = GameManager.equipped_weapons[i]
		if data == null or typeof(data) != TYPE_DICTIONARY: continue
		var weapon = Sprite2D.new()
		weapon.texture = load(data.get("icon", "res://icon.svg"))
		weapon.scale = Vector2(0.3, 0.3)
		parent.add_child(weapon)
		weapon.set_meta("slot_index", i)
		weapon_sprites.append(weapon)

func update_positions(player_pos: Vector2, offset: Vector2, radius_x: float, radius_y: float, y_offset: float, delta: float):
	floating_time += delta
	for i in range(weapon_sprites.size()):
		var weapon = weapon_sprites[i]
		var slot_idx = weapon.get_meta("slot_index")
		var angle = float(slot_idx) * (PI / 5.0)
		var target = player_pos + offset + Vector2(-cos(angle) * radius_x, -sin(angle) * radius_y + y_offset)
		weapon.position = weapon.position.lerp(target, delta * 8.0)
