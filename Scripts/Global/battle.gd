extends Control

# battle text box specifically (local signals)
signal textbox_continued
signal textbox_ended

# selections
signal optionSelected # for basic options and stuff
signal actionDecided # action is fully decided
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
var indexToBattlePosition = [
	Vector2(32, 16), 
	Vector2(-48, 128), 
	Vector2(-56, -80), 
	Vector2(-128, 16), 
	Vector2(592, 160),
	]
var battleData = {}

var currentAttackPacket = {} # will hold the selection of the member who has chosen something to do. might not need?
var currentAttacker = ""
var currentSelection = 1 # For all selection picking other than enemies
var currentItemSelection = Vector2(0, 0) # uses a grid system 

var fieldData = { # field data contains team wide  # ALWAYS Field Name, then number of turns left. If a field is Normal, it cannot be removed.
	# buffs/debuffs are percentage wise buffs that are multiplied to the stat during calculation.
	# if the current buff is one, turns left doesn't go down and the buff is not mentioned before last phase.
#	"PLAYERTEAM" = 
#	{ 
#		"ATTACK" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#		"MAGIC" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#		"DEFENSE" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#		"SPEED" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#		"AETHERGAIN" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#	},
#	"ENEMYTEAM" = 
#	{ 
#		"ATTACK" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#		"MAGIC" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#		"DEFENSE" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#		"SPEED" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#		"AETHERGAIN" = {"CurrentBuff" = 1, "TurnsLeft" = 0},
#	}
	
	# other individual specific buffs are initialized in the function createNewFieldData.
}

var fieldStatus = ["Normal", 0]

var currentEnemies = {}
var amountOfEnemies = 0

# built ins

func _ready(): # void
	
	for child in get_children():
		if child is Panel:
			child.visible = false
	PartyStats.battleStart.connect(battleStarted)
	
	for child in $BackgroundOverlay.get_children():
		child.visible = false
	
func _physics_process(delta):
	emit_signal("physics")
	
# Setup functions


func playerSetup(): #I'll add aniamtion when i feel like it. void.
	
	$PlayerDisplay/Sample.visible = false # just in case i forgot 
	
	var count = 0
	
	for member in PartyStats.currentPartyMembers:
		var newDisplay = $PlayerDisplay/Sample.duplicate()
		
		newDisplay.visible = true
		newDisplay.name = member 
		
		$PlayerDisplay.add_child(newDisplay)
		
		var displayAnimatedSprite:AnimatedSprite2D = get_node("PlayerDisplay/" + member + "/" + "PSprite")
		
		displayAnimatedSprite.sprite_frames = load("res://Assets/Sprites/Battle/DisplaySprites/PartySpriteAnimations/" + member + ".tres")
				
		displayAnimatedSprite.play(StringName("Debug")) # comment when we actually get animations PLACEHOLDER
		
		newDisplay.position = indexToBattlePosition[count]
		
		count += 1
		
		var newStatDisplay = $PlayerPanels/PlayerPanelsContainer/SampleMember.duplicate()
		
		newStatDisplay.visible = true
		newStatDisplay.name = member
		
		$PlayerPanels/PlayerPanelsContainer.add_child(newStatDisplay)
		
		var nameDisplay = get_node("PlayerPanels/PlayerPanelsContainer/" + member + "/" + "Name")
		nameDisplay.text = PartyStats.partyDatabase[member]["NAME"]
		
		createNewFieldData(member, false, newDisplay)
		
		
		
func enemySetup(): # void
	
	$EnemyDisplay/Sample.visible = false # just in case i forgot 
	
	var count = 0
	
	for enemyName in battleData["ENEMIES"]:
		var enemyData = EnemyDatabase.getEnemyFromString(enemyName)
		var indexName = enemyData["NAME"]
		if currentEnemies.has(enemyData["NAME"]):
			var amountOfEnemy = 1
			for enemy in currentEnemies.keys():
				if enemy == enemyName:
					amountOfEnemy += 1
			# Enemy, Enemy 2, Enemy 3, etc. max 4 enemies per battle.
			if amountOfEnemy != 1:
				indexName = indexName + str(amountOfEnemy) 
		currentEnemies[indexName] = enemyData
		currentEnemies[indexName]["NAME"] = indexName
		
		var newDisplay = $EnemyDisplay/Sample.duplicate()
		
		newDisplay.visible = true
		newDisplay.name = indexName 
		
		$EnemyDisplay.add_child(newDisplay)
		
		var displayAnimatedSprite:AnimatedSprite2D = get_node("EnemyDisplay/" + indexName + "/" + "PSprite")
		
		displayAnimatedSprite.sprite_frames = load("res://Assets/Sprites/Battle/DisplaySprites/Enemies/" + enemyName + ".tres")
		
		displayAnimatedSprite.play(StringName("Debug")) # comment when we actually get animations PLACEHOLDER
		
		newDisplay.position = indexToBattlePosition[count+4]
		
		createNewFieldData(indexName, true, newDisplay)
	
	
