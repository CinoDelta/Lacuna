extends Node

# Naming convention: lowercase with _ between words
var battleIdInfo = {
	"1" = {
		enemies = ["TestEnemy"], # String[]
		background = "Basic", # String
		exp = 10, # int
	}
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func getBattleInfoFromId(id):
	return battleIdInfo[str(id)]
