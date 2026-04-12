class_name PlayerRemote
extends Node2D

@export var player_id: String = ""
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

var last_seen_unix_ms: float = 0.0

const POSITION_LERP_SPEED := 14.0

var _target_global_position := Vector2.ZERO
var _has_snapshot := false
var _is_spawning := false
var _is_despawning := false
var _pending_state_after_spawn := "idle"

# Controls | HUD
@onready var Label_display_name: Label = %Label_player_name
@onready var all_roles_animation_sprites: AnimatedSprite2D = %AnimatedSprite2D_all_roles

signal despawn_finished(player_id: String)

func _ready() -> void:
	# Duplicar material para isolar shader parameters dessa instância
	# Previene que mudanças de cores desta instância afetem outros PlayerRemote
	all_roles_animation_sprites.material = all_roles_animation_sprites.material.duplicate()
	
	Label_display_name.text = display_name
	_apply_guild_colors(guild)
	_play_animation_for_state("idle")
	if not all_roles_animation_sprites.animation_finished.is_connected(_on_animation_finished):
		all_roles_animation_sprites.animation_finished.connect(_on_animation_finished)
	_target_global_position = global_position

func _process(delta):
	if _is_despawning:
		return
	if not _has_snapshot:
		return

	global_position = global_position.lerp(_target_global_position, clampf(delta * POSITION_LERP_SPEED, 0.0, 1.0))

func apply_snapshot(player_data) -> void:
	if player_data == null:
		return
	if _is_despawning:
		return

	player_id = str(player_data.player_id)
	display_name = str(player_data.display_name)
	role = str(player_data.role)
	last_seen_unix_ms = float(player_data.last_seen_unix_ms)

	Label_display_name.text = display_name
	_apply_guild_colors(str(player_data.guild))
	_pending_state_after_spawn = str(player_data.player_state)
	if not _is_spawning:
		_play_animation_for_state(_pending_state_after_spawn)

	var next_position := Vector2(float(player_data.pos_x), float(player_data.pos_y))
	if not _has_snapshot:
		global_position = next_position
		_target_global_position = next_position
		_has_snapshot = true
		_begin_spawn_animation()
		return

	if next_position.x > _target_global_position.x:
		all_roles_animation_sprites.flip_h = false
	elif next_position.x < _target_global_position.x:
		all_roles_animation_sprites.flip_h = true
	_target_global_position = next_position

func begin_despawn() -> void:
	if _is_despawning:
		return
	_is_despawning = true
	if all_roles_animation_sprites.sprite_frames != null and all_roles_animation_sprites.sprite_frames.has_animation("despawn_01"):
		all_roles_animation_sprites.play("despawn_01")
		return
	despawn_finished.emit(player_id)

func is_despawning() -> bool:
	return _is_despawning

func _begin_spawn_animation() -> void:
	if _is_despawning:
		return
	if all_roles_animation_sprites.sprite_frames != null and all_roles_animation_sprites.sprite_frames.has_animation("spawn_01"):
		_is_spawning = true
		all_roles_animation_sprites.play("spawn_01")
		return
	_is_spawning = false
	_play_animation_for_state("idle")

func _play_animation_for_state(player_state: String) -> void:
	var normalized_state := player_state.strip_edges().to_lower()
	if normalized_state == "run":
		all_roles_animation_sprites.play(role + "_run")
		return
	all_roles_animation_sprites.play(role + "_idle")

func _apply_guild_colors(new_guild: String) -> void:
	if new_guild == guild and all_roles_animation_sprites.material != null:
		return
	guild = new_guild
	if guild == "red":
		return
	swap_colors(
		all_roles_animation_sprites,
		Consts.GuildColorSwapDict["RED_SHADDOW"],
		Consts.GuildColorSwapDict["RED_LIGHT"],
		Consts.GuildColorSwapDict[guild.to_upper() + "_SHADDOW"],
		Consts.GuildColorSwapDict[guild.to_upper() + "_LIGHT"],
	)

func swap_colors(animated_sprite: AnimatedSprite2D, target1: Color, target2: Color, replacement1: Color, replacement2: Color):
	if animated_sprite.material == null:
		return
	const tolerance: float = 0.1620
	animated_sprite.material.set_shader_parameter("tolerance", tolerance)
	animated_sprite.material.set_shader_parameter("target_color1", target1)
	animated_sprite.material.set_shader_parameter("target_color2", target2)
	animated_sprite.material.set_shader_parameter("replace_color1", replacement1)
	animated_sprite.material.set_shader_parameter("replace_color2", replacement2)

func _on_animation_finished() -> void:
	if _is_spawning and all_roles_animation_sprites.animation == &"spawn_01":
		_is_spawning = false
		_play_animation_for_state(_pending_state_after_spawn)
		return
	if not _is_despawning:
		return
	if all_roles_animation_sprites.animation != &"despawn_01":
		return
	despawn_finished.emit(player_id)
