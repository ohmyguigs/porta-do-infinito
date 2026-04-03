class_name GameDataInstance
extends Node

const SAVE_GAME_PATH := "user://save_game_data.tres"

var local_game_save: GameData = null

func _ready() -> void:
	if ResourceLoader.exists(SAVE_GAME_PATH):
		local_game_save = ResourceLoader.load(SAVE_GAME_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		write_gamesave(GameData.new())

func write_gamesave(game_data: GameData) -> void:
	var error_code := ResourceSaver.save(game_data, SAVE_GAME_PATH)
	if error_code != OK:
		push_error("Failed to save game: " + error_string(error_code))

func load_gamesave(_device_id: String) -> GameData:
	if ResourceLoader.exists(SAVE_GAME_PATH):
		local_game_save = ResourceLoader.load(SAVE_GAME_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	# use _device_id to fetch save from server instead
	return local_game_save
