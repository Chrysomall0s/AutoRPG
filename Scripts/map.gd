# Map.gd
extends Node2D

const TILE_SCENE = preload("res://Scenes/MapTile.tscn")
const BRIDGE_SCENE = preload("res://Scenes/MapBridge.tscn")

# CHANGED: Flipped Y to negative so the player is shifted higher up, not lower down
const PLAYER_OFFSET: Vector2 = Vector2(0, -150)

@onready var player_token = $Hero 

# Grid Layout / Spacing Configurations
const TILE_X_SPACING: float = 540.0 
const TILE_Y_SPACING: float = 210.0  
const ROW_X_OFFSET: float = 300.0    
const GRID_OFFSET: Vector2 = Vector2(180, 1200)

var tiles: Dictionary = {}

# Intercept positional modifications and pipe them directly into GameManager memory
var current_tile_id: int:
	get:
		if "current_tile_id" in GameManager:
			return GameManager.current_tile_id
		return 4
	set(value):
		if "current_tile_id" in GameManager:
			GameManager.current_tile_id = value

# Maps your 12 tiles to your exact ASCII layout map (Column, Row)
var tile_layout: Dictionary = {
	1: Vector2i(0, 0), 2: Vector2i(1, 0),
	3: Vector2i(0, 1), 4: Vector2i(1, 1), 5: Vector2i(2, 1),
	6: Vector2i(0, 2), 7: Vector2i(1, 2),
	8: Vector2i(0, 3), 9: Vector2i(1, 3), 10: Vector2i(2, 3),
	11: Vector2i(0, 4), 12: Vector2i(1, 4)
}

# Node classifications setup
var tile_assignments: Dictionary = {
	3: MapTile.TileType.MONSTER,
	5: MapTile.TileType.SHOP,
	7: MapTile.TileType.MONSTER,
	10: MapTile.TileType.MONSTER,
	11: MapTile.TileType.STAIRWELL, # Progressive transition node
	12: MapTile.TileType.SHOP
}

# The 16 connections between staggered grid coordinates
var bridge_definitions: Array = [
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

func _ready():
	var display_floor = 1
	if "current_floor" in GameManager:
		display_floor = GameManager.current_floor
	print("--- NOW ENTERING FLOOR ", display_floor, " ---")
	
	# FIRST: Generate all tiles so they are drawn in the background
	generate_map()
	
	# SECOND: Spawn all bridges so they render on top of the tiles
	spawn_and_connect_bridges()
	
	snap_player_to_tile(current_tile_id)
	
	# FINALLY: Keep player token above both tiles and bridges
	if player_token:
		move_child(player_token, get_child_count() - 1)

func generate_map():
	for tile_id in tile_layout:
		var grid_pos = tile_layout[tile_id]
		var x_pos = grid_pos.x * TILE_X_SPACING
		
		if grid_pos.y % 2 == 0:
			x_pos += ROW_X_OFFSET
			
		var y_pos = grid_pos.y * TILE_Y_SPACING
		var pixel_position = Vector2(x_pos, y_pos) + GRID_OFFSET
		
		var new_tile = TILE_SCENE.instantiate() as MapTile
		new_tile.tile_id = tile_id
		new_tile.position = pixel_position
		new_tile.tile_clicked.connect(_on_tile_clicked)
		
		var is_cleared = "cleared_tiles" in GameManager and GameManager.cleared_tiles.has(tile_id)
		
		if is_cleared:
			new_tile.set_tile_type(MapTile.TileType.NORMAL)
		elif tile_assignments.has(tile_id):
			new_tile.set_tile_type(tile_assignments[tile_id])
		else:
			new_tile.set_tile_type(MapTile.TileType.NORMAL)
		
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
		
		if not bridge["visible"]:
			bridge_instance.visible = false
			continue
			
		tiles[t1].connected_tiles.append(t2)
		tiles[t2].connected_tiles.append(t1)

func _on_tile_clicked(clicked_tile: MapTile):
	if not tiles.has(current_tile_id): return
	var current_tile = tiles[current_tile_id]
	
	print("Attempting move: From Tile ", current_tile_id, " -> To Tile ", clicked_tile.tile_id)
	
	if clicked_tile.tile_id == current_tile_id:
		print("Action Denied: You are already standing on Tile ", clicked_tile.tile_id)
		return

	if clicked_tile.tile_id in current_tile.connected_tiles:
		move_player_to_tile(clicked_tile)
	else:
		print("Can't move! No open bridge connects Tile ", current_tile_id, " to Tile ", clicked_tile.tile_id)

func move_player_to_tile(target_tile: MapTile):
	current_tile_id = target_tile.tile_id 
	var tween = create_tween()
	
	# CHANGED: Added PLAYER_OFFSET here so the move tween targets the shifted location
	var target_position = target_tile.position + PLAYER_OFFSET
	tween.tween_property(player_token, "position", target_position, 0.25)
	
	await tween.finished
	handle_tile_event(target_tile.tile_type)

func snap_player_to_tile(tile_id: int):
	if tiles.has(tile_id):
		# CHANGED: Uses corrected PascalCase constant naming convention
		player_token.position = tiles[tile_id].position + PLAYER_OFFSET

func handle_tile_event(type: MapTile.TileType):
	match type:
		MapTile.TileType.MONSTER:
			print("Encountered a Monster! Loading Battle Scene...")
			get_tree().change_scene_to_file("res://Scenes/Battle.tscn")
			
		MapTile.TileType.SHOP:
			print("Entering the merchant shop...")
			get_tree().change_scene_to_file("res://Scenes/Store.tscn")
			
		MapTile.TileType.STAIRWELL:
			print("Climbing the stairs to the next floor...")
			if GameManager.has_method("advance_to_next_floor"):
				GameManager.advance_to_next_floor()
			get_tree().reload_current_scene()
			
		MapTile.TileType.NORMAL:
			print("Arrived safely on a standard layout tile.")
