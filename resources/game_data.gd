class_name GameData
extends Resource

# initial global game data
@export var player_id: String = "" # canonical player id (server-owned when available)
@export var browser_fingerprint: String = "" # unstable browser/device fingerprint used as auxiliary metadata
@export var display_name: String = "newb_1337"
@export var device_id: String = "desktop_newb_1337" # unique identifier for the player's device, used for saving/loading game data
@export var guild: String = "red"
@export var role: String = "warrior"
@export var player_state: String = "idle"
@export var player_global_position: Vector2 = Vector2(0, 0)
@export var last_seen_unix_ms: int = 0
