extends Control

# textbox
signal textbox_continued
signal textbox_ended

# selections
signal optionSelected
signal participatorSelected

# battle
signal attackedEnded

#built-in
signal physics

enum battlePhases {
	Starting,
	SelectingBasics,
	SelectingSkills,
	SelectingItems,
	SelectingPartyParticipator,
	SelectingEnemyParticipator,
	ExecutingSelection,
}

var battlePhase = battlePhases.Starting
var indexToBattlePosition = [Vector2(32, 16), Vector2(-48, 128), Vector2(-56, -80), Vector2(-128, 16)]
var battleData = {}

var currentSelection = {} # will hold the selection of the member who has chosen something to do.

var fieldData = { # field data contains team wide 
	"FIELD" = ["Normal", 0], # ALWAYS Field Name, then number of turns left. If a field is Normal, it cannot be removed.
	# buffs/debuffs are percentage wise buffs that are multiplied to the stat during calculation.
	# if the current buff is one, turns left doesn't go down and the buff is not mentioned before last phase.
	"PLAYERTEAM" = 
	{ 
		"ATTACK" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
		"MAGIC" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
		"DEFENSE" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
		"SPEED" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
		"AETHERGAIN" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
	},
	"ENEMYTEAM" = 
	{ 
		"ATTACK" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
		"MAGIC" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
		"DEFENSE" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
		"SPEED" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
		"AETHERGAIN" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
	}
	
	# other individual specific buffs are initialized in the function createNewFieldData.
}

var currentEnemies = {}
var amountOfEnemies = 0

func _ready(): # void
	for child in get_children():
		child.visible = false
	PartyStats.battleStart.connect(battleStarted)
	
# Setup functions


func playerSetup(): #I'll add aniamtion when i feel like it. void.
	
	var count = 0
	
	for member in PartyStats.currentPartyMembers:
		var newDisplay = $PlayerDisplay/Sample.duplicate()
		
		newDisplay.visible = true
		newDisplay.name = member 
		var displayAnimatedSprite:AnimatedSprite2D = get_node("PlayerDisplay/" + member + "/" + "PSprite")
		
		match member:
			"WeCalledIt":
				displayAnimatedSprite.play(StringName("Debug"))
		
		displayAnimatedSprite.play(StringName("Debug")) # comment when we actually get animations PLACEHOLDER
		
		newDisplay.position = indexToBattlePosition[count]
		
		$PlayerDisplay.add_child(newDisplay)
		
		count += 1
		
func enemySetup(): # void
	
	var count = 0
	
	for enemyName in battleData["ENEMIES"]:
		var enemyData = EnemyDatabase.getEnemyFromString(enemyName)
		var indexName = enemyData["NAME"]
		if currentEnemies.has(enemyData["NAME"]):
			var amountOfEnemy = 1
			for enemy in currentEnemies.keys():
				if enemy == enemyName:
					amountOfEnemy += 1
			indexName = indexName + str(amountOfEnemy) # Enemy, Enemy 2, Enemy 3, etc. max 4 enemies per battle.
		currentEnemies[indexName] = enemyData
		currentEnemies[indexName]["NAME"] = indexName
		
		createNewFieldData(indexName)
	
	
func createNewFieldData(participant): # void
	fieldData[participant] = {
		"CONDITIONS" = { 
			"POISONED" = 0, # conditions are ints, goes down by 1 each turn and is calculated after the attack phase.
			"BURNED" = 0 
		}
	}
	
func refreshSelectionData(): 
	currentSelection = {}
	
	
func setUpBattle(battleId): # void
	
	battleData = BattleDatabase.battleIdInfo[get_meta("battleId")]
	
	refreshSelectionData()
	
	playerSetup()
	enemySetup()
	
# ui getters

func getPlayerDisplayFromName(memberName:String): # Panel
	return get_node("PlayerDisplay/" + memberName)
	
func getEnemyDisplayFromName(enemyName:String): # Panel
	return get_node("EnemyDisplay/" + enemyName)

func battleStarted(id): # void
	var blacklist = ["TextBoxPanel"]
	for child in get_children():
		if !blacklist.has(child.name):
			child.visible = true
	await setUpBattle(id)
	
# ui functions

func display_text(textArray:Array, boxSize:Vector2, boxPosition:Vector2):
	
	var totalText = textArray.size()
	var textBackground = $TextBoxPanel/Background
	var textBoxText = $TextBoxPanel/Background/TexboxText
	
	textBackground.size = Vector2(boxSize.x, 0)
	
	textBoxText.visible = false
	$TextBoxPanel.show()
	
	var newTween = get_tree().create_tween()
	newTween.tween_property(textBackground, "size", boxSize, .75)
	await newTween
	
	textBoxText.visible = true
	
	for currentText in totalText:
		textBoxText.visible_characters = 0
		textBoxText.text = textArray[currentText]
		
		var allCharacters = textBoxText.get_total_character_count()
		
		for v in allCharacters + 1:
			textBoxText.visible_characters = v
			
			await physics
			await physics
			$DialogueBox/TextContinueSound.play()
		
		await textbox_continued
	
	$DialogueBox.hide()
	emit_signal("textbox_ended")
	
func _process(delta): # void 
	
	# misc keys
	if Input.is_action_just_pressed("Confirm") and PartyStats.inBattle == false and PartyStats.debug == true:
		PartyStats.emit_signal("battleStart")
	
	# Input handling. 
	match battlePhase:
		battlePhases.Starting:
			pass
	
