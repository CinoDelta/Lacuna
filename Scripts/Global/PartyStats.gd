extends Node
# battle signals
signal battleStart(id)
signal battleOver
signal playerPositionPacket(currentPos, animation)

# party members
# stats are by no means final
# naming convention: ALL CAPS, _ between words
var partyDatabase = {
	"Alistair" = {
		"NAME" = "Alistair",
		"MAX_HP" = 20,
		"HP" = 20,
		"VITALITY" = 2,
		"ATTACK" = 3,
		"DEFENSE" = 2,
		"SPEED" = 5,
		"MAGIC" = 4,
		"AETHER" = 1, # out of a percentage
		"AETHER_GAIN" = 7, # min 2 below max 2 above, divided by 100 before gaining
		"LEVEL" = 1,
		"MAX_EXP" = 20,
		"CURRENT_EXP" = 0,
		"CURRENT_PARTY_POSITION" = "First", # First, Second, Third, etc for placement. Put NONE for them to not be in the party.
		"EQUIPMENT" = {
			"WEAPON" = "WOODENSWORD", 
			"ARMOUR" = "NONE",
			"RINGS" = {
				"FIRST" = "NONE",
				"SECOND" = "NONE"
			},
			"AMULETS" = "NONE",
		},
		"SPELLS" = {},
		"DISTRIBUTION" = "Fighter"
	}
}

var wholePartyStats = {
	"GOLD" = 0
}

var storyFlags = {} #flags that are either true or false that effect save data

#Range: 1-7
#None: 0
#Low: 1-2
#Average-Low: 2-3
#Average: 3-4
#Average-High: 4-5
#High: 6-7

#Vitality
#High 2.5
#Average 2
#Low 1.5

#Attack
#Low 13
#Average 20
#High 28

#Defense:
#High 22
#Average 12
#Low 7

var levelUpStatDistribution = {
	"Fighter" = {
		"VITALITY" = 3,
		"ATTACK" = 31,
		"DEFENSE" = 10,
		"MAGIC" = 3,
		"SPEED" = 3
	}
}

var inventory = {}

var currentPartyMembers = ["Alistair"] # yes ik party position exists this is for easy access instead of converting to an array the whole time

var inBattle = false

var debug = true

var states = {}

func addItemToInv(itemName): #extends createNewItem
	var newItem = ItemDatabase.createNewItem(itemName) #super
	inventory[newItem["UID"]] = newItem


func removeItemFromInv(UID:String):
	for item in inventory:
		if inventory[item]["UID"] == UID:
			inventory.erase(item)
			break

# getters 
func getPartyStats(memberName):
	if memberName != null:	
		return partyDatabase[memberName]
	return partyDatabase
	
func canMemberLevelUp(memberName):
	return partyDatabase[memberName]["EXP"] >= partyDatabase[memberName]["MAX_EXP"]
	
func calculateStatIncrease(growthRate, oldLevel, currentStat):
	var variety = 0
	
	if oldLevel + 1 <= 10:
		variety = 5
	elif oldLevel % 4 == 0:
		variety = randi_range(7, 10)
	else: 
		variety = randi_range(3, 6)
		
	return ((growthRate * oldLevel) - ((currentStat - 2) * 10)) * variety/50
	
var statIncreases = [] # debug

func levelUp(memberName):
	
	var statMessages = []
	var statDistribution = levelUpStatDistribution[partyDatabase[memberName]["DISTRIBUTION"]]
	var oldLevel = partyDatabase[memberName]["LEVEL"]
	
	for stat in partyDatabase[memberName]:
		var statVal = partyDatabase[memberName][stat]
		match stat:
			"VITALITY":
				
				var increase = calculateStatIncrease(statDistribution[stat], oldLevel, statVal)

				partyDatabase[memberName]["VITALITY"] += increase
				#print(increase)
				if increase * 11 > 20:
					statMessages.insert(0, "Rock on! Vitality increased by " + str(roundi(increase)) + "!")
				elif (increase * 11) > 2:
					if partyDatabase[memberName]["HP"] < roundi(partyDatabase[memberName]["VITALITY"] * 11):
						partyDatabase[memberName]["HP"] = roundi(partyDatabase[memberName]["VITALITY"] * 11) 
						partyDatabase[memberName]["MAX_HP"] = roundi(partyDatabase[memberName]["VITALITY"] * 11) 
						if roundi(increase) > 0:
							statMessages.insert(0, "Vitality increased by " + str(roundi(increase)) + "!")
				else:
					var hpInc = randi_range(1, 2)
					partyDatabase[memberName]["HP"] += hpInc
					partyDatabase[memberName]["MAX_HP"] += hpInc
				# Otherwise no message :((
				
				#vitalityIncreases.insert(vitalityIncreases.size(), partyDatabase[memberName]["HP"]) #laggy, will be removed after data scraping
			"ATTACK":
				var increase = calculateStatIncrease(statDistribution[stat], oldLevel, statVal)
				
				if roundi(increase) > 0:
					partyDatabase[memberName]["ATTACK"] += roundi(increase)
				#print(increase)
				if increase > 3:
					statMessages.insert(0, "Oh yeah! Attack increased by " + str(roundi(increase)) + "!")
				elif increase > 0:
					statMessages.insert(0, "Attack increased by " + str(roundi(increase)) + "!")
						
				
				#statIncreases.insert(statIncreases.size(), partyDatabase[memberName]["DEFENSE"])
			"DEFENSE":
				var increase = calculateStatIncrease(statDistribution[stat], oldLevel, statVal)
				
				if roundi(increase) > 0:
					partyDatabase[memberName]["DEFENSE"] += roundi(increase)
				#print(increase)
				if increase > 3:
					statMessages.insert(0, "Oh yeah! Defense increased by " + str(roundi(increase)) + "!")
				elif increase > 0:
					statMessages.insert(0, "Defense increased by " + str(roundi(increase)) + "!")
						
						# partyDatabase[memberName]["ATTACK"]
				statIncreases.insert(statIncreases.size(), partyDatabase[memberName]["DEFENSE"])
	partyDatabase[memberName]["LEVEL"] += 1
	partyDatabase[memberName]["CURRENT_EXP"] = 0
	partyDatabase[memberName]["MAX_EXP"] = roundi(partyDatabase[memberName]["LEVEL"] ^ 2.4 + 23)
	if oldLevel == 99:
		print(statMessages)
		print(statIncreases)
		print(range(1, 101))
	
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

func _process(delta):
	if Input.is_action_just_pressed("DebugLevelUp"):
		for i in range(1, 101):
			levelUp("Alistair")
