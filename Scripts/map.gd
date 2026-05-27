# =================================================================
# res://Scenes/Map.gd
# =================================================================
extends Node2D

const TILE_SCENE = preload("res://Scenes/maptile.tscn")
const BRIDGE_SCENE = preload("res://Scenes/mapbridge.tscn")
const MapTileScript = preload("res://Scenes/maptile.tscn")

const PLAYER_OFFSET: Vector2 = Vector2(0, -150)

@onready var player_token = $Hero 
@onready var shop_button = $CanvasLayer/ShopButton

var floor_label: Label

const TILE_X_SPACING: float = 540.0 
const TILE_Y_SPACING: float = 210.0  
const ROW_X_OFFSET: float = 300.0    

# CHANGED: We remove the hardcoded 1200 Y pixel value and calculate it dynamically
var grid_offset: Vector2 = Vector2.ZERO

var tiles: Dictionary = {}
var spawned_bridge_nodes: Array = [] 

enum TileType { NORMAL, MONSTER, STAIRWELL }

var current_tile_id: int:
	get:
		return GameManager.current_tile_id
	set(value):
		GameManager.current_tile_id = value

var tile_layout: Dictionary = {
	1: Vector2i(0, 0), 2: Vector2i(1, 0),
	3: Vector2i(0, 1), 4: Vector2i(1, 1), 5: Vector2i(2, 1),
	6: Vector2i(0, 2), 7: Vector2i(1, 2),
	8: Vector2i(0, 3), 9: Vector2i(1, 3), 10: Vector2i(2, 3),
	11: Vector2i(0, 4), 12: Vector2i(1, 4)
}

var bridge_definitions: Array:
	get:
		return GameManager.persistent_bridge_definitions
	set(value):
		GameManager.persistent_bridge_definitions = value

var tile_assignments: Dictionary:
	get:
		return GameManager.persistent_tile_assignments
	set(value):
		GameManager.persistent_tile_assignments = value

func _ready():
	if shop_button:
		shop_button.pressed.connect(_on_shop_button_pressed)
	
	setup_floor_ui_label()
	calculate_dynamic_grid_offset() # NEW: Setup screen boundaries before drawing anything
	build_or_refresh_dungeon_floor()

func _on_shop_button_pressed():
	print("Opening persistent global shop scene...")
	get_tree().change_scene_to_file("res://Scenes/Store.tscn")

func setup_floor_ui_label():
	var ui_layer = get_node_or_null("CanvasLayer")
	if ui_layer:
		if ui_layer.has_node("FloorLabel"):
			floor_label = ui_layer.get_node("FloorLabel") as Label
		else:
			floor_label = Label.new()
			floor_label.name = "FloorLabel"
			if shop_button:
				floor_label.position = shop_button.position + Vector2(0, -50)
			else:
				floor_label.position = Vector2(40, 40)
			floor_label.add_theme_font_size_override("font_size", 32)
			ui_layer.add_child(floor_label)

# NEW: Calculates coordinates relative to the current device window size
func calculate_dynamic_grid_offset():
	var screen_size = get_viewport_rect().size
	var min_x = INF; var max_x = -INF
	var min_y = INF; var max_y = -INF
	
	# Iterate through all configured tiles to find the total bounds
	for tile_id in tile_layout:
		var pos = tile_layout[tile_id]
		# Apply the same logic as generate_map to find the exact position
		var x = pos.x * TILE_X_SPACING
		if pos.y % 2 == 0:
			x += ROW_X_OFFSET
		var y = pos.y * TILE_Y_SPACING
		
		min_x = min(min_x, x)
		max_x = max(max_x, x)
		min_y = min(min_y, y)
		max_y = max(max_y, y)
	
	# Calculate center of the bounds
	var grid_width = max_x - min_x
	var grid_height = max_y - min_y
	
	# Calculate the offset required to place that center at the center of the viewport
	var offset_x = (screen_size.x - grid_width) / 2.0 - min_x
	var offset_y = (screen_size.y - grid_height) / 2.0 - min_y
	
	grid_offset = Vector2(offset_x, offset_y)

