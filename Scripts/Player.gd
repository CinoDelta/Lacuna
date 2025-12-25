extends CharacterBody2D

@onready var MAX_SPEED = 250
@onready var MAX_RUNSPEED = 500
@onready var ACCELERATION = 1000000000
@onready var FRICTION = 1000000
@onready var movementAxis = Vector2.ZERO
@onready var animation_tree = $AnimationTree
@onready var storedMovementAxis = Vector2.ZERO
@onready var interactArea = $InteractArea

var directionFacing = "Left"
var bufferInteract = 3

var interactShapePositions = {
	"Right" = Vector2(69, 0),
	"Left" = Vector2(-69, 0),
	"Down" = Vector2(0, 69),
	"Up" = Vector2(0, -40)
}

func _process(delta):
	print(interactArea.get_overlapping_areas())
	if interactArea.get_overlapping_areas() != []:
		print("We have interacted with something")
		var interactionArea = interactArea.get_overlapping_areas()[0]
		var interactionId = interactionArea.get_meta("INTERACTION_ID")
		PartyStats.interaction.emit(interactionId)
	bufferInteract -= 1
	interactArea.get_child(0).disabled = true if bufferInteract <= 0 else false
	
	
	if abs(storedMovementAxis.x) >= abs(storedMovementAxis.y):
		if storedMovementAxis.x < 0:
			directionFacing = "Left"
		else:
			directionFacing = "Right"
	elif abs(storedMovementAxis.y) >= abs(storedMovementAxis.x):
		if storedMovementAxis.y < 0:
			directionFacing = "Up"
		else:
			directionFacing = "Down"
			
	# print("I'm facing.. " + str(directionFacing)) debug
	
	interactArea.get_child(0).position = interactShapePositions[directionFacing]
	
	update_blend_position()
#	$Player/CollisionShapeDetector.disabled = get_meta("Cutscene")
	if get_meta("Cutscene") == false:
		move(delta)
		if Input.is_action_just_pressed("Confirm"):
			interactArea.get_child(0).disabled = false # lasts for exactly one frame lol
			bufferInteract = 3
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
		#PartyStats.playerPositionPacket.emit(global_position, $AnimatedSprite2D.animation)
	
	movementAxis = get_input_axis()
	
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
	animation_tree["parameters/conditions/is_walking"] = bol
	animation_tree["parameters/conditions/idle"] = not bol
	
func update_blend_position():
	animation_tree["parameters/Idle/blend_position"] = storedMovementAxis
	animation_tree["parameters/Walk/blend_position"] = movementAxis
	


		
		
