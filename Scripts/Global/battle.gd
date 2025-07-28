extends Control

# textbox
signal textbox_continued
signal textbox_ended

# selections
signal optionSelected
signal participatorSelected

# battle
signal attackedEnded

#built-in
signal physics

enum battlePhases {
	Starting,
	SelectingBasics,
	SelectingSkills,
	SelectingItems,
	SelectingPartyParticipator,
	SelectingEnemyParticipator,
	ExecutingSelection,
}

var battlePhase = battlePhases.Starting

func _ready():
	PartyStats.battleStart.connect(battleStarted)

func battleStarted(id):
	pass
