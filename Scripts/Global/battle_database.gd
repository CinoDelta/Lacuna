extends Node

# Naming convention: lowercase with _ between words
var battleIdInfo = {
	"1" = {
		"ENEMIES" = ["DebugBoy"], # String[]
		"BACKGROUND" = "Basic", # String
		"START_TEXT" = ["Bugs crawl inside your skin. You must be debugged."]
		"EXP" = 10, # int
	}
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func getBattleInfoFromId(id):
	return battleIdInfo[str(id)]
