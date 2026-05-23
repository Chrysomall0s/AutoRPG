# =================================================================
# res://Scenes/Hero.gd
# =================================================================
extends Sprite2D # Or Sprite2D, depending on your original Hero node type

@onready var layers = $UpgradeLayers

func _ready() -> void:
	load_upgrade_sprites()

func load_upgrade_sprites() -> void:
	# Clear any editor placeholder visuals safely
	for child in layers.get_children():
		child.queue_free()

	# Process owned upgrades
	for upgrade in GameManager.owned_upgrades:
		if not upgrade or not upgrade.has("icon"):
			continue

		var sprite = Sprite2D.new()
		sprite.texture = load(upgrade["icon"])
		sprite.name = upgrade["name"]

		if upgrade.has("layer"):
			sprite.z_index = upgrade["layer"]

		layers.add_child(sprite)
	
	# Process equipped slots
	for slot_name in GameManager.equipped_slots:
		var upgrade = GameManager.equipped_slots[slot_name]

		if not upgrade or not upgrade.has("icon"):
			continue

		var sprite = Sprite2D.new()
		var icon_suffix = upgrade["icon"]
		
		match slot_name:
			"Left":
				icon_suffix += "/L.png"
			"Middle":
				icon_suffix += "/M.png"
			"Right":
				icon_suffix += "/R.png"
				
		sprite.texture = load(icon_suffix)
		sprite.name = upgrade["name"]

		if upgrade.has("layer"):
			sprite.z_index = upgrade["layer"]

		layers.add_child(sprite)
