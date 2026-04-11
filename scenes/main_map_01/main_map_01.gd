class_name MainMap01
extends Node2D

var device_id: String = "dev_player_1337"
var local_gamesave: GameData = null

func _ready() -> void:
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		device_id = window.fpid
		print("[main_map] js bridge fpid: %s" % device_id)
	local_gamesave = GlobalGameData.load_gamesave(device_id)
	print("[main_map] gamesave: %s" % str(local_gamesave))
	if local_gamesave != null:
		device_id = local_gamesave.browser_fingerprint

func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		get_tree().change_scene_to_file("res://scenes/player_edit/player_edit.tscn")
