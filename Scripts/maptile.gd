# MapTile.gd
extends Area2D
class_name MapTile

# Define a custom signal that passes this tile as a parameter
signal tile_clicked(clicked_tile: MapTile)

@export var tile_id: int
@export var tile_type: String = "Normal"

var connected_tiles: Array[int] = []

func _ready():
	input_pickable = true
	input_event.connect(_on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Safely emit the signal to whoever is listening
		tile_clicked.emit(self)
