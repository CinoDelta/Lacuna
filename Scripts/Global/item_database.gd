extends Node

#Encompasses 
var ITEM_DATABASE = {
	#Sample Item:
	# All different Item IDS:
	# 1: Generic Healing item. Needs USE_TEXT, SPECIAL_DATA.Health_Recovered, and SPECIAL_DATA.Target
	# 2: Generic Attack item. Animation depends on item NAME. needs same info as id 2,
	# except replace Health_Recovered with Health_Removed
	# All different Item TYPES:
	# 1: Battle item. 
	# 2: Armour items
	# 3: Weapon items - if its a weapon then special data will contain the Hand it is equipped to. (mainHand, offHand)
	# 4: Amulet items
	# 5: Ring items
	# 6: KEY items
	# String parsers for use text:
	# %s: reciever of health, reciever of equipped armour or weapon, reciever in any context.
	# %u: %s but the user.
	# Type of Targets
	# OnePlayer
	# AllPlayers
	# OneEnemy
	# AllEnemies
	
	"NONE" = {
		"NAME" = "NONE",
		"DESCRIPTION" = "NONE",
		"ID" = 0, 
		"TYPE" = 1,
		"USE_TEXT" = "NONE",
		"SPECIAL_DATA" = {
			"Hand" = "NONE",
			"WeaponType" = "NONE",
			"Buffs" = {
				"ATTACK" = 0,
				"DEFENSE" = 0,
				"MAGIC" = 0,
				"SPEED" = 0,
				"RESISTANCES" = {
					"FIRE" = 0
				},
				"ABILITIES" = {} # none
			}
		}
	},
	
	"TEST" = {
		"NAME" = "Test Item",
		"DESCRIPTION" = "The best item to ever exist. Heals 30 HP of one party member.",
		"ID" = 1, # IDS are used in the ATTACK function to identify what to do with an item.
		"TYPE" = 1,
		"USE_TEXT" = "%u used the Test Item!",
		"SPECIAL_DATA" = {
			"Health_Recovered" = 30,
			"Target" = "OnePlayer"
		}
	},
	"POWER_BOMB" = {
		"NAME" = "Power Bomb",
		"DESCRIPTION" = "A bomb containing a bit of ???'s power. Does 50 damage to all enemies.",
		"ID" = 2, # IDS are used in the ATTACK function to identify what to do with an item.
		"TYPE" = 1,
		"USE_TEXT" = "%u used the Power Bomb!",
		"SPECIAL_DATA" = {
			"Health_Removed" = 50,
			"Target" = "AllEnemies"
		}
	},
	
	"WOODEN_SWORD" = {
		"NAME" = "Wooden Sword",
		"DESCRIPTION" = "A useless sword. +3 ATTACK when equipped.",
		"ID" = 3, 
		"TYPE" = 2,
		"USE_TEXT" = "%u equipped the wooden sword!",
		"SPECIAL_DATA" = {
			"Hand" = "mainHand",
			"WeaponType" = "Sword",
			"Buffs" = {
				"ATTACK" = 3,
				"DEFENSE" = 0,
				"MAGIC" = 0,
				"SPEED" = 0,
				"RESISTANCES" = {
					"FIRE" = 0
				},
				"ABILITIES" = {} # none
			}
		}
	}
}

#Inventory service functions

var uidPullTable = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

func getRandomUID():
	var rng = RandomNumberGenerator.new()
	var randUID = ""
	for i in range(0, 6):
		randUID = randUID + uidPullTable[rng.randi_range(0, 15)]
	print(randUID)
	return randUID
	
func createNewItem(itemName):
	if ITEM_DATABASE.has(itemName) == false:
		print("no key was found") 
		return
	var itemData = ITEM_DATABASE[itemName]
	var packet = {
		"NAME" = itemData["NAME"], 
		"DESCRIPTION" = itemData["DESCRIPTION"],
		"TYPE" = itemData["TYPE"],
		"USE_TEXT" = itemData["USE_TEXT"],
		"SPECIAL_DATA" = itemData["SPECIAL_DATA"],
		"UID" = getRandomUID()
	}
	return packet

# should be a function to calculate item buffs here! (should return a packet table of buffs.
