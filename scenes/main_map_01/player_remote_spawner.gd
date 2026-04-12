extends Node2D

const REMOTE_PLAYER_SCENE = preload("res://scenes/player_instance/Player_remote.tscn")
const OFFLINE_PRUNE_INTERVAL_SEC := 1.0

var _spawned_remote_players := {}
var _offline_prune_timer: Timer = null

func _ready() -> void:
	_setup_offline_prune_timer()
	_connect_global_signals()
	_spawn_initial_snapshot()

func _exit_tree() -> void:
	_disconnect_global_signals()

func _setup_offline_prune_timer() -> void:
	if _offline_prune_timer != null:
		return
	_offline_prune_timer = Timer.new()
	_offline_prune_timer.one_shot = false
	_offline_prune_timer.wait_time = OFFLINE_PRUNE_INTERVAL_SEC
	if not _offline_prune_timer.timeout.is_connected(_on_offline_prune_timeout):
		_offline_prune_timer.timeout.connect(_on_offline_prune_timeout)
	add_child(_offline_prune_timer)
	_offline_prune_timer.start()

func _connect_global_signals() -> void:
	if not GlobalGameData.remote_player_created.is_connected(_on_remote_player_created):
		GlobalGameData.remote_player_created.connect(_on_remote_player_created)
	if not GlobalGameData.remote_player_updated.is_connected(_on_remote_player_updated):
		GlobalGameData.remote_player_updated.connect(_on_remote_player_updated)
	if not GlobalGameData.remote_player_removed.is_connected(_on_remote_player_removed):
		GlobalGameData.remote_player_removed.connect(_on_remote_player_removed)

func _disconnect_global_signals() -> void:
	if GlobalGameData.remote_player_created.is_connected(_on_remote_player_created):
		GlobalGameData.remote_player_created.disconnect(_on_remote_player_created)
	if GlobalGameData.remote_player_updated.is_connected(_on_remote_player_updated):
		GlobalGameData.remote_player_updated.disconnect(_on_remote_player_updated)
	if GlobalGameData.remote_player_removed.is_connected(_on_remote_player_removed):
		GlobalGameData.remote_player_removed.disconnect(_on_remote_player_removed)

func _spawn_initial_snapshot() -> void:
	for player in GlobalGameData.get_players_snapshot():
		_on_remote_player_created(player)

func _on_remote_player_created(player) -> void:
	if not _can_render_player(player):
		return

	var player_id := str(player.player_id)
	if _spawned_remote_players.has(player_id):
		var existing_remote: PlayerRemote = _spawned_remote_players[player_id]
		if existing_remote != null and not existing_remote.is_despawning():
			existing_remote.apply_snapshot(player)
		return

	var remote_player := REMOTE_PLAYER_SCENE.instantiate() as PlayerRemote
	if remote_player == null:
		return

	add_child(remote_player)
	_spawned_remote_players[player_id] = remote_player
	if not remote_player.despawn_finished.is_connected(_on_remote_player_despawn_finished):
		remote_player.despawn_finished.connect(_on_remote_player_despawn_finished)
	remote_player.apply_snapshot(player)

func _on_remote_player_updated(_previous_player, current_player) -> void:
	var player_id := str(current_player.player_id)
	if not _spawned_remote_players.has(player_id):
		_on_remote_player_created(current_player)
		return

	var remote_player: PlayerRemote = _spawned_remote_players[player_id]
	if remote_player == null:
		_spawned_remote_players.erase(player_id)
		return

	if not _can_render_player(current_player):
		_request_remote_despawn(player_id)
		return

	if remote_player.is_despawning():
		return

	remote_player.apply_snapshot(current_player)

func _on_remote_player_removed(player) -> void:
	_request_remote_despawn(str(player.player_id))

func _request_remote_despawn(player_id: String) -> void:
	if not _spawned_remote_players.has(player_id):
		return

	var remote_player: PlayerRemote = _spawned_remote_players[player_id]
	if remote_player == null:
		_spawned_remote_players.erase(player_id)
		return
	if remote_player.is_despawning():
		return

	remote_player.begin_despawn()

func _on_remote_player_despawn_finished(player_id: String) -> void:
	if not _spawned_remote_players.has(player_id):
		return

	var remote_player: PlayerRemote = _spawned_remote_players[player_id]
	_spawned_remote_players.erase(player_id)
	if remote_player != null:
		remote_player.queue_free()

func _on_offline_prune_timeout() -> void:
	var players_to_despawn: Array[String] = []
	for player_id in _spawned_remote_players.keys():
		var remote_player: PlayerRemote = _spawned_remote_players[player_id]
		if remote_player == null:
			players_to_despawn.append(player_id)
			continue
		if remote_player.is_despawning():
			continue
		if not GlobalGameData.is_last_seen_online(remote_player.last_seen_unix_ms):
			players_to_despawn.append(player_id)

	for player_id in players_to_despawn:
		_request_remote_despawn(player_id)

func _can_render_player(player) -> bool:
	if player == null:
		return false
	var player_id := str(player.player_id)
	if player_id == "":
		return false
	if GlobalGameData.is_local_player_id(player_id):
		return false
	return GlobalGameData.is_last_seen_online(float(player.last_seen_unix_ms))
