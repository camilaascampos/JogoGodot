extends Node

var MaxHP: float
var CurrrentHP: float
var Str: int = 30
var Dex: int = 4 
var Int: int = 3
var Mana: float

var Skills:Array[Resource]

func _ready():
	for skill in []:
		var CurrentSkill = load(skill)
		Skills.append(CurrentSkill)
