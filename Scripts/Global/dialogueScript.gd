extends Panel
# self = DialoguePanel

@onready var rDImage = $RightDialogueImg
@onready var lDImage = $LeftDialogueImg
@onready var dText = $DialougeText
@onready var pOneLabel = $PersonOne
@onready var pTwoLabel = $PersonTwo
@onready var choiceCont = $ChoiceContainer
@export var DIALOUGE_FRAME_DURATION = 10

signal dialougeCont
var skipDialogue = false
var skipBuffer = 1
var inDialogue = false
var inChoiceSelection = false
var currentChoice = 0
var choiceNum = 10
var cTexts = []

# Dialogue packet:
# "Left Speaker, Right Speaker, Speech, Current Speaker, ext data (collecting items, sound effects, etc)
var dialogueData = {
	"1" = {
		"1" = { # the first one sets it up. 
			"LeftSpeaker" = "Placeholder",
			"LSExpression" = "Sad",
			"RightSpeaker" = "Placeholder2",
			"RSExpression" = "Neutral",
			"CurrentSpeaker" = "Placeholder",
			"Speech" = [
				"Hey whats up, this is blah blah blah.", 
				"Hope you have a fun time you know. Reading this dialogue.",
				"I know I sure as hell aint...",
				"Wait. Do you like flowkenuinely or kirkenuinely more?"
				] # array of progressible speeches. when its over, we go to the next dict.
			, 
			"Choice" = true,
			"Continuation" = false,
			"ChoiceDictionary" = {
				"kirkenuinely" = 2,
				"flowkenuinely" = 3,
				"flowkirkenuinely" = 4
			},
			"ChangeExpressions" = {},
			"Sounds" = {}
		},
	},
	"2" = {
		"1" = {  
			"LeftSpeaker" = "Placeholder",
			"LSExpression" = "Neutral",
			"RightSpeaker" = "Placeholder2",
			"RSExpression" = "Neutral",
			"CurrentSpeaker" = "Placeholder",
			"Speech" = [
				"Ew...",
				"You're disgusting. Get the hell away from me."
				] 
			, 
			"Choice" = false,
			"Continuation" = true,
			"ChoiceDictionary" = {},
			"ChangeExpressions" = {},
			"Sounds" = {}
		},
	},
	"3" = {
		"1" = {  
			"LeftSpeaker" = "Placeholder",
			"LSExpression" = "Neutral",
			"RightSpeaker" = "Placeholder2",
			"RSExpression" = "Neutral",
			"CurrentSpeaker" = "Placeholder",
			"Speech" = [
				"May the gloving gods bless you."
				] 
			, 
			"Choice" = false,
			"Continuation" = true,
			"ChoiceDictionary" = {},
			"ChangeExpressions" = {},
			"Sounds" = {}
		},
	},
	"4" = {
		"1" = {  
			"LeftSpeaker" = "Placeholder",
			"LSExpression" = "Sad",
			"RightSpeaker" = "Placeholder2",
			"RSExpression" = "Neutral",
			"CurrentSpeaker" = "Placeholder",
			"Speech" = [
				"... BROOOOOOOOOOO...",
				"YOU ARE THE SMARTEST PERSON EVER!!!"
				] 
			, 
			"Choice" = false,
			"Continuation" = true,
			"ChoiceDictionary" = {},
			"ChangeExpressions" = {
				"1" = {
					"Speaker" = "LeftSpeaker",
					"Expression" = "Neutral"
				}
			},
			"Sounds" = {}
		},
	}
}

func loadSpeaker(speaker, expression):
	return load("res://Assets/Sprites/TalkSprites/" + speaker + "/" + expression + ".png")

func loadDialogue(dData, tween = true):	
	rDImage.texture = loadSpeaker(dData["RightSpeaker"], dData["RSExpression"])
	lDImage.texture = loadSpeaker(dData["LeftSpeaker"], dData["LSExpression"])
	self.visible = true
	dText.visible = true
	choiceCont.visible = false
	
	if tween:
		lDImage.flip_h = true
		
		rDImage.modulate = Color.from_hsv(0, 0, 1.0, 0.0)
		lDImage.modulate = Color.from_hsv(0, 0, 1.0, 0.0)

		rDImage.visible = true
		lDImage.visible = true
		
		get_tree().create_tween().tween_property(rDImage, "modulate", Color.from_hsv(0, 0, 1.0, 1.0), .4)
		get_tree().create_tween().tween_property(lDImage, "modulate", Color.from_hsv(0, 0, 1.0, 1.0), .4)
	
	pOneLabel.text = dData["LeftSpeaker"]
	pTwoLabel.text = dData["RightSpeaker"]

