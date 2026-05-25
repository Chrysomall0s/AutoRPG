# MapTile.gd
class_name MapTile
extends Node2D

signal tile_clicked(tile: MapTile)

enum TileType { NORMAL, MONSTER, SHOP, STAIRWELL }

var tile_id: int
var tile_type: TileType = TileType.NORMAL
var connected_tiles: Array[int] = []

func set_tile_type(type: TileType) -> void:
	tile_type = type
	
	match tile_type:
		TileType.MONSTER: modulate = Color.RED
		TileType.SHOP: modulate = Color.GOLD
		TileType.STAIRWELL: modulate = Color.PURPLE
		TileType.NORMAL: modulate = Color.WHITE

# This function will be called directly by your Area2D child node
func handle_click() -> void:
	print("POLYGON DETECTED: Clicked Tile ID: ", tile_id)
	tile_clicked.emit(self)


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# Stop input from leaking to elements behind this tile
		get_viewport().set_input_as_handled() 
		handle_click()
