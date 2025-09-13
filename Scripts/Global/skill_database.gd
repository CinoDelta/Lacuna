extends Node

#TargetTypes = "Player" "Enemy" "AllPlayer" "AllEnemy" "Field"
var SKILL_DATABASE = { 
	"Swordsmanship" = {
		"Icon" = preload("res://Assets/Sprites/Battle/DisplaySprites/Selections/SkillTypeGraphics/Swordsmanship.png"),
		"X-Slash" = {
			"Levels" = false,
			"DisplayName" = "X-Slash",
			"AetherData" = [false, 20],
			"Description" = "Cuts an opposing enemy with devastating force. Scales based on ATTACK. (Attack level 4)",
			"AttackShout" = "%u excecutes an X-Slash!",
			"TargetType" = "Enemy"
		},
		"Pierce the Veil" = {
			"Levels" = false,
			"DisplayName" = "Pierce the Veil",
			"AetherData" = [false, 10],
			"Description" = "Repeatedly cuts an enemies weak spots, ignoring defense boosts. Basic attack, but reduces defense by one stage.",
			"AttackShout" = "%u cuts the veil!",
			"TargetType" = "Enemy"
		},
		"Disarm" = {
			"Levels" = false,
			"DisplayName" = "Disarm",
			"AetherData" = [false, 25],
			"Description" = "Hits vital spots for attacking, lowering enemy attack by one stage.",
			"AttackShout" = "%u disarms %t!",
			"TargetType" = "Enemy"
		},
		"Flash Advance" = {
			"Levels" = false,
			"DisplayName" = "Flash Advance",
			"AetherData" = [false, 55],
			"Description" = "Moves at blinding speeds, catching an enemy off gaurd. Increases speed by one and always critical hits.",
			"AttackShout" = "%u splits the wind!",
			"TargetType" = "Enemy"
		},
		"Sweeping Cut" = {
			"Levels" = false,
			"DisplayName" = "Sweeping Cut",
			"AetherData" = [false, 45],
			"Description" = "Movement at blinding speeds. Increases speed by one and always critical hits.",
			"AttackShout" = "%u sweeps the field!",
			"TargetType" = "AllEnemy"
		},
	},
	"Spells" = {
		"Icon" = preload("res://Assets/Sprites/Battle/DisplaySprites/Selections/SkillTypeGraphics/Spells.png"),
		"FocusBlast" = {
			"Levels" = true,
			"I" = {
				"DisplayName" = "Focus Blast I",
				"AetherData" = [true, 14],
				"Description" = "Fire off a concentrated blast of Aether. Has a base damage of 7-10, and scales based off of MAGIC.",
				"AttackShout" = "%u fires off a focus blast!",
				"TargetType" = "Enemy"
			}
		}
	}
}