func build_or_refresh_dungeon_floor():
	var display_floor = GameManager.current_floor
	print("--- NOW ENTERING FLOOR ", display_floor, " ---")
	
	if floor_label:
		floor_label.text = "FLOOR: " + str(display_floor)
	
	clear_current_map_nodes()
	
	if not GameManager.map_layout_initialized:
		initialize_base_bridge_blueprints()
		generate_random_layout()
		GameManager.map_layout_initialized = true
	
	generate_map()
	spawn_and_connect_bridges()
	snap_player_to_tile(current_tile_id)
	
	if player_token:
		move_child(player_token, get_child_count() - 1)

func initialize_base_bridge_blueprints():
	bridge_definitions = [
		{"id": 1,  "from": 1,  "to": 3,  "visible": true},
		{"id": 2,  "from": 1,  "to": 4,  "visible": true},
		{"id": 3,  "from": 2,  "to": 4,  "visible": true},
		{"id": 4,  "from": 2,  "to": 5,  "visible": true},
		{"id": 5,  "from": 3,  "to": 6,  "visible": true},
		{"id": 6,  "from": 4,  "to": 6,  "visible": true},
		{"id": 7,  "from": 4,  "to": 7,  "visible": true},
		{"id": 8,  "from": 5,  "to": 7,  "visible": true},
		{"id": 9,  "from": 6,  "to": 8,  "visible": true},   
		{"id": 10, "from": 6,  "to": 9,  "visible": true},   
		{"id": 11, "from": 7,  "to": 9,  "visible": true},   
		{"id": 12, "from": 7,  "to": 10, "visible": true},  
		{"id": 13, "from": 8,  "to": 11, "visible": true},
		{"id": 14, "from": 9,  "to": 11, "visible": true},
		{"id": 15, "from": 9,  "to": 12, "visible": true},
		{"id": 16, "to": 12, "from": 10, "visible": true},
	]

func clear_current_map_nodes():
	for tile_id in tiles:
		if is_instance_valid(tiles[tile_id]):
			tiles[tile_id].queue_free()
	tiles.clear()
	
	for bridge_node in spawned_bridge_nodes:
		if is_instance_valid(bridge_node):
			bridge_node.queue_free()
	spawned_bridge_nodes.clear()

