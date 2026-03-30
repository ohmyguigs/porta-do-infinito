extends Control

@onready var Button_start: Button = %Button_start
@onready var LabelVersion: Label = %Label_version
@onready var LabelDeviceId: Label = %Label_device_id
@onready var LabelStatus: Label = %Label_status
@onready var SphereStatus: MeshInstance2D = %sphere_server_status
var player_id: String = "dev_player_1337"
var COLOR_ONLINE: Color = Color(0.016, 0.89, 0.047)
var COLOR_OFFLINE: Color = Color(0.737, 0.0, 0.0, 1.0)

func _ready() -> void:
	set_version_label()
	set_device_id_label()
	# check server connection
	set_offline_label() # mock offline
	# if load load last global position
	# else new save and go to player edit 
	

func set_online_label() -> void:
	SphereStatus.modulate = COLOR_ONLINE
	LabelStatus.text = LabelStatus.text.replace("offline","online")

func set_offline_label() -> void:
	SphereStatus.modulate = COLOR_OFFLINE
	LabelStatus.text = LabelStatus.text.replace("online","offline")
	
func set_version_label() -> void:
	var version = ProjectSettings.get_setting("application/config/version")
	LabelVersion.text = "versão: %s" % version

func set_device_id_label() -> void:
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		player_id = window.fpid
		print("[main_menu] js bridge fpid: %s" % player_id)
		if typeof(player_id) == TYPE_STRING:
			LabelDeviceId.text = "device_id: %s" % player_id
			# pls also save
	else:
		LabelDeviceId.text = "device_id: %s" % player_id
