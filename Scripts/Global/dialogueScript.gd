extends Panel
# self = DialoguePanel

@onready var rDImage = $RightDialogueImg
@onready var lDImage = $LeftDialogueImg
@onready var dText = $DialougeText
@onready var pOneLabel = $PersonOne
@onready var pTwoLabel = $PersonTwo
@onready var choiceCont = $ChoiceContainer
@export var DIALOUGE_FRAME_DURATION = 10

# Dialogue packet:
# "Left Speaker, Right Speaker, Speech, Current Speaker, ext data (collecting items, sound effects, etc)
var dialogueData = {
	"1" = {
		"1" = { # the first one sets it up. 
			"LeftSpeaker" = "Placeholder",
			"LSExpression" = "Neutral",
			"RightSpeaker" = "Placeholder2",
			"RSExpression" = "Neutral",
			"CurrentSpeaker" = "Placeholder",
			"Speech" = ["Hey whats up this is blah blah blah."] # array of progressible speeches. when its over, we go to the next dict.
			, "ExtraData" = {}
		}
	}
}

func loadSpeaker(speaker, expression):
	return load("res://Assets/Sprites/TalkSprites/" + speaker + "/" + expression + ".png")

func loadDialogue(dData, tween = true):	
	rDImage.texture = loadSpeaker(dData["RightSpeaker"], dData["RSExpression"])
	lDImage.texture = loadSpeaker(dData["LeftSpeaker"], dData["LSExpression"])
	self.visible = true
	
	if tween:
		lDImage.flip_h = true
		
		rDImage.modulate = Color.from_hsv(0, 0, 1.0, 0.0)
		lDImage.modulate = Color.from_hsv(0, 0, 1.0, 0.0)

		rDImage.visible = true
		lDImage.visible = true
		
		get_tree().create_tween().tween_property(rDImage, "modulate", Color.from_hsv(0, 0, 1.0, 1.0), .4)
		get_tree().create_tween().tween_property(lDImage, "modulate", Color.from_hsv(0, 0, 1.0, 1.0), .4)
	
		
func _ready():
	self.visible = false
	PartyStats.interaction.connect(processInteraction)
	

func processInteraction(id):
	var currentDSection = 1
	var dData = dialogueData[str(id)]
	
	match id:
		1:
			# the plan is to have it loop through, repeating through the sections until a choice occurs.
			# this will break the whole loop, and load a new dialogue, but without the tweens.
			for i in dData.keys():
				var currentSect = dData[str(currentDSection)]
				loadDialogue(dData[str(currentDSection)])
				for j in range(currentSect["Speech"].size()):
					var currentText = currentSect["Speech"][j]
					dText.text = currentText
					dText.visible_characters = 0
					for k in range(currentText.length()):
						dText.visible_characters = k + 1
						await get_tree().create_timer(0.01 * DIALOUGE_FRAME_DURATION).timeout
			pass
			#$AudioStreamPlayer.stream = load("res://Assets/Sounds/Sfx/EnemyAttacks.ogg")
			#$AudioStreamPlayer.play()
			
