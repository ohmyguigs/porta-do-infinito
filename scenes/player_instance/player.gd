class_name Player
extends Node2D

var device_id: String = "default"
var display_name: String = "display_name"
var role: String = "warrior"
var guild: String = "red"
var local_gamesave: GameData = null

@export var speed = 333

# Controls | HUD
@onready var Label_display_name: Label = %Label_player_name
@onready var all_roles_animation_sprites: AnimatedSprite2D = %AnimatedSprite2D_all_roles

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
	const tolerance: float = 0.1
	animated_sprite.material.set_shader_parameter("tolerance", tolerance)
	animated_sprite.material.set_shader_parameter("target_color1", target1)
	animated_sprite.material.set_shader_parameter("target_color2", target2)
	animated_sprite.material.set_shader_parameter("replace_color1", replacement1)
	animated_sprite.material.set_shader_parameter("replace_color2", replacement2)

#func _input(event: InputEvent) -> void:
	## movement
	#var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	## Set velocity based on direction and speed
	#velocity = direction * speed
	#
	## Apply movement and handle collisions automatically
	#move_and_slide()
	#if event.is_action("move_up") || event.is_action("move_down"):
		## actually move
		#
		#pass
	#if event.is_action("escape"):
		#get_tree().change_scene_to_file("res://scenes/player_edit/player_edit.tscn")
