extends Node

const GUILDS: Array = [
	"red",
	"black",
	"blue",
	"purple",
	"yellow"
]

const ROLES: Array = [
	"warrior",
	"lancer",
	"archer",
	"monk",
	"pawn"
]

# GUILD COLORS TO COLOR_SWAP SHADDER
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

var COLOR_ONLINE: Color = Color(0.016, 0.89, 0.047)
var COLOR_OFFLINE: Color = Color(0.737, 0.0, 0.0, 1.0)
