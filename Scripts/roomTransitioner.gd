extends Area2D

enum SIDES {
	LEFT,
	RIGHT,
	TOP,
	BOTTOM
} # For special sides we can jsut add them in

@export_category("Collision Area Settings")
@export_range(1, 12, 1, "or_greater") var boxSize : int = 2 :
	set( _v ):
		boxSize = _v
		_update_area()
@export_file("*.tscn") var room
@export var targetTransitionArea : String = "RoomTransition"

@onready var collision: CollisionShape2D = $CollisionShape2D
@export var positionOffset = Vector2.ZERO
@export var boxSide : SIDES = SIDES.LEFT:
	set( _v ):
		boxSide = _v
		_update_area()

func _ready() -> void:
	if $CollisionShape2D != null:
		_update_area()
	
func _update_area() :
	#var newRect = Vector2(32, 32)
	#
	#if boxSide == SIDES.LEFT or boxSide == SIDES.RIGHT:
		#newRect.x *= boxSize
	#else:
		#newRect.y *= boxSize 
	#
	#if collision == null:
		#collision = get_child(0)
	#else:
		#$CollisionShape2D.shape.size = newRect
		#
	pass

func _on_body_entered(body: Node2D) -> void:
	if PartyStats.canTransition == true and body.name == "Player":
		roomManager.loadNewRoom(room, targetTransitionArea, positionOffset)
		print(body.name)
