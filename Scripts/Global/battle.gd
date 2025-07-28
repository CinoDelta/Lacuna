extends Node

# textbox
signal textbox_continued
signal textbox_ended

# selections
signal optionSelected
signal participatorSelected

# battle
signal battleStart
signal attackedEnded

#built-in
signal physics

enum battlePhases {
	SelectingBasics,
	SelectingSkills,
	SelectingItems,
	SelectingPartyParticipator,
	SelectingEnemyParticipator,
	ExecutingSelection,
}
