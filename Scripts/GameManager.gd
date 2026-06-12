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
