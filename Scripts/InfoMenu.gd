extends Panel

var panelMode = 0 # [0, 3]
var currentPanelCharacter = 0 # If index out of bounds, default to 0
var currentSelection = "MEMBERS" # Top: MODES, Bottom: MEMBERS
# 0 stats
# 1 skills
# 2 equip
# 3 items
# Enabled if the panel is visible
@onready var modeNodes = [$Stats, $Skills, $Equipment, $Items]


func _process(delta: float) -> void:
	if !visible: return
	var currentPartyMembers = PartyStats.currentPartyMembers
	if currentPanelCharacter + 1 > currentPartyMembers.size():
		currentPanelCharacter = 0
	
	# Handle inputs 
	
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		if currentSelection == "MODES":
			currentSelection = "MEMBERS"
		else:
			currentSelection = "MODES"
	elif currentSelection == "MODES":
		if Input.is_action_just_pressed("ui_left"):
			panelMode = 3 if panelMode == 0 else panelMode - 1
		elif Input.is_action_just_pressed("ui_right"):
			panelMode = 0 if panelMode == 3 else panelMode + 1
	elif currentSelection == "MEMBERS": # no else for readability
		if Input.is_action_just_pressed("ui_left"):
			currentPanelCharacter = currentPartyMembers.size() - 1 if currentPanelCharacter == 0 else currentPanelCharacter - 1
		elif Input.is_action_just_pressed("ui_right"):
			currentPanelCharacter = 0 if currentPanelCharacter == currentPartyMembers.size() - 1 else currentPanelCharacter + 1
			
	# undo and set, highlights
	for node in modeNodes:
		var setText = ""
		if node.name != "Equipment":
			setText = node.name
		else:
			setText = "Equip"
		node.get_child(0).text = "[color=yellow]" + setText if modeNodes[panelMode] == node else setText
	
