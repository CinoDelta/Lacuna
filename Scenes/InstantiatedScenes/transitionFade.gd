extends ColorRect

func _ready():
	roomManager.room_load_started.connect(fadeIn)
	
func setTransparency(num : int):
	color = Color(0, 0, 0, num)
	
func fadeIn(seconds : int):
	get_tree().create_tween().tween_property(self, "color", Color(0, 0, 0, 1), seconds)
	
func fadeOut(seconds : int):
	get_tree().create_tween().tween_property(self, "color", Color(0, 0, 0, 0), seconds)