func generate_random_layout():
	tile_assignments.clear()
	GameManager.persistent_monster_profiles.clear()
	var available_ids = tile_layout.keys()
	
	if current_tile_id not in available_ids:
		current_tile_id = available_ids[0]
		
	var start_grid_pos = tile_layout[current_tile_id]
	var loop_success = false
	var chosen_stairwell_tile = -1

	var attempts = 0
	while attempts < 2000: 
		attempts += 1
		for bridge in bridge_definitions:
			bridge["visible"] = randf() > 0.55
			
		if is_map_fully_connected():
			var connection_counts = {}
			for tile_id in available_ids:
				connection_counts[tile_id] = 0
			for bridge in bridge_definitions:
				if bridge["visible"]:
					connection_counts[bridge["from"]] += 1
					connection_counts[bridge["to"]] += 1
			
			var distant_candidates = []
			for tile_id in available_ids:
				if tile_id == current_tile_id:
					continue
				var grid_pos = tile_layout[tile_id]
				var dist = max(abs(grid_pos.x - start_grid_pos.x), abs(grid_pos.y - start_grid_pos.y))
				if dist >= 3:
					distant_candidates.append(tile_id)
			
			if distant_candidates.is_empty():
				continue 
				
			var absolute_dead_ends = []
			for tile_id in distant_candidates:
				if connection_counts[tile_id] == 1:
					absolute_dead_ends.append(tile_id)
					
			if not absolute_dead_ends.is_empty():
				chosen_stairwell_tile = absolute_dead_ends.pick_random()
			else:
				var min_connections = 99
				var best_alternatives = []
				for tile_id in distant_candidates:
					if connection_counts[tile_id] < min_connections:
						min_connections = connection_counts[tile_id]
						best_alternatives = [tile_id]
					elif connection_counts[tile_id] == min_connections:
						best_alternatives.append(tile_id)
				chosen_stairwell_tile = best_alternatives.pick_random()
				
			print("Valid procedural graph with functional stairwell assignment verified at Tile ", chosen_stairwell_tile, " in ", attempts, " loops.")
			loop_success = true
			break
			
	if not loop_success:
		print("Warning: Fallback absolute map connectivity forced.")
		for bridge in bridge_definitions:
			bridge["visible"] = true
		
		var distant_candidates = []
		for tile_id in available_ids:
			if tile_id != current_tile_id:
				var grid_pos = tile_layout[tile_id]
				if max(abs(grid_pos.x - start_grid_pos.x), abs(grid_pos.y - start_grid_pos.y)) >= 3:
					distant_candidates.append(tile_id)
		chosen_stairwell_tile = distant_candidates.pick_random() if not distant_candidates.is_empty() else available_ids[-1]

	tile_assignments[chosen_stairwell_tile] = TileType.STAIRWELL
	
	var candidate_monster_tiles: Array = []
	for tile_id in available_ids:
		if tile_id != chosen_stairwell_tile and tile_id != current_tile_id:
			candidate_monster_tiles.append(tile_id)
			
	candidate_monster_tiles.shuffle() 
	
	var target_monster_count = min(6, candidate_monster_tiles.size())
	
	for i in range(candidate_monster_tiles.size()):
		var tile_id = candidate_monster_tiles[i]
		if i < target_monster_count:
			tile_assignments[tile_id] = TileType.MONSTER
			if ResourceLoader.exists("res://Scripts/MonsterData.gd"):
				var monster_db = load("res://Scripts/MonsterData.gd").new()
				GameManager.persistent_monster_profiles[tile_id] = monster_db.get_random_monster()
		else:
			tile_assignments[tile_id] = TileType.NORMAL

func is_map_fully_connected() -> bool:
	var adjacency_list: Dictionary = {}
	for tile_id in tile_layout.keys():
		adjacency_list[tile_id] = []
		
	for bridge in bridge_definitions:
		if bridge["visible"]:
			adjacency_list[bridge["from"]].append(bridge["to"])
			adjacency_list[bridge["to"]].append(bridge["from"])
			
	var visited = {}
	var queue = [current_tile_id]
	visited[current_tile_id] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		for neighbor in adjacency_list[current]:
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.push_back(neighbor)
				
	return visited.size() == tile_layout.size()

func generate_map():
	for tile_id in tile_layout:
		var grid_pos = tile_layout[tile_id]
		var x_pos = grid_pos.x * TILE_X_SPACING
		
		if grid_pos.y % 2 == 0:
			x_pos += ROW_X_OFFSET
			
		var y_pos = grid_pos.y * TILE_Y_SPACING
		# CHANGED: Uses the dynamic runtime grid_offset variable now
		var pixel_position = Vector2(x_pos, y_pos) + grid_offset
		
		var new_tile = TILE_SCENE.instantiate()
		new_tile.tile_id = tile_id
		new_tile.position = pixel_position
		
		new_tile.connected_tiles.clear()
		new_tile.tile_clicked.connect(_on_tile_clicked)
		
		var is_cleared = GameManager.cleared_tiles.has(tile_id)
		
		if is_cleared:
			new_tile.set_tile_type(TileType.NORMAL)
		elif tile_assignments.has(tile_id):
			var assigned_type = tile_assignments[tile_id]
			new_tile.set_tile_type(assigned_type)
			
			if assigned_type == TileType.MONSTER:
				if not GameManager.persistent_monster_profiles.has(tile_id):
					var monster_db = load("res://Scripts/MonsterData.gd").new()
					GameManager.persistent_monster_profiles[tile_id] = monster_db.get_random_monster()
				
				var profile = GameManager.persistent_monster_profiles[tile_id]
				if profile.has("icon"):
					var icon_path = profile["icon"]
					if ResourceLoader.exists(icon_path):
						new_tile.display_monster(icon_path, Vector2(0.4, 0.4))
		else:
			new_tile.set_tile_type(TileType.NORMAL)
		
		add_child(new_tile)
		tiles[tile_id] = new_tile
		
		var label = Label.new()
		label.text = str(tile_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-12, -12)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		new_tile.add_child(label)

