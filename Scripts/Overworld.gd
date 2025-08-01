extends Node2D

@onready var player = $Player
@onready var camera = $OverworldCamera
@onready var transitionCover = $TransitionBlack
@onready var greenTransitionCover = $TransitionGreen

# Called when the node enters the scene tree for the first time.
func _ready():
	PartyStats.battleStart.connect(battleTransition)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func battleTransition():
	
	var transitionTween = get_tree().create_tween().tween_property(greenTransitionCover, "color", Color(0, 0.78, 0, 0.5), 1).set_trans(Tween.TRANS_QUAD)
	await transitionTween.finished
	await get_tree().create_timer(4.0).timeout
	var coverTransitionTween = get_tree().create_tween().tween_property(transitionCover, "color", Color(1, 1, 1, 1), .25).set_trans(Tween.TRANS_QUAD)
	player.visible = false
	
	await get_tree().create_timer(1.25).timeout
	var coverTransitionOutTween = get_tree().create_tween().tween_property(transitionCover, "color", Color(1, 1, 1, 0), .25).set_trans(Tween.TRANS_QUAD)
	
