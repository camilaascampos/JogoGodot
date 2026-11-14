extends JRPGTurnManager

var turn := 0;

var TargetAlly: bool
var TargetEnemy: bool
var SelectedSkill: JRPGBaseSkill
var busy := false

func _ready() -> void:
	JRPGSignalBus.instance.PlayerTurn.connect(CheckPlayerTurn)
	JRPGSignalBus.instance.EnemyTurn.connect(CallEnemies)
	JRPGSignalBus.instance.EndTurn.connect(func(char,team): Turn())
	JRPGSignalBus.instance.Clicked.connect(SelectTarget)
	JRPGSignalBus.instance.SelectedSkill.connect(PrepareSkillTargeting)
	JRPGSignalBus.instance.CancelCommand.connect(CancelCommand)
	JRPGSignalBus.instance.DefendChosen.connect(OnDefend)
	
	await JRPGSignalBus.instance.StartDone
	Turn()

func Turn():
	if turn == 0:
		turn = 1
		
		for i:int in PlayerTeam.size():
			var hero := PlayerTeam[i]
			hero.AvailableAction = hero.Char.IsAlive() and not hero.IsActionBlocked()
			if hero.Char.IsAlive() and hero.IsActionBlocked():
				JRPGSignalBus.instance.ResultToUI.emit(hero.Char.species.get_display_name() + " is stunned and loses the turn")
		
		JRPGSignalBus.instance.PlayerTurn.emit()
		JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.SELECTABLE_PLAYER)
		JRPGSignalBus.instance.ResultToUI.emit("Player turn")
		JRPGSignalBus.instance.StartTurn.emit(null, JRPGEnums.Team.Player)
	else:
		turn = 0
		JRPGSignalBus.instance.EnemyTurn.emit()
		JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.NONE)
		JRPGSignalBus.instance.ResultToUI.emit("Enemy turn")
		JRPGSignalBus.instance.StartTurn.emit(null, JRPGEnums.Team.Enemy)

func CheckPlayerTurn():
	var playerturn := true
	
	for i:int in PlayerTeam.size():
		var character: JRPGBaseBattleChar = PlayerTeam[i]
		if character.Char.IsAlive() && character.AvailableAction:
			playerturn = false;
			break;
	
	if playerturn:
		JRPGSignalBus.instance.EndTurn.emit(null, JRPGEnums.Team.Player)

func SelectTarget(MouseTarget: JRPGBaseBattleChar):
	if turn != 1 || MouseTarget == null:
		return;
	
	print("selected char: " + MouseTarget.to_string())
	
	if (TargetAlly && MouseTarget.Team == JRPGEnums.Team.Player) || (TargetEnemy && MouseTarget.Team == JRPGEnums.Team.Enemy):
		TargetAlly = false
		TargetEnemy = false
		SelectedCharacter.AvailableAction = false;
		busy = true
		await SelectedSkill.Activate(SelectedCharacter, [MouseTarget])
		busy = false
		JRPGSignalBus.instance.SelectedChar.emit(null)
		JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.SELECTABLE_PLAYER)
		SelectedCharacter = null
		CheckPlayerTurn()
	elif MouseTarget.Team == JRPGEnums.Team.Player && !busy && !TargetAlly && !TargetEnemy && MouseTarget.AvailableAction:
		SelectedCharacter = MouseTarget
		JRPGSignalBus.instance.SelectedChar.emit(MouseTarget)

func PrepareSkillTargeting(Skill: JRPGBaseSkill):
	if Skill == null:
		return
	print("selected skill: " + Skill.Name)
	SelectedSkill = Skill
	match SelectedSkill.Target:
		JRPGEnums.Target.All_Enemies:
			var enemies: Array[JRPGBaseBattleChar]
			for node:JRPGBaseBattleChar in get_tree().get_nodes_in_group("BattleChar"):
				if node.Team == JRPGEnums.Team.Enemy:
					enemies.append(node)
			_activate_instant(enemies)
			
		JRPGEnums.Target.Enemy:
			JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.TARGET_ENEMY)
			TargetEnemy = true;
			
		JRPGEnums.Target.All_Allies:
			var allies: Array[JRPGBaseBattleChar]
			for node:JRPGBaseBattleChar in get_tree().get_nodes_in_group("BattleChar"):
				if node.Team == JRPGEnums.Team.Player:
					allies.append(node)
			_activate_instant(allies)
			
		JRPGEnums.Target.Ally:
			JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.TARGET_ALLY)
			TargetAlly = true;
			
		JRPGEnums.Target.Self:
			var self_target: Array[JRPGBaseBattleChar] = [SelectedCharacter]
			_activate_instant(self_target)
			
		_:
			JRPGSignalBus.instance.SelectedChar.emit(null)
			JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.NONE)
			push_error("Unhandled target: %s" % SelectedSkill.Target)

func _activate_instant(targets: Array[JRPGBaseBattleChar]):
	var caster := SelectedCharacter
	caster.AvailableAction = false
	busy = true
	await SelectedSkill.Activate(caster, targets)
	busy = false
	JRPGSignalBus.instance.SelectedChar.emit(null)
	JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.SELECTABLE_PLAYER)
	SelectedCharacter = null
	CheckPlayerTurn()

## VOLTAR no menu: cancela a escolha de alvo ou, se não há skill pendente, desfaz a seleção do herói.
func CancelCommand():
	if turn != 1 || busy || SelectedCharacter == null:
		return
	if TargetAlly || TargetEnemy:
		TargetAlly = false
		TargetEnemy = false
		SelectedSkill = null
		JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.SELECTABLE_PLAYER)
	else:
		SelectedCharacter = null
		JRPGSignalBus.instance.SelectedChar.emit(null)

## DEFENDER: por enquanto só consome a ação do herói. TODO: aplicar sua redução de dano aqui.
func OnDefend(Character: JRPGBaseBattleChar):
	if turn != 1 || busy || SelectedCharacter == null || Character != SelectedCharacter:
		return
	Character.AvailableAction = false
	JRPGSignalBus.instance.ResultToUI.emit(Character.Char.species.get_display_name() + " is defending")
	SelectedCharacter = null
	JRPGSignalBus.instance.SelectedChar.emit(null)
	JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.SELECTABLE_PLAYER)
	CheckPlayerTurn()

func CallEnemies():
	for Char: JRPGBaseBattleChar in EnemyTeam:
		if !Char.Char.IsAlive():
			continue
		if Char.IsActionBlocked():
			JRPGSignalBus.instance.ResultToUI.emit(Char.Char.species.get_display_name() + " is stunned and loses the turn")
			continue
		var context := JRPGContext.new()
		context.Allies = EnemyTeam
		context.Enemies = PlayerTeam
		
		Char.AITurn(context)
		await JRPGSignalBus.instance.DidAction;
	
	JRPGSignalBus.instance.EndTurn.emit(null, JRPGEnums.Team.Enemy)
