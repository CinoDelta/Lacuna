extends Node

signal room_load_started
signal room_loaded

signal tilemap_bounds_changed(bounds : Array[Vector2])

var current_tilemap_bounds: Array [Vector2]
var target_transition: String
var position_offset: Vector2

func change_tilemap_bounds(bounds : Array [Vector2]):
	current_tilemap_bounds = bounds
	tilemap_bounds_changed.emit(bounds)
	
func loadNewRoom(
	roomPath : String,
	targetTransition : String,
	positionOffset : Vector2
) -> void:
	
	get_tree().paused = true 
	target_transition = targetTransition
	position_offset = positionOffset
	
	await get_tree().process_frame # Room Transition Effect
	
	room_load_started.emit()
	
	await get_tree().process_frame
	
	get_tree().change_scene_to_file(roomPath)
	
	await get_tree().process_frame # Room Transition Effect
	
	get_tree().paused = false
	
	await get_tree().process_frame
	
	room_loaded.emit()
	
	pass
