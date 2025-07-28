extends CharacterBody2D

@export var MAX_SPEED = 250
@export var MAX_RUNSPEED = 500
@export var ACCELERATION = 1000000000
@export var FRICTION = 1000000

@onready var movementAxis = Vector2.ZERO
@onready var animation_tree = $AnimationTree
@onready var storedMovementAxis = Vector2.ZERO
var x = 0
#var SS_Sprites = [
#	"res://Assets/Sprites/PlayerSprites/P_JumpIntobattleR"
#]

func _process(delta):
	update_blend_position()
#	$Player/CollisionShapeDetector.disabled = get_meta("Cutscene")
	if get_meta("Cutscene") == false:
		move(delta)
	$AnimatedSprite2D.visible = not get_meta("SecondSprite")
#	$SecondSprite.visible = get_meta("SecondSprite")
#	$SecondSprite.play("Pinball")
func get_input_axis():
	
	if int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")) == 0 and int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up")) == 0:
		movementAxis = Vector2.ZERO
	else:
		movementAxis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
		movementAxis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		
		storedMovementAxis = movementAxis
		
	return movementAxis.normalized()
	
var lastAnimation = StringName("");
var lastPosition = Vector2.ZERO;
 
func move(delta):
	
	if global_position != lastPosition:
		if $AnimatedSprite2D.animation != lastAnimation:
			lastAnimation = $AnimatedSprite2D.animation
		lastPosition = global_position
		PartyStats.playerPositionPacket.emit(global_position, $AnimatedSprite2D.animation)
	
	movementAxis = get_input_axis()
	
	x += 1
	if movementAxis == Vector2.ZERO:
		set_walking(false)
		apply_friction(FRICTION * delta)
	else:
		set_walking(true)
		var deltAccel = ACCELERATION * delta
		
		apply_movement(movementAxis * deltAccel)
	
	move_and_slide()
	
func apply_friction(amount):
	if velocity.length() > amount:
		velocity -= velocity.normalized() * amount
	else:
		velocity = Vector2.ZERO
	
func apply_movement(accel):
	velocity += accel
	
	if Input.is_action_pressed("Run"):
		velocity = velocity.limit_length(MAX_RUNSPEED)
	else:
		velocity = velocity.limit_length(MAX_SPEED)
	
	
func set_walking(bol):
	#animation_tree.set("parameters/conditions/idle", not bol)
	#animation_tree.set("parameters/conditions/is_walking",  bol)
	animation_tree["parameters/conditions/is_walking"] = bol
	animation_tree["parameters/conditions/idle"] = not bol
	
	
func update_blend_position():
	animation_tree["parameters/Idle/blend_position"] = storedMovementAxis
	animation_tree["parameters/Walk/blend_position"] = movementAxis
	
	
