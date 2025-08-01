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

func battleTransition(id):
	
	var transitionTween = get_tree().create_tween().tween_property(greenTransitionCover, "color", Color(0.09, 0.67, 0.3, 0.5), 1).set_trans(Tween.TRANS_QUAD)
	await transitionTween.finished
	await get_tree().create_timer(2.0).timeout
	var coverTransitionTween = get_tree().create_tween().tween_property(transitionCover, "color", Color(1, 1, 1, 1), 1).set_trans(Tween.TRANS_QUAD)
	await coverTransitionTween.finished
	player.visible = false
	greenTransitionCover.color = Color(0.09, 0.67, 0.3, 0)
	await get_tree().create_timer(2).timeout
	var coverTransitionOutTween = get_tree().create_tween().tween_property(transitionCover, "color", Color(1, 1, 1, 0), .25).set_trans(Tween.TRANS_QUAD)
	
