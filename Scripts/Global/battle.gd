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
# battle minigames
signal minigameConfirm
signal minigameCancel

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
	# mingame shit
	SwordMinigame,
}

var battlePhase = battlePhases.Starting
var indexToBattlePosition = [
	Vector2(32, 16), 
	Vector2(-48, 128), 
	Vector2(-56, -80), 
	Vector2(-128, 16), 
	Vector2(592, 160),
	Vector2(664, 272),
	Vector2(648, 32)
	]
var battleData = {}

var currentAttackPacket = {
	"ATTACKER_FIELD_DATA" = {
		"CONDITIONS" = { 
			"POISONED" = 0,
			"BURNED" = 0 
		},
		"STAT_BUFFS" = {
			"ATTACK" = {PercentBuff = 1, TurnsLeft = 0},
			"DEFENSE" = {PercentBuff = 1, TurnsLeft = 0},
			"SPEED" = {PercentBuff = 1, TurnsLeft = 0},
			"AETHER_GAIN" = {PercentBuff = 1, TurnsLeft = 0}
		},
		"IS_ENEMY" = false,
		"TURNS_WAITING" = 0,
		"CONSECUTIVE_TURNS" = 0,
		"BATTLE_DISPLAY" = ""
	},
	# this will fill in any missing data. and since field data isn't being changed in the attack function, we can use this 
	# as a getter.

	# Next there should probably be an ACTION table.

	"ACTION" = {
		"PRIMARY_ACTION" = "", # Can be: BasicAttack, SpecialAttack, Item, Defend. 
		# leave blank if the thing being done doesn't require a target, or is targeting all enemies.
		# Target should contain the participant's name, as with that we can get if they're an enemy or not from
		# field data, and get stats from there.
		"TARGET" = "",
		"EXTRA_DATA" = {} # Extra Data that can be passed if needed, depending on the skill being used. Allows for expandability on the system.
	}
} # will hold the selection of the member who has chosen something to do. 

var currentAttacker = ""
var currentSelection = 1 # For basic selection picking

var selectionTracker = { # this is so that it saves when you go back to the selection :>
	"ENEMY_SELECTION" = 1,
	"ITEM_SELECTION" = Vector2(0,0),
	"SPECIAL_SELECTION" = 1
} 

var optionStatus = false

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

# more minigame bools
var minigameHasConfirmed = false
var currentMinigameData = {}

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
	match battlePhase:
		battlePhases.SwordMinigame:
			currentMinigameData["framesSinceMiss"] += 1
	
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
				
		displayAnimatedSprite.play(StringName("Idle")) # comment when we actually get animations PLACEHOLDER
		
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
		print("enemy ")
		var enemyData = EnemyDatabase.getEnemyFromString(enemyName)
		var indexName = enemyData["NAME"]
		print("actual name is " + indexName)
		if currentEnemies.keys().has(indexName):
			var amountOfEnemy = 1
			for enemy in currentEnemies.keys():
				if enemyData["NAME"] in enemy:
					amountOfEnemy += 1
			# Enemy, Enemy 2, Enemy 3, etc. max 4 enemies per battle.
			print(amountOfEnemy)
			indexName = indexName + str(amountOfEnemy)
		print("new name is " + indexName)
		currentEnemies[indexName] = enemyData
		
		var newDisplay = $EnemyDisplay/Sample.duplicate()
		
		newDisplay.visible = true
		newDisplay.name = indexName 
		
		$EnemyDisplay.add_child(newDisplay)
		
		var displayAnimatedSprite:AnimatedSprite2D = get_node("EnemyDisplay/" + indexName + "/" + "PSprite")
		
		displayAnimatedSprite.sprite_frames = load("res://Assets/Sprites/Battle/DisplaySprites/Enemies/" + enemyName + ".tres")
		
		displayAnimatedSprite.play(StringName("Debug")) # comment when we actually get animations PLACEHOLDER
		
		newDisplay.position = indexToBattlePosition[count+4]
		
		createNewFieldData(indexName, true, newDisplay)
		
		count += 1
	
	
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
	
func playSetupTweens(duration): # void
	

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
	
