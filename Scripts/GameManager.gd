# GameManager.gd
extends Node



# --- Profiles ---
var player_profile = {
    "stats": {},
    "passives": [],
    "weapons": [],
    "audience": []
}
var current_enemy_profile = {
    "stats": {},
    "passives": [],
    "weapons": [],
    "audience": []
}

var audience_mastery := {}
var selectedCharacter: int = 0

func unlock_difficulty_mastery():
    if !audience_mastery.has(selected_difficulty):
       audience_mastery[selected_difficulty] = {}
    audience_mastery[selected_difficulty][selectedCharacter] = true

var difficulties = ["Easy", "Normal", "Hard", "Insane"]

static func _find_passive_data3(stat_name: String,target_stats: Dictionary) -> Dictionary:
    for passive in target_stats["passives"]:
        if passive.get("name") == stat_name:
            return passive
    return {} # Return empty if not found

static func addtopassive3(stat_name: String, amount: float,target_stats: Dictionary) -> void:
    var passives = _find_passive_data3(stat_name,target_stats)
    passives["level"] += amount

static func getpassive3(stat_name: String,target_stats: Dictionary) -> float:
    var passives = _find_passive_data3(stat_name,target_stats)
    # Check if the stat exists to avoid a "Key not found" error
    if passives.has("level"):
        return float(passives["level"])
    
    return 0.0

static func _find_passive_data2(stat_name: String) -> Dictionary:
    for passive in GameManager.current_enemy_profile["passives"]:
        if passive.get("name") == stat_name:
            return passive
    return {} # Return empty if not found

static func addtopassive2(stat_name: String, amount: float) -> void:
    var passives = _find_passive_data2(stat_name)
    passives["level"] += amount

static func getpassive2(stat_name: String) -> float:
    var passives = _find_passive_data2(stat_name)
    # Check if the stat exists to avoid a "Key not found" error
    if passives.has("level"):
        return float(passives["level"])
    
    return 0.0

static func _find_passive_data(stat_name: String) -> Dictionary:
    for passive in GameManager.player_profile["passives"]:
        if passive.get("name") == stat_name:
            return passive
    return {} # Return empty if not found

static func addtopassive(stat_name: String, amount: float) -> void:
    var passives = _find_passive_data(stat_name)
    passives["level"] += amount

static func getpassive(stat_name: String) -> float:
    var passives = _find_passive_data(stat_name)
    # Check if the stat exists to avoid a "Key not found" error
    if passives.has("level"):
        return float(passives["level"])
    
    return 0.0

func get_difficulty_key() -> String:
    if selected_difficulty < 0 or selected_difficulty >= difficulties.size():
        return "Easy" # fallback safety
    return difficulties[selected_difficulty]
var after_battle_data
var currentRound: int = 0
var battle_over: bool = false
var escaped: bool = false
# Place these variables inside your global auto-load script (e.g., res://Scripts/GameManager.gd)

# GameManager.gd Additions
var shop_initialized: bool = false
var shop_items: Array = []  # Stores item dictionary states and "bought" statuses
var persistent_reroll_cost: int = 10

var selected_difficulty = 1
