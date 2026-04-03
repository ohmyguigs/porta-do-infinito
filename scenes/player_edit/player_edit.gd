class_name PlayerEdit
extends Control

var device_id: String = "dev_player_1337"

var local_gamesave: GameData = null
var display_name: String = ""
var selected_role: String = "warrior"
var selected_guild: String = "red"

# Controls
@onready var LineEdit_name: LineEdit = %LineEdit_name
@onready var Label_gamedata: Label = %Label_localgamedata

# ROLE TILE MAP LAYERS
@onready var WARRIOR_TILEMAPLAYER: TileMapLayer = %idle_warrior
@onready var LANCER_TILEMAPLAYER: TileMapLayer = %idle_lancer
@onready var ARCHER_TILEMAPLAYER: TileMapLayer = %idle_archer
@onready var MONK_TILEMAPLAYER: TileMapLayer = %idle_monk

# GUILD COLORS TO SHADDER SWAP
var GuildColorSwapDict: Dictionary[String, Color] = {
	'RED_SHADDOW':Color(0.573, 0.255, 0.349, 1.0),
	'RED_LIGHT':Color(0.906, 0.38, 0.38, 1.0),
	'BLUE_SHADDOW':Color(0.282, 0.345, 0.518, 1.0),
	'BLUE_LIGHT':Color(0.275, 0.592, 0.675, 1.0),
	'BLACK_SHADDOW':Color(0.263, 0.251, 0.333, 1.0),
	'BLACK_LIGHT':Color(0.369, 0.435, 0.525, 1.0),
	'PURPLE_SHADDOW':Color(0.361, 0.329, 0.494, 1.0),
	'PURPLE_LIGHT':Color(0.671, 0.431, 0.612, 1.0),
	'YELLOW_SHADDOW':Color(0.533, 0.376, 0.286, 1.0),
	'YELLOW_LIGHT':Color(0.863, 0.667, 0.275, 1.0),
}

func _ready() -> void:
	# START - HANDLE GAME DATA LOAD
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		device_id = window.fpid
		print("[player_edit] js bridge fpid: %s" % device_id)
	else:
		print("[player_edit] NO js bridge, fallback device_id: %s" % device_id)
	local_gamesave = GlobalGameData.load_gamesave(device_id)
	print("[player_edit] gamesave: { guild: %s, role: %s, device_id: %s, display_name: %s }" % [
		local_gamesave.guild,
		local_gamesave.role,
		local_gamesave.device_id,
		local_gamesave.display_name,
	])
	if local_gamesave != null:
		device_id = local_gamesave.device_id
		display_name = local_gamesave.display_name
		selected_guild = local_gamesave.guild
		selected_role = local_gamesave.role
		handle_guild_select(local_gamesave.guild, true)
		LineEdit_name.text = local_gamesave.display_name
	# END - HANDLE GAME DATA LOAD

func handle_guild_select(new_guild: String, fisrtRun: bool = false) -> void:
	if new_guild == selected_guild && !fisrtRun:
		print("[player_edit] skiping guild select, %s is already selected!" % selected_guild)
		return
	var tilemaplayer_name = selected_role.to_upper() + '_TILEMAPLAYER'
	print("[player_edit] handle guild select, tilemaplayer name: %s" % tilemaplayer_name)
	var tilemaplayer = get(tilemaplayer_name)
	var target1_key = selected_guild.to_upper() + '_SHADDOW'
	print("[player_edit] target1 name: %s" % target1_key)
	var target1 = GuildColorSwapDict[target1_key]
	var target2_key = selected_guild.to_upper() + '_LIGHT'
	print("[player_edit] target2 name: %s" % target2_key)
	var target2 = GuildColorSwapDict[target2_key]
	# transforma tudo pra vermelho antes de trocar pra cor destino
	var transition1 = GuildColorSwapDict["RED_SHADDOW"]
	var transition2 = GuildColorSwapDict["RED_LIGHT"]
	var replacement1_key = new_guild.to_upper() + '_SHADDOW'
	print("[player_edit] replacement1 name: %s" % replacement1_key)
	var replacement1 = GuildColorSwapDict[replacement1_key]
	var replacement2_key = new_guild.to_upper() + '_LIGHT'
	print("[player_edit] replacement2 name: %s" % replacement2_key)
	var replacement2 = GuildColorSwapDict[replacement2_key]
	swap_colors(tilemaplayer, target1, target2, transition1, transition2)
	swap_colors(tilemaplayer, transition1, transition2, replacement1, replacement2)
	Label_gamedata.text = new_guild + " " + selected_role
	selected_guild = new_guild


func swap_colors(_tilemaplayer: TileMapLayer, target1: Color, target2: Color, replacement1: Color, replacement2: Color):
	const tolerance: float = 0.1
	_tilemaplayer.material.set_shader_parameter("tolerance", tolerance)
	_tilemaplayer.material.set_shader_parameter("target_color1", target1)
	_tilemaplayer.material.set_shader_parameter("target_color2", target2)
	_tilemaplayer.material.set_shader_parameter("replace_color1", replacement1)
	_tilemaplayer.material.set_shader_parameter("replace_color2", replacement2)

func _on_line_edit_name_text_changed(typed_value: String) -> void:
	print("[player_edit] name typed: %s" % str(typed_value))
	display_name = typed_value

func _on_button_save_button_up() -> void:
	print("[player_edit] saving name: %s" % str(display_name))
	local_gamesave.display_name = display_name
	local_gamesave.guild = selected_guild
	local_gamesave.role = selected_role
	GlobalGameData.write_gamesave(local_gamesave)
	#get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_texture_button_guild_purple_button_up() -> void:
	print("[player_edit] clicked guild purple!")
	handle_guild_select("purple")

func _on_texture_button_guild_black_button_up() -> void:
	print("[player_edit] clicked guild black!")
	handle_guild_select("black")

func _on_texture_button_guild_blue_button_up() -> void:
	print("[player_edit] clicked guild blue!")
	handle_guild_select("blue")

func _on_texture_button_guild_red_button_up() -> void:
	print("[player_edit] clicked guild red!")
	handle_guild_select("red")

func _on_texture_button_guild_yellow_button_up() -> void:
	print("[player_edit] clicked guild yellow!")
	handle_guild_select("yellow")
