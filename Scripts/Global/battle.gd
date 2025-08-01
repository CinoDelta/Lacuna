extends Control

# battle text box specifically (local signals)
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
var indexToBattlePosition = [
	Vector2(32, 16), 
	Vector2(-48, 128), 
	Vector2(-56, -80), 
	Vector2(-128, 16), 
	Vector2(592, 160),
	]
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
			indexName = indexName + str(amountOfEnemy) # Enemy, Enemy 2, Enemy 3, etc. max 4 enemies per battle.
		currentEnemies[indexName] = enemyData
		currentEnemies[indexName]["NAME"] = indexName
		
		createNewFieldData(indexName)
		
		var newDisplay = $EnemyDisplay/Sample.duplicate()
		
		newDisplay.visible = true
		newDisplay.name = indexName 
		
		$EnemyDisplay.add_child(newDisplay)
		
		var displayAnimatedSprite:AnimatedSprite2D = get_node("EnemyDisplay/" + indexName + "/" + "PSprite")
		
		displayAnimatedSprite.sprite_frames = load("res://Assets/Sprites/Battle/DisplaySprites/Enemies/" + enemyName + ".tres")
		
		displayAnimatedSprite.play(StringName("Debug")) # comment when we actually get animations PLACEHOLDER
		
		newDisplay.position = indexToBattlePosition[count+4]
		
		
	
	
func createNewFieldData(participant): # void
	fieldData[participant] = {
		"CONDITIONS" = { 
			"POISONED" = 0, # conditions are ints, goes down by 1 each turn and is calculated after the attack phase.
			"BURNED" = 0 
		}
	}
	
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
	
	MusicManager.loadMusic("res://Assets/Sounds/WeirdOnesApproaching.ogg")
	MusicManager.setVolume(0.7)
	MusicManager.play()
	
	display_text(battleData["START_TEXT"], Vector2(576, 60), Vector2(0, 30))
	
# ui getters

func getPlayerDisplayFromName(memberName:String): # Panel
	return get_node("PlayerDisplay/" + memberName)
	
func getEnemyDisplayFromName(enemyName:String): # Panel
	return get_node("EnemyDisplay/" + enemyName)

func battleStarted(id): # void
	$BattleIntro.play()
	
	await get_tree().create_timer(6).timeout
	
	for child in get_children():
		if child is Panel and child.name != "TextBoxPanel":
			child.visible = true
			
			
	await setUpBattle(id)
	
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
			print("anything?")
		await textbox_continued
	
		$Select.play()
	$TextBoxPanel.hide()
	emit_signal("textbox_ended")
	
func _process(delta): # void 
	
	# misc keys
	
	# CONFIRM
	if Input.is_action_just_pressed("Confirm"):
		if PartyStats.inBattle == false and PartyStats.debug == true:
			PartyStats.battleStart.emit(1)
			$Select.play()
		elif $TextBoxPanel.visible == true:
			emit_signal("textbox_continued")
			
	
	# Input handling. 
	match battlePhase:
		battlePhases.Starting:
			pass
	
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
				
				
				
				
