# =================================================================
# res://Scenes/Hero.gd
# =================================================================
extends Sprite2D

@onready var layers: Node2D = $UpgradeLayers

func _ready() -> void:
	load_upgrade_sprites()

func load_upgrade_sprites() -> void:
	# Clean up existing sprites safely
	for child in layers.get_children():
		layers.remove_child(child) # Instantly detach so get_children() reflects a clean slate immediately
		child.queue_free()         # Safely delete from memory at the end of the frame

	# Process general owned passive upgrades (Armor, Boots, Capes, etc.)
	if "owned_upgrades" in GameManager and GameManager.owned_upgrades:
		for upgrade in GameManager.owned_upgrades:
			# Safety check to ensure it's a valid data entry
			if not upgrade or not upgrade.has("icon") or not upgrade.has("name"):
				continue
			
			# OPTIONAL CHOP: If you track "is_equip" for weapons in your upgrades database, 
			# we can skip them here so they don't get glued to the hero's body texturing.
			if upgrade.get("is_equip", false) == true:
				continue

			# Ensure the asset path is valid before trying to load it
			if ResourceLoader.exists(upgrade["icon"]):
				var sprite = Sprite2D.new()
				sprite.texture = load(upgrade["icon"])
				sprite.name = upgrade["name"]

				# Stack the visuals correctly (e.g., cape behind body, armor in front)
				if upgrade.has("layer"):
					sprite.z_index = clamp(upgrade["layer"], -4096, 4096)

				layers.add_child(sprite)
			else:
				push_warning("Failed to load general upgrade texture at: " + upgrade["icon"])