func changeExpression(speaker, speakerName, expression):
	if speaker == "LeftSpeaker":
		lDImage.texture = loadSpeaker(speakerName, expression)
	else:
		rDImage.texture = loadSpeaker(speakerName, expression)

func unloadDialogue():
	get_tree().create_tween().tween_property(rDImage, "modulate", Color.from_hsv(0, 0, 1.0, 0.0), .4)
	get_tree().create_tween().tween_property(lDImage, "modulate", Color.from_hsv(0, 0, 1.0, 0.0), .4)
	await get_tree().create_timer(.4).timeout
	self.visible = false

func _ready():
	self.visible = false
	PartyStats.interaction.connect(processInteraction)

func updateLabels():
	for label in choiceCont.get_children():
		if label.name != "SampleChoice":
			print("Index: ")
			print(cTexts.find(label.text)) 
			print("current choice:")
			print(currentChoice)
			if cTexts.find(label.text) == currentChoice:
				label.text = "[color=yellow]" + label.name + "[/color]"
			else:
				label.text = label.name

func _process(_delta):
	skipBuffer -= 1 if skipBuffer > 0 else 0
	if Input.is_action_just_pressed("Confirm") and inDialogue:
		if skipBuffer == 0:
			skipDialogue = true
			skipBuffer = 20
		dialougeCont.emit()
	if inChoiceSelection:

		if Input.is_action_just_pressed("ui_down"):
			print("yes?")
			currentChoice += 1
			if currentChoice == choiceNum:
				currentChoice = 0
			updateLabels()
		elif Input.is_action_just_pressed("ui_up"):
			currentChoice -= 1
			if currentChoice < 0:
				currentChoice = (choiceNum - 1)
			updateLabels()
		
func processInteraction(id):
	var currentDSection = 0
	var dData = dialogueData[str(id)]
	inDialogue = true
	PartyStats.setCutscene.emit(true)
	
	for i in dData.keys():
		currentDSection += 1
		var currentSect = dData[str(currentDSection)]
		var tween = (currentDSection == 1) # first measure
		tween = not currentSect["Continuation"] # second measure
		loadDialogue(currentSect, tween)
		for j in range(currentSect["Speech"].size()):
			
			for possibleChange in currentSect["ChangeExpressions"]:
				if possibleChange == str(j):
					var exData = currentSect["ChangeExpressions"][str(j)]
					changeExpression(exData["Speaker"], currentSect[exData["Speaker"]], exData["Expression"])
			
			var currentText = currentSect["Speech"][j]
			dText.text = currentText
			dText.visible_characters = 0
			skipDialogue = false
			for k in range(currentText.length()):
				if not skipDialogue:
					dText.visible_characters = k + 1
					var extWaitTime = 1
					match dText.text[dText.visible_characters - 1]:
						".":
							extWaitTime = 4
						"?":
							extWaitTime = 4
						"!":
							extWaitTime = 4
						",":
							extWaitTime = 2
						":":
							extWaitTime = 2
					await get_tree().create_timer(0.01 * DIALOUGE_FRAME_DURATION * extWaitTime).timeout
				else:
					# set to false afterwards
					dText.visible_characters = currentText.length()
					break
					
			await dialougeCont
			
			#$AudioStreamPlayer.stream = load("res://Assets/Sounds/Sfx/EnemyAttacks.ogg")
			#$AudioStreamPlayer.play()
		
	var finalSectionData = dData[str(currentDSection)]
	if finalSectionData["Choice"]:
		inChoiceSelection = true
		dText.visible = false
		choiceCont.visible = true
		cTexts = []
		choiceNum = finalSectionData["ChoiceDictionary"].keys().size()
		currentChoice = 0
		for possibleChoice in finalSectionData["ChoiceDictionary"]:
			var newCText = choiceCont.get_child(0).duplicate()
			newCText.text = possibleChoice
			choiceCont.add_child(newCText)
			newCText.visible = true
			newCText.name = possibleChoice
			cTexts.insert(cTexts.size(), newCText.text)
		print("CText")
		print(cTexts)
		await dialougeCont
		
		for label in choiceCont.get_children():
			if label.name != "SampleChoice":
				choiceCont.remove_child(label)
		processInteraction(finalSectionData["ChoiceDictionary"][cTexts[currentChoice]]) # Recursive function!! :O
	else:
		inDialogue = false
		unloadDialogue()
		PartyStats.setCutscene.emit(false)
	
	
