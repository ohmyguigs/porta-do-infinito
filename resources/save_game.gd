class_name save_game
extends Resource

const SAVE_GAM_PATH := "user://save_game_data.tres"
const GUILDS: Array[String] = ["red", "blue", "black", "purple", "yellow"]
const ROLES: Array[String] = ["warrior", "lancer", "monk", "archer"]

# initial global game data
@export var display_name:String = "player_dev_1337"
@export var device_id:String = "desktop_dev_1337"
@export var selected_guild:String = "red"
@export var selected_role:String = "pawn"
@export var player_global_position := Vector2(0, 0)
