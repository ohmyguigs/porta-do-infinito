class_name MainMenu
extends Control

@onready var Button_start: Button = %Button_start
@onready var LabelVersion: Label = %Label_version
@onready var LabelDeviceId: Label = %Label_device_id
@onready var LabelStatus: Label = %Label_status
@onready var SphereStatus: MeshInstance2D = %sphere_server_status
var device_id: String = "dev_player_1337"


var local_gamesave: GameData = null

func _ready() -> void:
	set_version_label()
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		device_id = window.fpid
		print("[main_menu] js bridge fpid: %s" % device_id)
	local_gamesave = GlobalGameData.load_gamesave(device_id)
	print("[main_menu] gamesave: %s" % str(local_gamesave))
	if local_gamesave != null:
		device_id = local_gamesave.device_id
	set_device_id_label()
	# check server connection
	set_offline_label() # mock offline
	# if load load last global position
	# else new save

func set_online_label() -> void:
	SphereStatus.modulate = Consts.COLOR_ONLINE
	LabelStatus.text = LabelStatus.text.replace("offline","online")

func set_offline_label() -> void:
	SphereStatus.modulate = Consts.COLOR_OFFLINE
	LabelStatus.text = LabelStatus.text.replace("online","offline")
	
func set_version_label() -> void:
	var version = ProjectSettings.get_setting("application/config/version")
	LabelVersion.text = "versão: %s" % version

func set_device_id_label() -> void:
	if local_gamesave != null:
		LabelDeviceId.text = "player_name: %s" % local_gamesave.display_name
	elif typeof(device_id) == TYPE_STRING:
			LabelDeviceId.text = "device_id: %s" % device_id

func _on_Button_start_pressed() -> void:
	print("start button pressed")
	get_tree().change_scene_to_file("res://scenes/player_edit/player_edit.tscn")
