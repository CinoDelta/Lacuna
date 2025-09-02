extends Node

var SKILL_DATABASE = { 
	"Swordsmanship" = {
		"X-Slash" = {
			"Levels" = false,
			"DisplayName" = "X-Slash",
			"AetherData" = [false, 60],
			"Description" = "Cuts an opposing enemy with devastating force. Scales based on ATTACK. (Attack level 4)",
			"AttackShout" = "%u excecutes an X-Slash!"
		}
	},
	"Spells" = {
		"FocusBlast" = {
			"Levels" = true,
			"I" = {
				"DisplayName" = "Focus Blast I",
				"AetherData" = [true, 14],
				"Description" = "Fire off a concentrated blast of Aether. Has a base damage of 7, and scales based off of MAGIC.",
				"AttackShout" = "%u fires off a focus blast!"
			}
		}
	}
}
