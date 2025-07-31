extends Node

# Naming convention: 
var enemiesInfo = {
	"DebugBoy" = {
		"NAME" = "Debug Boy",
		"MAX_HP" = 20,
		"HP" = 20,
		"VITALITY" = 2,
		"ATTACK" = 20,
		"DEFENSE" = 10,
		"SPEED" = 20,
		"MAGIC" = 20,
		"AETHER" = 1, 
		"AETHER_GAIN" = 7,
		"TYPEMODIFIERS" = {
			"FIRE" = 0.5 # 50% less damage taken from fire based moves (will add more later
		}
	}
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func getEnemyFromString(enemyName): #for readability
	return enemiesInfo[enemyName]
