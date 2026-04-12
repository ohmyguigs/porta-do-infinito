class_name GameDataInstance
extends Node

const LOCAL_SAVE_GAME_PATH := "user://save_game_data.tres"
const SPACETIMEDB_URI := "https://maincloud.spacetimedb.com"
const SPACETIMEDB_DATABASE_NAME := "portal-infinito-main-l7sw9"
const SPACETIMEDB_MODULE_ALIAS := "main"
const ONLINE_WINDOW_MS := 60_000
const HEARTBEAT_INTERVAL_SEC := 10.0

var local_game_save: GameData = null
var _is_remote_connected := false
var _pending_remote_sync: GameData = null
var _subscription = null

var _last_known_online_count: int = 0
var _players_table_listeners_registered := false
var _heartbeat_timer: Timer = null

signal remote_status_changed(is_online: bool)
signal remote_sync_error(message: String)

signal online_players_count_changed(count: int)
signal remote_player_created(player)
signal remote_player_updated(previous_player, current_player)
signal remote_player_removed(player)

func _ready() -> void:
	_reload_local_gamesave()
	if local_game_save == null:
		local_game_save = GameData.new()
	_normalize_identity(local_game_save, local_game_save.browser_fingerprint)
	_save_local_gamesave(local_game_save)
	_setup_heartbeat_timer()
	_connect_remote()

func write_gamesave(game_data: GameData) -> void:
	_normalize_identity(game_data, game_data.browser_fingerprint)
	game_data.last_seen_unix_ms = Time.get_unix_time_from_system() * 1000
	_save_local_gamesave(game_data)
	_sync_remote_game_data(game_data)

func load_gamesave(device_id: String) -> GameData:
	_reload_local_gamesave()
	if local_game_save == null:
		local_game_save = GameData.new()
	_normalize_identity(local_game_save, device_id)
	_save_local_gamesave(local_game_save)
	_ensure_subscription_for_identity(local_game_save)
	return local_game_save

func is_remote_connected() -> bool:
	return _is_remote_connected

func get_local_player_id() -> String:
	if local_game_save == null:
		return ""
	return local_game_save.player_id

func is_local_player_id(player_id: String) -> bool:
	if player_id == "":
		return false
	return player_id == get_local_player_id()

func is_last_seen_online(last_seen_unix_ms: float) -> bool:
	var now_ms := Time.get_unix_time_from_system() * 1000
	return now_ms - last_seen_unix_ms <= ONLINE_WINDOW_MS

func get_players_snapshot() -> Array:
	var module_client = _get_module_client()
	if module_client == null:
		return []

	var players: Array = []
	for player in module_client.db.players.iter():
		players.append(player)
	return players