func tweenOptions(goIn, duration):
	if goIn == true:
		$OptionsPanel.position = optionPanelTween[0]
		var tweenOptions = get_tree().create_tween()
		tweenOptions.tween_property($OptionsPanel, "position", optionPanelTween[1], duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		$OptionsPanel.position = optionPanelTween[1]
		var tweenOptions = get_tree().create_tween()
		tweenOptions.tween_property($OptionsPanel, "position", optionPanelTween[0], duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
func setUpBattle(battleId): # void
	
		
	
	battleData = BattleDatabase.battleIdInfo[str(get_meta("battleId"))]
	
	get_node("BackgroundOverlay/" + battleData["BACKGROUND"]).visible = true
	
	await get_tree().create_timer(2)
	
	playerSetup()
	enemySetup()
	
	PartyStats.inBattle = true
	
	await get_tree().create_timer(2)
	
	

	
	await playSetupTweens(.5)
	
	await get_tree().create_timer(4.0)
	

	
	
	
	MusicManager.loadMusic("res://Assets/Sounds/WallowingWisps.ogg")
	MusicManager.setVolume(1.2)
	MusicManager.play()
	
	await display_text(battleData["START_TEXT"], Vector2(576, 60), Vector2(0, 30))
	
# ui getters

func getPlayerDisplayFromName(memberName:String): # Panel
	return get_node("PlayerDisplay/" + memberName)
	
func getEnemyDisplayFromName(enemyName:String): # Panel
	return fieldData[enemyName]["BATTLE_DISPLAY"]
	
func getEnemyFromSelection(): # String
	print(selectionTracker["ENEMY_SELECTION"])
	for child in $OptionsPanel/SubMenu/DisplayEnemyInfo.get_children():
		if child.name != "SampleEnemyInfo":
			print("not sample")
			print(child.get_meta("SelectionOrder"))
			if child.get_meta("SelectionOrder") == selectionTracker["ENEMY_SELECTION"]:
				print("selected")
				return child.name
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
			#print("main calculation")
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
			#print("The random weight is " + str(randWeight))
			
			#print(weightedChanceTable)
			for participant in weightedChanceTable:
				if randWeight <= weightedChanceTable[participant] + currentWeight:
					var tempArray = [participant]
					#print("the person picked is: " + participant)
					tempArray.append_array(turnOrder)
					turnOrder = tempArray
					#print(turnOrder)
					for person in fieldData:
						if person != participant:
							fieldData[person]["TURNS_WAITING"] += 1
							fieldData[person]["CONSECUTIVE_TURNS"] = 0
					fieldData[participant]["TURNS_WAITING"] = 0
					fieldData[participant]["CONSECUTIVE_TURNS"] += 1
					break
				else:
					currentWeight += weightedChanceTable[participant]
				#print("The currentweight is" + str(currentWeight))
			
			
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

func attack(attacker, attackDataPacket):
	
	# some useful info
	var attackerFieldData = attackDataPacket["ATTACKER_FIELD_DATA"]
	var attackerAction = attackDataPacket["ACTION"]
	var isEnemy = attackerFieldData["IS_ENEMY"]
	
	var attackerSprite = get_node(str(attackerFieldData["BATTLE_DISPLAY"].get_path()) + "/PSprite")
	
	var target = attackerAction["TARGET"]
	var targetFieldData
	var targetDisplay
	
	if target != "":
		print("target")
		targetFieldData = fieldData[target]
		targetDisplay = targetFieldData["BATTLE_DISPLAY"]
	
	# I think ill split it like -> basic action -> nuances... -> player/enemy split
	
	match attackerAction["PRIMARY_ACTION"]:
		"BasicAttack":
			if !isEnemy:
				
				var weapon = PartyStats.partyDatabase[attacker]["EQUIPMENT"]["WEAPON"]
				var weaponType = ItemDatabase.ITEM_DATABASE[weapon]["SPECIAL_DATA"]["WeaponType"]
				# minigames 
				
				var specialWeapons = []
				
				var minigamePoints = 0
				
				attackerSprite.play(StringName("AttackHold"))
				
				if !(weapon in specialWeapons):
					match weaponType:
						"Sword":
							
							currentMinigameData = {
								"currentDirection" = "up",
								"currentSprite" = $Select,
								"framesSinceMiss" = 100
							}
							
							var comboNumber = 6
							var comboSpeedMulti = 0.85 # LOWER MEANS FASTER
							
							battlePhase = battlePhases.SwordMinigame
							var differentCombinations = {"ui_up" = 0, "ui_right" = 90, "ui_down" = 180, "ui_left" = 270} 
							
							var randomCombo = []
							
							for num in range(0, comboNumber):
								randomCombo.insert(num, differentCombinations.keys().pick_random())
							
							# first frame of animation here:
							
							# tweening minigame panel to expand
							$MinigamePanel.visible = true
							$MinigamePanel.position = targetDisplay.global_position + Vector2(-$MinigamePanel.size.x, -$MinigamePanel.size.y/2)
							$MinigamePanel.scale = Vector2(0, 1)
							
							var panelTween = get_tree().create_tween().tween_property($MinigamePanel, "scale", Vector2(1,1), 0.75).set_trans(Tween.TRANS_QUAD)
							
							await panelTween.finished
							
							var comboSprites = []
							
							var thresholds = { # if x is greater than threshold then its that judgment. loops through
								"Miss" = 0,
								"Okay" = 200,
								"Good" = 344,
								"Perfect" = 418
							}
							
							var points = {
								"Miss" = 0,
								"Okay" = 40,
								"Good" = 50,
								"Perfect" = 60
							}
							
							var spriteIndex = 0
							
							
							for direction in randomCombo:
								
								var newCommandSprite = $MinigamePanel/SampleCommand.duplicate()
								$MinigamePanel.add_child(newCommandSprite)
								
								newCommandSprite.position = Vector2(20, 40)
								newCommandSprite.scale = Vector2(0, 0)
								newCommandSprite.rotation_degrees = differentCombinations[direction]
								newCommandSprite.set_meta("Direction", direction)
								newCommandSprite.name = direction + str(randi_range(0, 9999999))
								
								comboSprites.insert(spriteIndex, newCommandSprite)
								spriteIndex += 1
								
							
							var i = 0
							var swordMinigameCompleted = false
							
							var spawnSprite = func(sprite, index):
								print("SPAWNING SPRITE")
								minigameHasConfirmed = false
								
								
								
								sprite.visible = true
								
								
								
								var scaleTween = get_tree().create_tween()
								scaleTween.tween_property(sprite, "scale", Vector2(2, 2), 0.3 * comboSpeedMulti).set_trans(Tween.TRANS_QUAD)
								
								var positionTween = get_tree().create_tween()
								positionTween.tween_property(sprite, "position", Vector2(470, 32), 0.8 * comboSpeedMulti).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
								
								if index > 0:
									if randomCombo[index-1] != "":
										print("i am waiting")
										await minigameCancel
										print("done waiting")
									
								var currentSprite = sprite
								
								
								currentMinigameData["currentSprite"] = currentSprite
								currentMinigameData["currentDirection"] = currentSprite.get_meta("Direction")
								
										
								await minigameConfirm
								positionTween.kill()
								randomCombo[index] = ""
								
								var scaleTween2 = get_tree().create_tween()
								scaleTween2.tween_property(currentSprite, "scale", Vector2(4, 4), 0.3).set_trans(Tween.TRANS_QUAD)
								
								var transparencyTween = get_tree().create_tween()
								transparencyTween.tween_property(currentSprite, "modulate", Color(1, 1, 1, 0), 0.5).set_trans(Tween.TRANS_QUAD)
								
								var pointsGained = 0
								var judgementDecided = "Miss"
								var tintSprite = get_node(str(sprite.get_path()) + "/Tint")
								
								if minigameHasConfirmed == true:
									for judgement in thresholds:
										if currentSprite.position.x > thresholds[judgement]:
											judgementDecided = judgement
								
								pointsGained = points[judgementDecided]
								minigamePoints += pointsGained
								
								if judgementDecided != "Miss":
									$ComboHit.play()
									print(judgementDecided)
								else:
									print(judgementDecided)
									
								
								var judgementToColor = {
									"Miss" = Color(0.97, 0, 0, 0.5),
									"Okay" = Color(0.97, 0.94, 0, 1),
									"Good" = Color(0, 0.92, 0.25, 1),
									"Perfect" = Color(0.32, 1, 0.92, 0.5)
								}
								
								print(tintSprite.color)
								var tintTween = get_tree().create_tween()
								tintTween.tween_property(tintSprite, "color", judgementToColor[judgementDecided], 0.125).set_trans(Tween.TRANS_QUAD)
								
								print('completed')
								
								
								
								if index >= comboNumber - 1:
									print("emitted ")
									emit_signal("attackedEnded")
								
								await get_tree().create_timer(0.1).timeout
								emit_signal("minigameCancel")
								randomCombo[index] = ""
								print(tintSprite.color)
							
							for sprite in comboSprites:
								if i > 0:
									await get_tree().create_timer(randf_range(0.4, 0.6) * comboSpeedMulti).timeout
								spawnSprite.call(sprite, i)
#								print("cancel minigame")
#								emit_signal("minigameCancel")
								i += 1
								
									
							await attackedEnded
							
							var panelTween2 = get_tree().create_tween().tween_property($MinigamePanel, "scale", Vector2(0,1), 0.75).set_trans(Tween.TRANS_QUAD)
							
							await get_tree().create_timer(0.5).timeout
							
							attackerSprite.play("Attack")
							$SlashHit.play()
							
							await attackerSprite.animation_finished
							
							for sprite in comboSprites:
								$MinigamePanel.remove_child(sprite)
							
							await get_tree().create_timer(1000.0).timeout
							
						
			else:
				var attackMessage = attackerAction["EXTRA_DATA"]["ENEMY_ATTACK_MESSAGE"]
				pass
# functions that are run until an action is decided! Only for the player's party.

func basicSelection(memberName, memberFieldData):# this just keeps getting passed down (parameters) for special and item selection specifically
	
	
	if $OptionsPanel.position != optionPanelTween[1]:
		tweenOptions(true, .5)
		
	resetCurrentAttackPacket()
	
	$OptionsPanel/SubMenu.visible = false
	optionStatus = false
	battlePhase = battlePhases.SelectingBasics
	
	var highlight = get_node(str(memberFieldData["BATTLE_DISPLAY"].get_path()) + "/PSprite/Highlight")
	
	var highlightTween = get_tree().create_tween()
	
	highlightTween.tween_property(highlight, "color", Color(1, 1, 1, 0.5), 1)
	highlightTween.tween_property(highlight, "color", Color(1, 1, 1, 0), 1)
	
	highlightTween.set_loops()
	
	await buffer(.3)
	await optionSelected
	
	highlightTween.kill()
	highlight.color = Color(1, 1, 1, 0)
	# option status HAS to be true, there is no backing out of basic options
	
	if currentSelection == 1:
		$Select.play()
		currentAttackPacket["ACTION"]["PRIMARY_ACTION"] = "BasicAttack"
		selectEnemy(memberName, memberFieldData)
	else:
		basicSelection(memberName, memberFieldData)
	

func selectEnemy(memberName, memberFieldData):
	
	$OptionsPanel/SubMenu.visible = true
	optionStatus = false
	battlePhase = battlePhases.SelectingEnemyParticipator
	
	refreshEnemySelectionInfo()
	refreshEnemySelectionHighlights()
	
	await optionSelected
	
	if optionStatus == true:
		# turn should always end with selecting an enmy/player.
		currentAttackPacket["ACTION"]["TARGET"] = getEnemyFromSelection()
		emit_signal("actionDecided")
		tweenOptions(false, .5)
	else:
		basicSelection(memberName, memberFieldData) 
		
	$OptionsPanel/SubMenu.visible = false
	
	clearEnemyHighlights()
	

# util

func buffer(time):
	await get_tree().create_timer(time).timeout
	
func resetCurrentAttackPacket(): # void
	currentAttackPacket = {
		"ATTACKER_FIELD_DATA" = {
			"CONDITIONS" = { 
				"POISONED" = 0,
				"BURNED" = 0 
			},
			"STAT_BUFFS" = {
				"ATTACK" = {PercentBuff = 1, TurnsLeft = 0},
				"DEFENSE" = {PercentBuff = 1, TurnsLeft = 0},
				"SPEED" = {PercentBuff = 1, TurnsLeft = 0},
				"AETHER_GAIN" = {PercentBuff = 1, TurnsLeft = 0}
			},
			"IS_ENEMY" = false,
			"TURNS_WAITING" = 0,
			"CONSECUTIVE_TURNS" = 0,
			"BATTLE_DISPLAY" = ""
		},
		"ACTION" = {
			"PRIMARY_ACTION" = "", # Can be: BasicAttack, SpecialAttack, Item, Defend. 
			# leave blank if the thing being done doesn't require a target, or is targeting all enemies.
			# Target should contain the participant's name, as with that we can get if they're an enemy or not from
			# field data, and get stats from there.
			"TARGET" = "",
			"EXTRA_DATA" = {} # Extra Data that can be passed if needed, depending on the skill being used. Allows for expandability on the system.
		}
	}
func battleStarted(id): # void, main battle loop as well.
	$BattleIntro.play()
	$BattleIntro.get_path()
	
	var isBattleOver = false
	var isFirstTurn = true
	
	await get_tree().create_timer(3.8).timeout
	
	for child in get_children():
		if child is Panel and child.name != "TextBoxPanel" and child.name != "MinigamePanel":
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
			print("player attack")
			basicSelection(currentAttacker, attackerFieldData)
			
			
			print("ittsss " + currentAttacker + "'s turn!")
			await actionDecided
			currentAttackPacket["ATTACKER_FIELD_DATA"] = attackerFieldData
			await attack(currentAttacker, currentAttackPacket)
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

func refreshEnemySelectionInfo(): # void 
	
	var displayEnemyInfo = $OptionsPanel/SubMenu/DisplayEnemyInfo
	for panel in displayEnemyInfo .get_children():
		if panel.name != "SampleEnemyInfo":
			displayEnemyInfo.remove_child(panel)
			
	var sampleEnemyInf = $OptionsPanel/SubMenu/DisplayEnemyInfo/SampleEnemyInfo
	
	var count = 1
	
	for enemy in currentEnemies:
		
		var enemyData = fieldData[enemy] # just in case i wanna add more to the enemy display
		
		var newInfo = sampleEnemyInf.duplicate()
		displayEnemyInfo.add_child(newInfo)
		var newInfoText = get_node(str(newInfo.get_path()) + "/EnemyName")
		
		newInfoText.text = enemy
		newInfo.visible = true
		
		newInfo.set_meta("SelectionOrder", count)
		newInfo.name = enemy
		count += 1
		
func refreshEnemySelectionHighlights(): # void
	var displayEnemyInfo = $OptionsPanel/SubMenu/DisplayEnemyInfo
	for panel in displayEnemyInfo.get_children():
		if panel.name != "SampleEnemyInfo":
			var enemyFieldDisplayHighlight = get_node(str(fieldData[panel.name]["BATTLE_DISPLAY"].get_path()) + "/PSprite/Highlight")
			var panelText = get_node(str(panel.get_path()) + "/EnemyName")
			if panel.get_meta("SelectionOrder") == selectionTracker["ENEMY_SELECTION"]:
				panelText.text = "[color=yellow]" + panel.name + "[/color]"
				enemyFieldDisplayHighlight.color = Color(1, 1, 1, 0.5)
			else:
				enemyFieldDisplayHighlight.color = Color(1, 1, 1, 0)
				panelText.text = panel.name
				
func clearEnemyHighlights():
	for enemy in currentEnemies:
		var enemyFieldDisplayHighlight = get_node(str(fieldData[enemy]["BATTLE_DISPLAY"].get_path()) + "/PSprite/Highlight")
		enemyFieldDisplayHighlight.color = Color(1, 1, 1, 0)
		
func _process(delta): # void 
	
	# misc
	var coyoteFramesLeft = 1
	match battlePhase:
		battlePhases.SwordMinigame:
			if currentMinigameData["currentSprite"] != $Select:
				if currentMinigameData["currentSprite"].position.x > 467:
					emit_signal("minigameConfirm")
	# keys
	
	# CONFIRM
	if Input.is_action_just_pressed("Confirm"):
		if PartyStats.inBattle == false and PartyStats.debug == true:
			PartyStats.inBattle = true
			PartyStats.battleStart.emit(1)
			$Select.play()
		elif $TextBoxPanel.visible == true:
			emit_signal("textbox_continued")
		match battlePhase:
			battlePhases.SelectingBasics:
				optionStatus = true
				emit_signal("optionSelected")
			battlePhases.SelectingEnemyParticipator:
				optionStatus = true
				emit_signal("optionSelected")
	# CANCEL
	if Input.is_action_just_pressed("Cancel"):
		match battlePhase:
			battlePhases.SelectingEnemyParticipator: # if below is the same for each phase im going to uniform it
				$Select.play()
				emit_signal("optionSelected")
				optionStatus = false
	# LEFT
	elif Input.is_action_just_pressed("ui_left"):
		match battlePhase:
			battlePhases.SelectingBasics:
				$MenuMovement.play()
				currentSelection = 4 if currentSelection == 1 else currentSelection - 1
			battlePhases.SwordMinigame:
				minigameHasConfirmed = true
				if currentMinigameData["framesSinceMiss"] > 30:
					if currentMinigameData["currentDirection"] == "ui_left" and currentMinigameData["framesSinceMiss"] > 30:
						emit_signal("minigameConfirm")
					else:
						minigameHasConfirmed = false
						emit_signal("minigameConfirm")
						currentMinigameData["framesSinceMiss"] = 0
	# RIGHT
	elif Input.is_action_just_pressed("ui_right"):
		match battlePhase:
			battlePhases.SelectingBasics:
				$MenuMovement.play()
				currentSelection = 1 if currentSelection == 4 else currentSelection + 1
			battlePhases.SwordMinigame:
				minigameHasConfirmed = true
				if currentMinigameData["framesSinceMiss"] > 30:
					if currentMinigameData["currentDirection"] == "ui_right" and currentMinigameData["framesSinceMiss"] > 30:
						emit_signal("minigameConfirm")
					else:
						minigameHasConfirmed = false
						emit_signal("minigameConfirm")
						currentMinigameData["framesSinceMiss"] = 0
	# UP
	elif Input.is_action_just_pressed("ui_up"):
		match battlePhase:
			battlePhases.SelectingEnemyParticipator:
				$MenuMovement.play()
				if selectionTracker["ENEMY_SELECTION"] < 2:
					selectionTracker["ENEMY_SELECTION"] = currentEnemies.keys().size()
				else:
					selectionTracker["ENEMY_SELECTION"] -= 1
				refreshEnemySelectionHighlights()
			battlePhases.SwordMinigame:
				minigameHasConfirmed = true
				if currentMinigameData["framesSinceMiss"] > 30:
					if currentMinigameData["currentDirection"] == "ui_up":
						emit_signal("minigameConfirm")
					else:
						minigameHasConfirmed = false
						emit_signal("minigameConfirm")
						currentMinigameData["framesSinceMiss"] = 0
	# DOWN
	elif Input.is_action_just_pressed("ui_down"):
		match battlePhase:
			battlePhases.SelectingEnemyParticipator:
				$MenuMovement.play()
				if selectionTracker["ENEMY_SELECTION"] + 1 > currentEnemies.keys().size():
					selectionTracker["ENEMY_SELECTION"] = 1
				else:
					selectionTracker["ENEMY_SELECTION"] += 1
				refreshEnemySelectionHighlights()
			battlePhases.SwordMinigame:
				minigameHasConfirmed = true
				if currentMinigameData["framesSinceMiss"] > 30:
					if currentMinigameData["currentDirection"] == "ui_down" and currentMinigameData["framesSinceMiss"] > 30:
						emit_signal("minigameConfirm")
					else:
						minigameHasConfirmed = false
						emit_signal("minigameConfirm")
						currentMinigameData["framesSinceMiss"] = 0
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
				
				
				
				
