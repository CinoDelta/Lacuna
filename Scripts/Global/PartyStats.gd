extends Node
# battle signals
signal battleStart(id)
signal battleOver
signal playerPositionPacket(currentPos, animation)

# party members
# stats are by no means final
# naming convention: ALL CAPS, _ between words
var partyDatabase = {
	"WeCalledIt" = {
		"NAME" = "???",
		"MAX_HP" = 20,
		"HP" = 20,
		"ATTACK" = 20,
		"DEFENSE" = 10,
		"SPEED" = 20,
		"MAGIC" = 20,
		"AETHER" = 1, # out of a percentage
		"AETHER_GAIN" = 7, # min 2 below max 2 above, divided by 100 before gaining
		"LEVEL" = 1,
		"MAX_EXP" = 20,
		"CURRENT_EXP" = 0,
		"CURRENT_PARTY_POSITION" = "First" # First, Second, Third, etc for placement. Put NONE for them to not be in the party.
	}
}

var inventory = {}

var currentPartyMembers = ["WeCalledIt"] # yes ik party position exists this is for easy access instead of converting to an array the whole time

var inBattle = false

var states = {}

func addItemToInv(itemName): #extends createNewItem
	var newItem = ItemDatabase.createNewItem(itemName) #super
	inventory[newItem["UID"]] = newItem

func removeItemFromInv(UID:String):
	for item in inventory:
		if inventory[item]["UID"] == UID:
			inventory.erase(item)
			break

# getter 
func getPartyStats(member):
	if member != null:	
		return partyDatabase[member]
	return partyDatabase
	
# these are for SCENE SPECIFIC saves, not game saves. do not use as game saves.

func save_state(id: String, state: Dictionary):
	states[id] = state

func purge_state(ids_that_start_with: String):
	var to_erase = []
	for key in states:
		if key.left(len(ids_that_start_with)) == ids_that_start_with:
			to_erase.append(key)

	for key in to_erase:
		states.erase(key)
