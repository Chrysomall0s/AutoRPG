# MapTile.gd
class_name MapTile
extends Node2D

signal tile_clicked(tile: MapTile)

# Clear tracking of tile types including our progression gates
enum TileType { NORMAL, MONSTER, SHOP, STAIRWELL }

var tile_id: int
var tile_type: TileType = TileType.NORMAL
var connected_tiles: Array[int] = []

# The clickable radius around the center of this tile (in pixels)
const CLICK_RADIUS: float = 60.0 

func set_tile_type(type: TileType) -> void:
	tile_type = type
	
	# Visual helper so you can distinguish tiles during development
	match tile_type:
		TileType.MONSTER:
			modulate = Color.RED      # Red for danger/combat zones
		TileType.SHOP:
			modulate = Color.GOLD     # Gold/Yellow for shops
		TileType.STAIRWELL:
			modulate = Color.PURPLE   # Purple for progressive exit stairwells
		TileType.NORMAL:
			modulate = Color.WHITE    # Default safe tile color

func _unhandled_input(event: InputEvent) -> void:
	# Works flawlessly across both desktop mouse and mobile screens
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# Calculate distance between mouse click and the local center of this node
		var local_mouse_pos = get_local_mouse_position()
		
		# If the click happens within this tile's circular hit boundary, capture it
		if local_mouse_pos.length() <= CLICK_RADIUS:
			print("FORCE DETECTED: Clicked Tile ID: ", tile_id)
			tile_clicked.emit(self)
