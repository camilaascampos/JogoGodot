extends Node2D
class_name JRPGCombatManager

## Emitido quando a batalha acaba e o jogador confirma a tela de vitória/derrota.
signal battle_finished(player_won: bool)

enum TurnManagerStyle {
	## per turn the player can choose all of the characters to do something once
	PerTeam,
	## per turn the player get to choose the action of one character in the order of [color=green]ally1,ally2,ally3[/color],[color=red]enemy1,enemy2,enemy3[/color]
	OrderTeam,
	## per turn the player get to choose the action of one character in the order of [color=green]ally1[/color],[color=red]enemy1[/color],[color=green]ally2[/color],[color=red]enemy2[/color],[color=green]ally3[/color],[color=red]enemy3[/color]
	OrderAternating,
	## the turn order gets decided by the [color=yellow][b]speed[/b][/color] stat of the character
	OrderStat,
	## the turn order gets decided by the [color=yellow][b]speed[/b][/color] stat of the character and this stat can be affected mid battle
	LooseOrderStat,
}

## choice for which [b]TurnManager[/b] you want to use in combat
@export var turnmanagerstyle: TurnManagerStyle = TurnManagerStyle.OrderStat
@export var PlayerTeamNode: Node2D
@export var EnemyTeamNode: Node2D
## Filepath where all you character for the turn based combat are. they need to be structured like: res://[yourfolders]/[example]Battlechars/[speciesname]/Battle.tscn the structure is important otherwise this won't be able to find the characters. To see an example look at the template scene
@export var CharactersPath: String

## Itens do menu ITEM (ex.: Pote de cura). Só aparecem se o jogador possuir o item (JRPGInventory).
@export var ItemSkills: Array[JRPGBaseSkill]

@export_group("UI")
@export var Background: Texture2D
@export_subgroup("Theme")
@export var EnableCustomTheme: bool
@export var CustomTheme: Theme


## if true adds a little randomization to the choice of attacks the enemies do
static var RandomizeAttacks: bool = false
## if true tries to prevent enemy from spamming a single attack over and over
static var SpamPenalty: bool = false

## array of character for the players team [color=green][b]3 max[/b][/color]
var PlayerTeam: Array[JRPGCharInstance]
## array of character for the enemy team [color=green][b]3 max[/b][/color]
var EnemyTeam: Array[JRPGCharInstance]
var TurnManagerinstance: JRPGTurnManager
var _player_won := false
## Inventário no começo da luta: "tentar novamente" devolve os itens gastos.
var _inventory_snapshot: Dictionary = {}


func start():
	
	match turnmanagerstyle:
		TurnManagerStyle.PerTeam:
			var preinstance = load("res://addons/turnbasedcombat/Scripts/TurnManagers/TurnManagerPerTeam.gd")
			TurnManagerinstance = preinstance.new()
			add_child(TurnManagerinstance)
			SetupPerTeam()
		TurnManagerStyle.OrderTeam:
			push_error("Not implemented yet!")
		TurnManagerStyle.OrderAternating:
			push_error("Not implemented yet!")
		TurnManagerStyle.OrderStat:
			var preinstance = load("res://addons/turnbasedcombat/Scripts/TurnManagers/TurnManagerOrderStat.gd")
			TurnManagerinstance = preinstance.new()
			add_child(TurnManagerinstance)
			SetupPerTeam()
		TurnManagerStyle.LooseOrderStat:
			push_error("Not implemented yet!")
	
	# HUD: precisa dos personagens já criados (LoadChars roda dentro do SetupPerTeam).
	JRPGSignalBus.instance.BattleEnded.connect(func(won: bool): _player_won = won)
	_inventory_snapshot = JRPGInventory.items.duplicate()
	JRPGSignalBus.instance.RetryBattle.connect(func():
		JRPGInventory.items = _inventory_snapshot.duplicate()
		get_tree().reload_current_scene())
	JRPGSignalBus.instance.EndBattle.connect(func(): battle_finished.emit(_player_won))

	if TurnManagerinstance != null:
		$UI.item_skills = ItemSkills
		$UI.setup_hud(TurnManagerinstance.PlayerTeam, TurnManagerinstance.EnemyTeam)

	if EnableCustomTheme:
		var controlnodes = find_children("*", "Control")
		
		for controlnode: Control in controlnodes:
			controlnode.theme = CustomTheme
		
	if Background != null:
		$Background/TextureRect.theme = null
		$Background/TextureRect.texture = Background;
		$Background/TextureRect.position.x = (1152 - Background.get_size().x) / 2
		$Background/TextureRect.position.y = (648 - Background.get_size().y) / 2

func LoadChars() -> Array[JRPGBaseBattleChar]: 
	var characters: Array[JRPGBaseBattleChar] 
	
	for i:int in PlayerTeam.size():
		var instance : JRPGBaseBattleChar = load(CharactersPath + PlayerTeam[i].species.Name + "/Battle.tscn").instantiate()
		instance.add_to_group("BattleChar")
		instance.Team = JRPGEnums.Team.Player
		characters.push_back(instance)
		PlayerTeamNode.add_child(instance)
		instance.global_position = PlayerTeamNode.get_child(i).global_position - Vector2(450,0)
		instance.Char = PlayerTeam[i]
		
		TurnManagerinstance.PlayerTeam.append(instance)
	
	for i:int in EnemyTeam.size():
		var instance : JRPGBaseBattleChar = load(CharactersPath + EnemyTeam[i].species.Name + "/Battle.tscn").instantiate()
		instance.add_to_group("BattleChar")
		instance.Team = JRPGEnums.Team.Enemy
		characters.push_back(instance)
		EnemyTeamNode.add_child(instance)
		instance.global_position = EnemyTeamNode.get_child(i).global_position + Vector2(450,0)
		instance.Char = EnemyTeam[i]
		
		TurnManagerinstance.EnemyTeam.append(instance)
	
	return characters

func SetupPerTeam():
	var Characters: Array[JRPGBaseBattleChar] = LoadChars()
	
	var i := 0
	var j := 0
	
	for char:JRPGBaseBattleChar in Characters:
		if char.Team == JRPGEnums.Team.Player:
			char.playstart(PlayerTeamNode.get_child(i).global_position)
			i += 1
		elif char.Team == JRPGEnums.Team.Enemy:
			char.playstart(EnemyTeamNode.get_child(j).global_position)
			j += 1
