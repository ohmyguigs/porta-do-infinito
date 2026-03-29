extends Control

@onready var LabelVersion: Label = %Label_version
var player_id: String = "new_player_1337"

func _ready():
	var version = ProjectSettings.get_setting("application/config/version")
	LabelVersion.text = "version: %s" % version
	print("[main_menu] version: %s" % version)
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		player_id = window.fpid
		print("[main_menu] js bridge fpid: %s" % player_id)
		if typeof(player_id) == TYPE_STRING:
			LabelVersion.text = "%s | device id: %s" % [LabelVersion.text, window.fpid]
			# pls also save
	else:
		LabelVersion.text = "%s | device id: %s" % [LabelVersion.text, player_id]