func createNewFieldData(participant, isEnemy:bool, battleDisplay:Panel): # void
	fieldData[participant] = {
		"CONDITIONS" = { 
			"POISONED" = 0, # conditions are ints, goes down by 1 each turn and is calculated after the attack phase.
			"BURNED" = 0 
		},
		"STAT_BUFFS" = {
			"ATTACK" = {PercentBuff = 1, TurnsLeft = 0},
			"DEFENSE" = {PercentBuff = 1, TurnsLeft = 0},
			"SPEED" = {PercentBuff = 1, TurnsLeft = 0},
			"AETHER_GAIN" = {PercentBuff = 1, TurnsLeft = 0}
		},
		"IS_ENEMY" = isEnemy,
		"TURNS_WAITING" = 0,
		"CONSECUTIVE_TURNS" = 0,
		"BATTLE_DISPLAY" = battleDisplay
	}
	
func removeFieldData(participant):
	fieldData.erase(participant)
	
func refreshSelectionData(): # void
	currentSelection = {}

func playSetupTweens(duration): # void
	
	var optionPanelTween = [
		Vector2(0, -152),
		Vector2(0,0)
	]
	var playerPanelsTween = [
		Vector2(0, 696),
		Vector2(0,528)
	]
	var orderPanelTween = [
		Vector2(-80, 192),
		Vector2(0,192)
	]
	
	$OptionsPanel.position = optionPanelTween[0]
	$PlayerPanels.position = playerPanelsTween[0]
	$OrderPanel.position = orderPanelTween[0]

	var tweenOptions = get_tree().create_tween()
	tweenOptions.tween_property($OptionsPanel, "position", optionPanelTween[1], duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	
	var tweenPlayerInfo = get_tree().create_tween()
	tweenPlayerInfo.tween_property($PlayerPanels, "position", playerPanelsTween[1], duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	
	var tweenOrderPanel = get_tree().create_tween()
	tweenOrderPanel.tween_property($OrderPanel, "position", orderPanelTween[1], duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await tweenOrderPanel.finished
	
func setUpBattle(battleId): # void
	
		
	
	battleData = BattleDatabase.battleIdInfo[str(get_meta("battleId"))]
	
	get_node("BackgroundOverlay/" + battleData["BACKGROUND"]).visible = true
	
	await get_tree().create_timer(2)
	
	refreshSelectionData()
	
	playerSetup()
	enemySetup()
	
	PartyStats.inBattle = true
	
	await get_tree().create_timer(2)
	
	

	
	await playSetupTweens(.5)
	
	await get_tree().create_timer(4.0)
	

	
	
	
	MusicManager.loadMusic("res://Assets/Sounds/RottensApproaching.ogg")
	MusicManager.setVolume(0.3)
	MusicManager.play()
	
	await display_text(battleData["START_TEXT"], Vector2(576, 60), Vector2(0, 30))
	
# ui getters

func getPlayerDisplayFromName(memberName:String): # Panel
	return get_node("PlayerDisplay/" + memberName)
	
func getEnemyDisplayFromName(enemyName:String): # Panel
	return get_node("EnemyDisplay/" + enemyName)
	
# very very very important battle functions

var turnOrder = []

func calculateOrder(refreshOrder, numOfTurns):
	
	turnOrder = [] if refreshOrder else turnOrder
	
	# pre calculation (Are there people that haven't moved for 5 turns
	
	var peopleWaitingTooLong = []
	var turnThreshold = 5
	
	for i in range(0, numOfTurns):
		# if there are ever more than 5 participants in the battle, threshold will be increased.
		if fieldData.keys().size() > 5:
			turnThreshold += fieldData.keys().size() - 5
		
		for participant in fieldData:
			if fieldData[participant]["TURNS_WAITING"] >= 5:
				peopleWaitingTooLong.append(participant)
				
		if peopleWaitingTooLong.size() > 0:
			turnOrder.insert(0, peopleWaitingTooLong.pick_random()) # if theres one, it picks that no matter what. if theres more than that, it just picks random.
		else:
			# main calculation
			print("main calculation")
			var weightedChanceTable = {}
			var totalWeight = 0
			var currentWeight = 0
			
			for participant in fieldData:
				var randSpeedAlter = randf_range(0.9, 1.1)
				
				var secondSpeedAlter = 1.0
				
				match fieldData[participant]["CONSECUTIVE_TURNS"]:
					1:
						secondSpeedAlter = 0.65
					2:
						secondSpeedAlter = 0.40
				
				secondSpeedAlter = 0 if fieldData[participant]["CONSECUTIVE_TURNS"] >= 3 else secondSpeedAlter
				
#				print("PARTICIPANT: " + str(participant))
#				print("Consecutive turns is " + str(fieldData[participant]["CONSECUTIVE_TURNS"]))
#				print("Altering is " + str(secondSpeedAlter))
				
				var participantSpeed
				
				# this exists for more variability, especially early game!
				var uniformSpeedMultiplier = 5
				
				if fieldData[participant]["IS_ENEMY"]:
					participantSpeed = currentEnemies[participant]["SPEED"] * uniformSpeedMultiplier
				else:
					participantSpeed = PartyStats.partyDatabase[participant]["SPEED"] * uniformSpeedMultiplier
				
				participantSpeed *= randSpeedAlter
				participantSpeed *= secondSpeedAlter
				
				participantSpeed = roundi(participantSpeed)
				
				weightedChanceTable[participant] = participantSpeed
				totalWeight += participantSpeed
				
			var randWeight = randf_range(0, totalWeight)
			print("The random weight is " + str(randWeight))
			
			print(weightedChanceTable)
			for participant in weightedChanceTable:
				if randWeight <= weightedChanceTable[participant] + currentWeight:
					var tempArray = [participant]
					print("the person picked is: " + participant)
					tempArray.append_array(turnOrder)
					turnOrder = tempArray
					print(turnOrder)
					for person in fieldData:
						if person != participant:
							fieldData[person]["TURNS_WAITING"] += 1
							fieldData[person]["CONSECUTIVE_TURNS"] = 0
					fieldData[participant]["TURNS_WAITING"] = 0
					fieldData[participant]["CONSECUTIVE_TURNS"] += 1
					break
				else:
					currentWeight += weightedChanceTable[participant]
				print("The currentweight is" + str(currentWeight))
			
			
# Ok lets deisgn the attack data packet!

#var attackPacket = {
#	# First, it should contain the FIELD DATA of the person.
#	"ATTACKER_FIELD_DATA" = {
#		"CONDITIONS" = { 
#			"POISONED" = 0,
#			"BURNED" = 0 
#		},
#		"STAT_BUFFS" = {
#			"ATTACK" = {PercentBuff = 1, TurnsLeft = 0},
#			"DEFENSE" = {PercentBuff = 1, TurnsLeft = 0},
#			"SPEED" = {PercentBuff = 1, TurnsLeft = 0},
#			"AETHER_GAIN" = {PercentBuff = 1, TurnsLeft = 0}
#		},
#		"IS_ENEMY" = isEnemy,
#		"TURNS_WAITING" = 0,
#		"CONSECUTIVE_TURNS" = 0,
#		"BATTLE_DISPLAY" = battleDisplay
#	},
#	# this will fill in any missing data. and since field data isn't being changed in the attack function, we can use this 
#	# as a getter.
#
#	# Next there should probably be an ACTION table.
#
#	"ACTION" = {
#		"PRIMARY_ACTION" = "", # Can be: BasicAttack, SpecialAttack, Item, Defend. 
#		# leave blank if the thing being done doesn't require a target, or is targeting all enemies.
#		# Target should contain the participant's name, as with that we can get if they're an enemy or not from
#		# field data, and get stats from there.
#		"TARGET" = "",
#		"EXTRA_DATA" = {} # Extra Data that can be passed if needed, depending on the skill being used. Allows for expandability on the system.
#	}
#}

func attack(attackDataPacket):
	pass

# functions that are run until an action is decided! Only for the player's party.

func basicSelection(memberName, memberFieldData):
	
	currentSelection = 1
	battlePhase = battlePhases.SelectingBasics
	
	var highlight = get_node(str(memberFieldData["BATTLE_DISPLAY"].get_path()) + "/PSprite/Highlight")
	
	var highlightTween = get_tree().create_tween()
	
	highlightTween.tween_property(highlight, "color", Color(1, 1, 1, 0.5), 1)
	highlightTween.tween_property(highlight, "color", Color(1, 1, 1, 0), 1)
	
	highlightTween.set_loops()
	
	
	await optionSelected
	
	highlightTween.kill()

	pass
	


func battleStarted(id): # void, main battle loop as well.
	$BattleIntro.play()
	$BattleIntro.get_path()
	
	var isBattleOver = false
	var isFirstTurn = true
	
	await get_tree().create_timer(3.8).timeout
	
	for child in get_children():
		if child is Panel and child.name != "TextBoxPanel":
			child.visible = true
			
			
	await setUpBattle(id)
	
	await calculateOrder(true, 4)
	
	
	while !isBattleOver:
		# At the start of each loop, figure out which person is supposed to move based on calculate order.
		
		if !isFirstTurn:
			calculateOrder(false, 1)
		
		currentAttacker = turnOrder.back()
		turnOrder.remove_at(turnOrder.size() - 1)
		
		var attackerFieldData = fieldData[currentAttacker] # for getting. for setting, just get index normally.
		
		if !attackerFieldData["IS_ENEMY"]:
			# run the code for it being a player.
			basicSelection(currentAttacker, attackerFieldData)
			
			print("ittsss " + currentAttacker + "'s turn!")
			await actionDecided
		else:
			# run the code for it being an enemy
			print("pretend the enemy went")
			pass
			
		
		isFirstTurn = false

	
# ui functions

func display_text(textArray:Array, boxSize:Vector2, boxPosition:Vector2):
	
	var totalText = textArray.size()
	var textBackground = $TextBoxPanel/Background
	var textBoxText = $TextBoxPanel/Background/TexboxText
	
	textBackground.size = Vector2(boxSize.x, 0)
	textBoxText.text = ""
	

	$TextBoxPanel.show()
	
	var newTween = get_tree().create_tween()
	newTween.tween_property(textBackground, "size", boxSize, .15)
	
	await get_tree().create_timer(.15).timeout
	

	$TextBoxPanel/Background/TexboxText.show()
	
	for i in range(0, totalText):
		$TextBoxPanel/Background/TexboxText.text = textArray[i]
		print(textBoxText.text)
		
		var allCharacters = $TextBoxPanel/Background/TexboxText.get_total_character_count()
		
		for v in range(0, allCharacters + 1):
			$TextBoxPanel/Background/TexboxText.visible_characters = v

			if $TextBoxPanel/Background/TexboxText.text[v-1] == "." or $TextBoxPanel/Background/TexboxText.text[v-1] == ",":
				for j in range(0, 10):
					await physics
					await physics
			else:
				await physics
				await physics
			
			$TextBoxPanel/Background/TexboxText/textBox.play()
		await textbox_continued
	
		$Select.play()
	$TextBoxPanel.hide()
	emit_signal("textbox_ended")
	
func resetSelectionHighlights(): #void
	for child in $OptionsPanel/OptionsContainer.get_children():
		var borderHighlight:TextureRect = get_node(str(child.get_path()) + "/Highlight")
		borderHighlight.texture = load("res://Assets/Sprites/Battle/DisplaySprites/Selections/Selection.png")

func _process(delta): # void 
	
	# keys
	
	# CONFIRM
	if Input.is_action_just_pressed("Confirm"):
		if PartyStats.inBattle == false and PartyStats.debug == true:
			PartyStats.battleStart.emit(1)
			$Select.play()
		elif $TextBoxPanel.visible == true:
			emit_signal("textbox_continued")
	elif Input.is_action_just_pressed("ui_left"):
		match battlePhase:
			battlePhases.SelectingBasics:
				currentSelection = 4 if currentSelection == 1 else currentSelection - 1
	elif Input.is_action_just_pressed("ui_right"):
		match battlePhase:
			battlePhases.SelectingBasics:
				currentSelection = 1 if currentSelection == 4 else currentSelection + 1
	
	# Selection highlights
	if battlePhase == battlePhases.SelectingBasics:
		var boxCounter = 1
		for child in $OptionsPanel/OptionsContainer.get_children():
			var borderHighlight:TextureRect = get_node(str(child.get_path()) + "/Highlight")
			borderHighlight.texture = load("res://Assets/Sprites/Battle/DisplaySprites/Selections/HighlightedSelection.png") if boxCounter == currentSelection else load("res://Assets/Sprites/Battle/DisplaySprites/Selections/Selection.png")
			boxCounter += 1
	
	# UI displays
	if PartyStats.inBattle == true:
		for panel in $PlayerPanels/PlayerPanelsContainer.get_children():
			if panel.name != "SampleMember":
				var partyMemStats = PartyStats.partyDatabase[panel.name]
				var rootPath = "PlayerPanels/PlayerPanelsContainer/" + panel.name + "/"
				
				var hpDisplay = get_node(rootPath + "HPDisplay")
				var aetherDisplay = get_node(rootPath + "ManaDisplay")
				var hpBarDisplay = get_node(rootPath + "HP")
				var aetherBarDisplay = get_node(rootPath + "AETHER")
				
				hpDisplay.text = str(partyMemStats["HP"]) + "/" + str(partyMemStats["MAX_HP"])
				aetherDisplay.text = str(partyMemStats["AETHER"] * 100) + "%"
				
				aetherBarDisplay.value = partyMemStats["AETHER"] 
				hpBarDisplay.max_value = partyMemStats["MAX_HP"]
				hpBarDisplay.value = partyMemStats["HP"]
				
				
				
				
