extends Node2D



@onready var player = $Player
@onready var camera = $OverworldCamera
@onready var transitionCover = $TransitionBlack
@onready var greenTransitionCover = $TransitionGreen
@onready var infoMenu = $StatMenu

var currentRoom
var nextRoom
var menuOpen = false
var menuTransitioning = false

# Called when the node enters the scene tree for the first time.
func _ready():
	PartyStats.battleStart.connect(battleTransition)
	PartyStats.battleOver.connect(transitionOut)
	roomManager.room_load_started.connect(freeRoom)
	PartyStats.interaction.connect(processInteraction)
	infoMenu.position = Vector2(70, -500) # starting position


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("Menu") and !menuTransitioning:
		menuTransitioning = true
		player.set_meta("Cutscene", !menuOpen)
		if menuOpen: # Already open.
			var transitionTween = get_tree().create_tween().tween_property(infoMenu, "position", Vector2(70, -500), .4).set_trans(Tween.TRANS_QUAD)
			await transitionTween.finished
			await get_tree().create_timer(.15).timeout
		else:
			var transitionTween = get_tree().create_tween().tween_property(infoMenu, "position", Vector2(70, 100), .4).set_trans(Tween.TRANS_QUAD)
			await transitionTween.finished
			await get_tree().create_timer(.15).timeout
		
		menuTransitioning = false
		menuOpen = !menuOpen

func battleTransition(_id):
	
	player.set_meta("Cutscene", true)
	
	var transitionTween = get_tree().create_tween().tween_property(greenTransitionCover, "color", Color(0.09, 0.67, 0.3, 0.5), 1).set_trans(Tween.TRANS_QUAD)
	await transitionTween.finished
	await get_tree().create_timer(1.0).timeout
	
	var coverTransitionTween = get_tree().create_tween().tween_property(transitionCover, "color", Color(1, 1, 1, 1), .8).set_trans(Tween.TRANS_QUAD)
	await coverTransitionTween.finished
	player.visible = false
	greenTransitionCover.color = Color(0.09, 0.67, 0.3, 0)
	await get_tree().create_timer(1).timeout
	var _coverTransitionOutTween = get_tree().create_tween().tween_property(transitionCover, "color", Color(1, 1, 1, 0), .2).set_trans(Tween.TRANS_QUAD)

func transitionOut():
	player.set_meta("Cutscene", false)
	
	var coverTransitionTween = get_tree().create_tween().tween_property(transitionCover, "color", Color(0, 0, 0, 1), .8).set_trans(Tween.TRANS_QUAD)
	await coverTransitionTween.finished
	player.visible = true
	
	await get_tree().create_timer(1.3).timeout
	var _coverTransitionOutTween = get_tree().create_tween().tween_property(transitionCover, "color", Color(0,0,0, 0), .2).set_trans(Tween.TRANS_QUAD)


func freeRoom():
	remove_child(player)
	queue_free()
	
func processInteraction(id):
	match id:
		1:
			pass
			#$AudioStreamPlayer.stream = load("res://Assets/Sounds/Sfx/EnemyAttacks.ogg")
			#$AudioStreamPlayer.play()
