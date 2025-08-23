extends Node

# BasicAttack effects:
# GroundShockwave
# Normal
var enemiesInfo = {
	"Husk" = {
		"NAME" = "Husk",
		"MAX_HP" = 10,
		"HP" = 10,
		"VITALITY" = 2,
		"ATTACK" = 2,
		"DEFENSE" = 2,
		"SPEED" = 2,
		"MAGIC" = 2,
		"AETHER" = 1, 
		"AETHER_GAIN" = 7,
		"TYPEMODIFIERS" = {
			"FIRE" = 0.5 # 50% less damage taken from fire based moves (will add more later
		},
		"MOVEPOOL" = {
			"ShockwaveAttack" = { # first, the name of the attack
				"TYPE" = "BasicAttack", # the type of attack.
				"CHANCE" = 100, # The chance BEFORE modification based on the status of the enemy.
				"ATTACK_MESSAGE" = "The %u sent a shockwave!", #attack message, u will be replaced by the attacker's name
				"ATTACK_EFFECT" = "GroundShockwave", # the effect of the attack, changes what the attack function does before applying damage
				"ATTACK_LEVEL" = 2 # level of the attack
			}
		},
		"DEATH_MESSAGE" = "%u has been purified!",
		"DEATH_SOUND" = 0
	}
}

var deathSounds = [
	"res://Assets/Sounds/Sfx/Purified.ogg"
]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func getEnemyFromString(enemyName): #for readability
	return enemiesInfo[enemyName]
