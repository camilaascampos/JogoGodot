extends RefCounted
class_name JRPGCharInstance

var species: JRPGSpecies

var level := 1
var ExPoints := 0

var max_hp: int
var max_magi: int
var current_hp: int
var current_magi: int

## Carga da ultimate (0 a ultimate_max). A HUD só lê; quem enche é a sua mecânica de dano.
var ultimate_charge := 0.0
var ultimate_max := 100.0

## Recargas: { JRPGBaseSkill: turnos restantes }
var cooldowns: Dictionary = {}

var unlocked_skills : Array[JRPGBaseSkill]
var equipped_skills : Array[JRPGBaseSkill]

func _init(_species: JRPGSpecies, _level := 1):
	species = _species
	level = _level
	recalc_stats()
	ultimate_max = float(species.UltimateMax)
	current_hp = max_hp
	current_magi = max_magi
	unlocked_skills = species.Base_Skills.duplicate()
	equipped_skills = species.Base_Skills.duplicate()

func recalc_stats():
	max_hp = species.Max_Base_HP + species.HP_Growth * (level - 1)
	max_magi = species.Max_Base_Magi + species.Magi_Growth * (level - 1)

func IsAlive()-> bool:
	return current_hp > 0


func cooldown_left(skill: JRPGBaseSkill) -> int:
	return int(cooldowns.get(skill, 0))

## +1 porque o fim do turno em que a skill foi usada já desconta 1.
func start_cooldown(skill: JRPGBaseSkill) -> void:
	cooldowns[skill] = skill.Cooldown + 1

func tick_cooldowns() -> void:
	for skill in cooldowns.keys():
		cooldowns[skill] = maxi(int(cooldowns[skill]) - 1, 0)

func add_ultimate(amount: float) -> void:
	ultimate_charge = clampf(ultimate_charge + amount, 0.0, ultimate_max)
