# =================================================================
# res://Scenes/MapTile.gd
# =================================================================
extends Area2D

# Configurable paths to your visual assets
const NORMAL_TILE_TEXTURE = "res://Assets/tiles/tile.png" 
const STAIRS_TILE_TEXTURE = "res://Assets/tiles/down.png" 

@export var tile_id: int
var tile_type: int = 0 
var connected_tiles: Array = []

signal tile_clicked(tile)

var monster_container: Node2D = null
var monster_sprite: Sprite2D = null

func _ready():
	_ensure_container_exists()

func _ensure_container_exists():
	if has_node("MonsterContainer"):
		monster_container = get_node("MonsterContainer") as Node2D
		monster_container.z_index = 2 # <-- FORCE existing containers to draw on top!
		if monster_container.has_node("MonsterSprite"):
			monster_sprite = monster_container.get_node("MonsterSprite") as Sprite2D
			return

	if not monster_container:
		monster_container = Node2D.new()
		monster_container.name = "MonsterContainer"
		monster_container.position = Vector2(0, -60)
		monster_container.z_index = 2 # <-- FORCE newly created containers to draw on top!
		add_child(monster_container)
		
	if not monster_sprite:
		monster_sprite = Sprite2D.new()
		monster_sprite.name = "MonsterSprite"
		monster_container.add_child(monster_sprite)

func set_tile_type(type: int):
	tile_type = type
	_ensure_container_exists()
	
	if monster_container:
		monster_container.visible = (type == 1) # 1 = TileType.MONSTER
	
	# Direct node extraction to bypass any @onready engine timing limitations
	var tile_sprite = get_node_or_null("Sprite2D") as Sprite2D
	
	if tile_sprite:
		if type == 2: # 2 = TileType.STAIRWELL
			if ResourceLoader.exists(STAIRS_TILE_TEXTURE):
				tile_sprite.texture = load(STAIRS_TILE_TEXTURE)
		else:
			if ResourceLoader.exists(NORMAL_TILE_TEXTURE):
				tile_sprite.texture = load(NORMAL_TILE_TEXTURE)

func display_monster(texture_path: String, custom_scale: Vector2 = Vector2(0.4, 0.4)):
	_ensure_container_exists()
	
	if not monster_sprite:
		return
		
	if ResourceLoader.exists(texture_path):
		monster_sprite.texture = load(texture_path)
		monster_sprite.scale = custom_scale
		if monster_container:
			monster_container.visible = true
	else:
		print("Warning: Monster asset path not found: ", texture_path)
		if monster_container:
			monster_container.visible = false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_clicked.emit(self)