func spawn_and_connect_bridges():
	for bridge in bridge_definitions:
		var t1 = bridge["from"]
		var t2 = bridge["to"]
		if not (tiles.has(t1) and tiles.has(t2)): continue
			
		var pos_a = tiles[t1].position
		var pos_b = tiles[t2].position
		
		var bridge_instance = BRIDGE_SCENE.instantiate() as Node2D
		bridge_instance.name = "Bridge" + str(bridge["id"])
		bridge_instance.position = (pos_a + pos_b) / 2.0
		
		var is_mirrored = false
		if (pos_b.x > pos_a.x and pos_b.y < pos_a.y) or (pos_b.x < pos_a.x and pos_b.y > pos_a.y):
			is_mirrored = true
			
		if abs(pos_a.y - pos_b.y) < 5.0:
			is_mirrored = false
			
		if is_mirrored:
			bridge_instance.scale.x = -1.0
		else:
			bridge_instance.scale.x = 1.0

		add_child(bridge_instance)
		spawned_bridge_nodes.append(bridge_instance) 
		
		if not bridge["visible"]:
			bridge_instance.visible = false
			continue 
			
		tiles[t1].connected_tiles.append(t2)
		tiles[t2].connected_tiles.append(t1)

func _on_tile_clicked(clicked_tile: Node2D):
	if not tiles.has(current_tile_id): return
	var current_tile = tiles[current_tile_id]
	
	if clicked_tile.tile_id == current_tile_id:
		return

	if clicked_tile.tile_id in current_tile.connected_tiles:
		move_player_to_tile(clicked_tile)

func move_player_to_tile(target_tile: Node2D):
	current_tile_id = target_tile.tile_id 
	var tween = create_tween()
	var target_position = target_tile.position + PLAYER_OFFSET
	tween.tween_property(player_token, "position", target_position, 0.25)
	
	await tween.finished
	handle_tile_event(target_tile.tile_type)

func snap_player_to_tile(tile_id: int):
	if tiles.has(tile_id):
		player_token.position = tiles[tile_id].position + PLAYER_OFFSET

func handle_tile_event(type: int):
	match type:
		TileType.MONSTER:
			if GameManager.escaped:
				GameManager.escaped = false 

			if GameManager.cleared_tiles.has(current_tile_id):
				return

			if GameManager.persistent_monster_profiles.has(current_tile_id):
				var profile = GameManager.persistent_monster_profiles[current_tile_id]
				GameManager.current_enemy_profile = profile
				GameManager.max_enemy_hp = profile.get("hp", 50)
				GameManager.enemy_hp = profile.get("hp", 50)
				GameManager.enemy_dmg = profile.get("damage", 10)
				GameManager.enemy_speed = profile.get("speed", 4)
			
			get_tree().change_scene_to_file("res://Scenes/Battle.tscn")
			
		TileType.STAIRWELL:
			var preserved_spawn_tile_id = current_tile_id
			
			if GameManager.has_method("advance_to_next_floor"):
				GameManager.advance_to_next_floor()
				
			GameManager.cleared_tiles.clear()
			GameManager.map_layout_initialized = false
			
			current_tile_id = preserved_spawn_tile_id
			
			build_or_refresh_dungeon_floor()
