extends Node2D

@export var Annabeth: JRPGSpecies
@export var Percy: JRPGSpecies

@export var Arai_Any: JRPGSpecies
@export var Arai_Kelli: JRPGSpecies
@export var Arai_Seraphone: JRPGSpecies

@export_group("Inventário de teste")
## Liga só para testar esta cena sozinha. Na história real, desligue e preencha o
## JRPGInventory antes de abrir a luta (ver JRPGInventory.gd).
@export var UseTestInventory: bool = true
@export var TestYankeesCap: bool = true
@export var TestAthenaBlessings: int = 2
@export var TestHealingPots: int = 3

func _ready() -> void:
	if UseTestInventory and not JRPGInventory.managed_by_story:
		JRPGInventory.clear()
		if TestYankeesCap:
			JRPGInventory.give(JRPGInventory.YANKEES_CAP)
		JRPGInventory.give(JRPGInventory.ATHENA_BLESSING, TestAthenaBlessings)
		JRPGInventory.give(JRPGInventory.HEALING_POT, TestHealingPots)

		# Vitória: vai para a cena definida pela história; sem ela, reinicia (teste).
	$Combat.battle_finished.connect(func(_won: bool):
		if JRPGInventory.after_victory_scene != "":
			get_tree().change_scene_to_file(JRPGInventory.after_victory_scene)
		else:
			get_tree().reload_current_scene())

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
