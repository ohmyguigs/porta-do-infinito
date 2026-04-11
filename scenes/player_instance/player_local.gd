class_name Player
extends Node2D

@export var display_name: String = "display_name"
@export_enum(
	Consts.ROLES[0],
	Consts.ROLES[1],
	Consts.ROLES[2],
	Consts.ROLES[3]
) var role = "warrior"
@export_enum(
	Consts.GUILDS[0],
	Consts.GUILDS[1],
	Consts.GUILDS[2],
	Consts.GUILDS[3],
	Consts.GUILDS[4],
) var guild = "red"
@export_range(300, 420) var speed: int = 333
var device_id: String = "default"
var local_gamesave: GameData = null

# Controls | HUD
@onready var Label_display_name: Label = %Label_player_name
@onready var all_roles_animation_sprites: AnimatedSprite2D = %AnimatedSprite2D_all_roles
#@onready var player_camera: Camera2D = %Camera2D_player

func _ready() -> void:
	# START GAME DATA LOGIC
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		device_id = window.fpid
		print("[main_menu] js bridge fpid: %s" % device_id)
	local_gamesave = GlobalGameData.load_gamesave(device_id)
	print("[main_menu] gamesave: %s" % str(local_gamesave))
	if local_gamesave != null:
		device_id = local_gamesave.device_id
		display_name = local_gamesave.display_name
		role = local_gamesave.role
		guild = local_gamesave.guild
		Label_display_name.text = local_gamesave.display_name
		self.global_position = local_gamesave.player_global_position
	# END GAME DATA LOGIC
	if guild != "red":
		swap_colors(
			all_roles_animation_sprites,
			Consts.GuildColorSwapDict["RED_SHADDOW"],
			Consts.GuildColorSwapDict["RED_LIGHT"],
			Consts.GuildColorSwapDict[guild.to_upper() + "_SHADDOW"],
			Consts.GuildColorSwapDict[guild.to_upper() + "_LIGHT"],
		)
	#wait(2.0)
	#player_camera.position_smoothing_enabled = true
	#player_camera.position_smoothing_speed = 5

func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * speed
	if Input.is_action_pressed("move_right"):
		all_roles_animation_sprites.flip_h = false
	if Input.is_action_pressed("move_left"):
		all_roles_animation_sprites.flip_h = true
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		all_roles_animation_sprites.play(role + "_run")
	else:
		all_roles_animation_sprites.play(role + "_idle")
	position += velocity * delta

func swap_colors(animated_sprite: AnimatedSprite2D, target1: Color, target2: Color, replacement1: Color, replacement2: Color):
	const tolerance: float = 0.1620
	animated_sprite.material.set_shader_parameter("tolerance", tolerance)
	animated_sprite.material.set_shader_parameter("target_color1", target1)
	animated_sprite.material.set_shader_parameter("target_color2", target2)
	animated_sprite.material.set_shader_parameter("replace_color1", replacement1)
	animated_sprite.material.set_shader_parameter("replace_color2", replacement2)

func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		local_gamesave.player_global_position = self.global_position
		GlobalGameData.write_gamesave(local_gamesave)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
