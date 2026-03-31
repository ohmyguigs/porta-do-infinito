class_name PlayerEdit
extends Control

var device_id: String = "dev_player_1337"

var local_gamesave: GameData = null
var display_name: String = ""

func _ready() -> void:
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		device_id = window.fpid
		print("[player_edit] js bridge fpid: %s" % device_id)
	else:
		print("[player_edit] NO js bridge, fallback device_id: %s" % device_id)
	local_gamesave = GlobalGameData.load_gamesave(device_id)
	print("[player_edit] gamesave: %s" % str(local_gamesave))
	if local_gamesave != null:
		device_id = local_gamesave.device_id

func _on_line_edit_name_text_changed(typed_value: String) -> void:
	print("[player_edit] name typed: %s" % str(typed_value))
	display_name = typed_value


func _on_button_save_button_up() -> void:
	print("[player_edit] saving name: %s" % str(display_name))
	local_gamesave.display_name = display_name
	GlobalGameData.write_gamesave(local_gamesave)
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
