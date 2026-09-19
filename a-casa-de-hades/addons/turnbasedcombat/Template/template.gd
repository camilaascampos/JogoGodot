extends Node2D

@export var Annabeth: JRPGSpecies
@export var Percy: JRPGSpecies

@export var Arai_Any: JRPGSpecies
@export var Arai_Kelli: JRPGSpecies
@export var Arai_Seraphone: JRPGSpecies

func _ready() -> void:
	$Combat.PlayerTeam = [
		JRPGCharInstance.new(Annabeth),
		JRPGCharInstance.new(Percy)
	] as Array[JRPGCharInstance]

	$Combat.EnemyTeam = [
		JRPGCharInstance.new(Arai_Any),
		JRPGCharInstance.new(Arai_Kelli),
		JRPGCharInstance.new(Arai_Seraphone)
	] as Array[JRPGCharInstance]

	$Combat.start()
