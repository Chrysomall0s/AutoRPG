extends Control

@export var statsbook_font_ratio: float = 0.02
@export var reference_height: float = 1080.0

var stats_container: VBoxContainer
var current_page_index: int = 0
var stat_pages = []

var stat_registry = {
    "hp": {"name": "Health", "group": "Health Stats", "iconatlas": "res://Assets/atlas/icon.tres", "iconindex": 1, "defaultValue": 12},
    "maxhp": {"name": "Max Health", "group": "Health Stats", "iconatlas": "res://Assets/atlas/icon.tres", "iconindex": 1, "defaultValue": 12},
    "mp": {"name": "Mana", "group": "Resources", "iconatlas": "res://Assets/atlas/icon.tres", "iconindex": 2, "defaultValue": 12},
    "maxmp": {"name": "Max Mana", "group": "Resources", "iconatlas": "res://Assets/atlas/icon.tres", "iconindex": 2, "defaultValue": 12},
    "dmg": {"name": "Damage", "group": "Combat Stats", "iconatlas": "res://Assets/atlas/icon.tres", "iconindex": 14, "defaultValue": 12},
}

func _ready():
    stats_container = VBoxContainer.new()
    add_child(stats_container)
    stats_container.set_anchors_preset(Control.PRESET_FULL_RECT)
    stats_container.add_theme_constant_override("separation", 10)
    
    get_viewport().size_changed.connect(refresh_stats)
    refresh_stats()

func refresh_stats():
    build_stat_pages()
    update_stats_display()

func build_stat_pages():
    var groups = {}
    var stats = GameManager.player_profile.get("stats", {})
    for key in stats.keys():
        var def = stat_registry.get(key, null)
        if def == null: continue
        var group_name = def["group"]
        if not groups.has(group_name): groups[group_name] = []
        groups[group_name].append(key)
    
    stat_pages.clear()
    for group_name in groups.keys():
        stat_pages.append({"title": group_name, "stats": groups[group_name]})

    var passives = GameManager.player_profile.get("passives", [])
    var passive_list = []
    for p in passives:
        passive_list.append({
            "text": p.get("name", "Unknown") + " (Lv." + str(p.get("level", 1)) + ")",
            "icon": p.get("icon", ""),
            "index": p.get("index", 0)
        })
    stat_pages.append({"title": "Passive Items", "items": passive_list})

    var audience = GameManager.player_profile.get("audience", [])
    var audience_counts = {}
    for member in audience:
        var a_name = (member.get("name", "Unknown") if typeof(member) == TYPE_DICTIONARY else str(member))
        if not audience_counts.has(a_name):
            audience_counts[a_name] = {"count": 0, "icon": member.get("icon", ""), "index": member.get("index", 0)}
        audience_counts[a_name]["count"] += 1
        
    var sorted_audience = audience_counts.keys()
    sorted_audience.sort()
    
    var audience_list = []
    for name in sorted_audience:
        var entry = audience_counts[name]
        audience_list.append({"text": str(entry["count"]) + " " + name, "icon": entry["icon"], "index": entry["index"]})
    stat_pages.append({"title": "Audience", "items": audience_list})

func update_stats_display():
    for child in stats_container.get_children():
        child.queue_free()

    var page = stat_pages[current_page_index]
    var scale_factor = get_viewport_rect().size.y / reference_height
    var dynamic_font_size = int(get_viewport_rect().size.y * statsbook_font_ratio)

    var flip_button = Button.new()
    flip_button.text = "FLIP PAGE"
    flip_button.pressed.connect(flip_stats_page)
    flip_button.custom_minimum_size = Vector2(0, dynamic_font_size * 3)
    flip_button.add_theme_font_size_override("font_size", dynamic_font_size * 2)
    stats_container.add_child(flip_button)

    var title = Label.new()
    title.text = page["title"]
    title.add_theme_font_size_override("font_size", int(dynamic_font_size * 1.5))
    stats_container.add_child(title)

    if page.has("stats"):
        var stats = GameManager.player_profile.get("stats", {})
        for stat_key in page["stats"]:
            var value = stats.get(stat_key, 0)
            var def = stat_registry.get(stat_key, {})
            create_stat_row(def.get("name", stat_key) + ": " + str(value), def.get("iconatlas", ""), def.get("iconindex", 0), scale_factor)
    elif page.has("items"):
        for item in page["items"]:
            create_stat_row(item["text"], item.get("icon", ""), item.get("index", 0), scale_factor)

func create_stat_row(text: String, icon_path: String, icon_idx: int, scale_factor: float):
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation", int(10 * scale_factor))
    
    var font_size = int(get_viewport_rect().size.y * statsbook_font_ratio)
    
    if icon_path != "":
        var tex_rect = TextureRect.new()
        tex_rect.custom_minimum_size = Vector2(font_size, font_size)
        tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        
        var full_tex = load(icon_path)
        var atlas = AtlasTexture.new()
        atlas.atlas = full_tex
        var tile_w = full_tex.get_width() / 4.0
        var tile_h = full_tex.get_height() / 4.0
        atlas.region = Rect2(Vector2((icon_idx % 4) * tile_w, (icon_idx / 4) * tile_h), Vector2(tile_w, tile_h))
        
        tex_rect.texture = atlas
        row.add_child(tex_rect)
        
    var label = Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", font_size)
    row.add_child(label)
    
    stats_container.add_child(row)

func flip_stats_page():
    current_page_index = (current_page_index + 1) % stat_pages.size()
    update_stats_display()
