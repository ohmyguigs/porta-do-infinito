class_name MainMenu
extends Control

@onready var Button_start: Button = %Button_start
@onready var LabelVersion: Label = %Label_version
@onready var LabelDeviceId: Label = %Label_device_id
@onready var LabelStatus: Label = %Label_status
@onready var LabelTotalPlayers: Label = %Label_total_players
@onready var SphereStatus: MeshInstance2D = %sphere_server_status
@onready var DialogServerBusy: AcceptDialog = %Dialog_server_busy
var device_id: String = "dev_player_1337"


var local_gamesave: GameData = null

func _ready() -> void:
	set_version_label()
	if not GlobalGameData.remote_status_changed.is_connected(_on_remote_status_changed):
		GlobalGameData.remote_status_changed.connect(_on_remote_status_changed)
	if not GlobalGameData.remote_session_status_changed.is_connected(_on_remote_session_status_changed):
		GlobalGameData.remote_session_status_changed.connect(_on_remote_session_status_changed)
	if not GlobalGameData.online_players_count_changed.is_connected(_on_online_players_count_changed):
		GlobalGameData.online_players_count_changed.connect(_on_online_players_count_changed)
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		device_id = window.fpid
		print("[main_menu] js bridge fpid: %s" % device_id)
	local_gamesave = GlobalGameData.load_gamesave(device_id)
	print("[main_menu] gamesave: %s" % str(local_gamesave))
	if local_gamesave != null:
		device_id = local_gamesave.browser_fingerprint
	set_device_id_label()
	_apply_server_status(GlobalGameData.get_remote_session_status(), GlobalGameData.get_remote_session_status_message())
	# if load load last global position
	# else new save

func set_online_label() -> void:
	SphereStatus.modulate = Consts.COLOR_ONLINE
	LabelStatus.text = LabelStatus.text.replace("offline", "online")
	LabelStatus.text = LabelStatus.text.replace("ocupado", "online")
	if not LabelStatus.text.contains("online"):
		LabelStatus.text = "server online"
	Button_start.visible = true
	Button_start.disabled = false

func set_offline_label() -> void:
	SphereStatus.modulate = Consts.COLOR_OFFLINE
	LabelStatus.text = LabelStatus.text.replace("online", "offline")
	LabelStatus.text = LabelStatus.text.replace("ocupado", "offline")
	if not LabelStatus.text.contains("offline"):
		LabelStatus.text = "server offline"
	Button_start.visible = true
	Button_start.disabled = false

func set_occupied_label() -> void:
	SphereStatus.modulate = Consts.COLOR_OFFLINE
	LabelStatus.text = LabelStatus.text.replace("online", "ocupado")
	LabelStatus.text = LabelStatus.text.replace("offline", "ocupado")
	if not LabelStatus.text.contains("ocupado"):
		LabelStatus.text = "server ocupado"
	Button_start.visible = false
	Button_start.disabled = true
	
func set_version_label() -> void:
	var version = ProjectSettings.get_setting("application/config/version")
	LabelVersion.text = "versão: %s" % version

func set_total_players(total_players_online: int) -> void:
	LabelTotalPlayers.text = "%s players" % str(total_players_online if total_players_online else 0)

func set_device_id_label() -> void:
	if local_gamesave != null:
		LabelDeviceId.text = "player_name: %s" % local_gamesave.display_name
	elif typeof(device_id) == TYPE_STRING:
			LabelDeviceId.text = "device_id: %s" % device_id

func _on_remote_status_changed(is_online: bool) -> void:
	if GlobalGameData.get_remote_session_status() == GlobalGameData.SESSION_STATUS_OCCUPIED:
		return
	if is_online:
		set_online_label()
		return
	set_offline_label()

func _on_remote_session_status_changed(status: String, message: String) -> void:
	_apply_server_status(status, message)

func _apply_server_status(status: String, message: String) -> void:
	if status == GlobalGameData.SESSION_STATUS_OCCUPIED:
		set_occupied_label()
		_show_server_busy_dialog(message)
		return
	if status == GlobalGameData.SESSION_STATUS_ONLINE:
		set_online_label()
		return
	set_offline_label()

func _show_server_busy_dialog(message: String) -> void:
	if message == "":
		DialogServerBusy.dialog_text = "Servidor ocupado: voce provavelmente ja esta conectado em outra aba."
	else:
		DialogServerBusy.dialog_text = message
	if DialogServerBusy.visible:
		return
	DialogServerBusy.popup_centered()

func _on_online_players_count_changed(count: int) -> void:
	set_total_players(count)

func _on_Button_start_pressed() -> void:
	if GlobalGameData.get_remote_session_status() == GlobalGameData.SESSION_STATUS_OCCUPIED:
		_show_server_busy_dialog(GlobalGameData.get_remote_session_status_message())
		return
	print("start button pressed")
	get_tree().change_scene_to_file("res://scenes/player_edit/player_edit.tscn")