func _reload_local_gamesave() -> void:
	if ResourceLoader.exists(LOCAL_SAVE_GAME_PATH):
		local_game_save = ResourceLoader.load(LOCAL_SAVE_GAME_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

func _save_local_gamesave(game_data: GameData) -> void:
	local_game_save = game_data
	var error_code := ResourceSaver.save(game_data, LOCAL_SAVE_GAME_PATH)
	if error_code != OK:
		push_error("Failed to save game: " + error_string(error_code))

func _normalize_identity(game_data: GameData, browser_fingerprint: String) -> void:
	if game_data.player_id == "":
		game_data.player_id = _generate_local_player_id()
	if browser_fingerprint != "":
		game_data.browser_fingerprint = browser_fingerprint
	if game_data.browser_fingerprint != "":
		# Keep compatibility with older code until full migration away from device_id.
		game_data.device_id = game_data.browser_fingerprint

func _generate_local_player_id() -> String:
	var unix_ms := Time.get_unix_time_from_system() * 1000
	return "local_%s_%s" % [str(unix_ms), str(randi())]

func _connect_remote() -> void:
	var module_client = _get_module_client()
	if module_client == null:
		return

	if not module_client.connected.is_connected(_on_remote_connected):
		module_client.connected.connect(_on_remote_connected)
	if not module_client.disconnected.is_connected(_on_remote_disconnected):
		module_client.disconnected.connect(_on_remote_disconnected)
	if not module_client.connection_error.is_connected(_on_remote_connection_error):
		module_client.connection_error.connect(_on_remote_connection_error)

	var options := SpacetimeDBConnectionOptions.new()
	options.one_time_token = false
	options.debug_mode = false
	if OS.has_feature("web"):
		options.threading = false
	module_client.connect_db(SPACETIMEDB_URI, SPACETIMEDB_DATABASE_NAME, options)

func _get_module_client():
	if not has_node("/root/SpacetimeDB"):
		return null
	var module_property_name := SPACETIMEDB_MODULE_ALIAS.to_pascal_case()
	var module_client = SpacetimeDB.get(module_property_name)
	if module_client == null:
		push_warning("SpacetimeDB module alias '%s' not found. Generate schema first." % SPACETIMEDB_MODULE_ALIAS)
	return module_client

func _on_remote_connected(_identity: PackedByteArray, _token: String) -> void:
	_is_remote_connected = true
	remote_status_changed.emit(true)
	if local_game_save != null:
		_ensure_subscription_for_identity(local_game_save)
	_register_players_table_listeners()
	_start_heartbeat()
	_flush_pending_remote_sync()

func _on_remote_disconnected() -> void:
	_is_remote_connected = false
	remote_status_changed.emit(false)
	_stop_heartbeat()

func _on_remote_connection_error(_code: int, reason: String) -> void:
	_is_remote_connected = false
	remote_status_changed.emit(false)
	_stop_heartbeat()
	remote_sync_error.emit(reason)

func _ensure_subscription_for_identity(game_data: GameData) -> void:
	if not _is_remote_connected:
		return
	var module_client = _get_module_client()
	if module_client == null:
		return
	if game_data.player_id == "":
		return

	var query_player := "SELECT * FROM players WHERE player_id = '%s'" % game_data.player_id
	var query_online := "SELECT * FROM players WHERE last_seen_unix_ms > %s" % str(Time.get_unix_time_from_system() * 1000 - ONLINE_WINDOW_MS)
	_subscription = module_client.subscribe(PackedStringArray([query_player, query_online]))

func _sync_remote_game_data(game_data: GameData) -> void:
	if not _is_remote_connected:
		_pending_remote_sync = game_data.duplicate(true)
		return

	var module_client = _get_module_client()
	if module_client == null:
		_pending_remote_sync = game_data.duplicate(true)
		return
	if not module_client.reducers.has_method("upsert_player"):
		remote_sync_error.emit("Reducer upsert_player not found in module.")
		_pending_remote_sync = game_data.duplicate(true)
		return

	module_client.reducers.upsert_player(
		game_data.player_id,
		game_data.browser_fingerprint,
		game_data.display_name,
		game_data.guild,
		game_data.role,
		game_data.player_state,
		game_data.player_global_position.x,
		game_data.player_global_position.y,
		game_data.last_seen_unix_ms
	)

func _flush_pending_remote_sync() -> void:
	if _pending_remote_sync == null:
		return
	_sync_remote_game_data(_pending_remote_sync)
	_pending_remote_sync = null

func _count_online_players() -> int:
	var module_client = _get_module_client()
	if module_client == null:
		return 0
	
	var online_count := 0
	var now_ms := Time.get_unix_time_from_system() * 1000
	
	for player in module_client.db.players.iter():
		if now_ms - player.last_seen_unix_ms <= ONLINE_WINDOW_MS:
			online_count += 1
	
	return online_count

func _emit_online_count_changed() -> void:
	var current_count := _count_online_players()
	if current_count != _last_known_online_count:
		_last_known_online_count = current_count
		online_players_count_changed.emit(current_count)

func _register_players_table_listeners() -> void:
	if _players_table_listeners_registered:
		return
	var module_client = _get_module_client()
	if module_client == null:
		return
	
	# Listeners para mudanças na tabela players
	module_client.db.players.on_insert(func(player):
		if not _is_local_player(player):
			remote_player_created.emit(player)
		_emit_online_count_changed()
	)
	
	module_client.db.players.on_update(func(old_player, new_player):
		if not _is_local_player(new_player):
			remote_player_updated.emit(old_player, new_player)
		_emit_online_count_changed()
	)
	
	module_client.db.players.on_delete(func(player):
		if not _is_local_player(player):
			remote_player_removed.emit(player)
		_emit_online_count_changed()
	)
	
	_players_table_listeners_registered = true
	
	# Emitir contagem inicial
	_emit_online_count_changed()

func _is_local_player(player) -> bool:
	if player == null:
		return false
	if local_game_save == null:
		return false
	return str(player.player_id) == local_game_save.player_id

func _setup_heartbeat_timer() -> void:
	if _heartbeat_timer != null:
		return
	_heartbeat_timer = Timer.new()
	_heartbeat_timer.one_shot = false
	_heartbeat_timer.wait_time = HEARTBEAT_INTERVAL_SEC
	if not _heartbeat_timer.timeout.is_connected(_on_heartbeat_timeout):
		_heartbeat_timer.timeout.connect(_on_heartbeat_timeout)
	add_child(_heartbeat_timer)

func _start_heartbeat() -> void:
	if _heartbeat_timer == null:
		_setup_heartbeat_timer()
	if _heartbeat_timer != null and _heartbeat_timer.is_stopped():
		_heartbeat_timer.start()
	_send_heartbeat()

func _stop_heartbeat() -> void:
	if _heartbeat_timer != null:
		_heartbeat_timer.stop()

func _on_heartbeat_timeout() -> void:
	_send_heartbeat()

func _send_heartbeat() -> void:
	if not _is_remote_connected:
		return
	if local_game_save == null:
		return
	if local_game_save.player_id == "":
		return

	var module_client = _get_module_client()
	if module_client == null:
		return
	if not module_client.reducers.has_method("heartbeat_player"):
		return

	local_game_save.last_seen_unix_ms = Time.get_unix_time_from_system() * 1000
	module_client.reducers.heartbeat_player(local_game_save.player_id, local_game_save.last_seen_unix_ms)
