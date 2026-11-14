extends "res://addons/turnbasedcombat/Scripts/TurnManagers/TurnManagerPerTeam.gd"
## Turnos individuais por velocidade (Speed da espécie): maior Speed age primeiro,
## misturando heróis e inimigos. Empate: heróis antes, depois ordem do time.
## Reaproveita a seleção de alvo / skills / cancelar / defender do TurnManagerPerTeam.

signal ActorDone

var _actor: JRPGBaseBattleChar
var _over := false


func _ready() -> void:
	var bus := JRPGSignalBus.instance
	bus.Clicked.connect(SelectTarget)
	bus.SelectedSkill.connect(PrepareSkillTargeting)
	bus.CancelCommand.connect(CancelCommand)
	bus.DefendChosen.connect(OnDefend)

	# As equipes só são preenchidas depois deste _ready (Combat.start): espera um frame.
	await get_tree().process_frame
	# Cada personagem emite StartDone ao terminar de entrar em campo.
	for i in PlayerTeam.size() + EnemyTeam.size():
		await bus.StartDone
	_run()


func _run() -> void:
	while not _over:
		var order := _build_order()
		for i in order.size():
			var actor := order[i]
			if not actor.Char.IsAlive():
				continue
			_publish_order(order, i)
			await _take_turn(actor)
			if _check_end():
				return


func _build_order() -> Array[JRPGBaseBattleChar]:
	var all: Array[JRPGBaseBattleChar] = []
	all.append_array(PlayerTeam)
	all.append_array(EnemyTeam)
	var alive: Array[JRPGBaseBattleChar] = []
	for c in all:
		if c.Char.IsAlive():
			alive.append(c)
	alive.sort_custom(func(a: JRPGBaseBattleChar, b: JRPGBaseBattleChar) -> bool:
		var sa := a.Char.species.Speed
		var sb := b.Char.species.Speed
		if sa != sb:
			return sa > sb
		return all.find(a) < all.find(b))
	return alive


func _publish_order(order: Array[JRPGBaseBattleChar], index: int) -> void:
	var upcoming: Array = []
	for i in range(index, order.size()):
		if order[i].Char.IsAlive():
			upcoming.append(order[i])
	# completa com a ordem da próxima rodada
	for c in _build_order():
		if upcoming.size() >= 5:
			break
		upcoming.append(c)
	JRPGSignalBus.instance.TurnOrderChanged.emit(upcoming)


func _take_turn(actor: JRPGBaseBattleChar) -> void:
	var bus := JRPGSignalBus.instance
	var actor_name := actor.Char.species.get_display_name()

	bus.StartTurn.emit(actor, actor.Team)
	if not actor.Char.IsAlive():
		return

	if actor.IsActionBlocked():
		bus.ResultToUI.emit(actor_name + " loses the turn")
		actor.FloatText("PERDEU A VEZ", Color(0.9, 0.9, 0.5))
		await get_tree().create_timer(0.8).timeout
	elif actor.Team == JRPGEnums.Team.Player:
		await _player_turn(actor)
	else:
		await _enemy_turn(actor)

	if actor.Char.IsAlive():
		bus.EndTurn.emit(actor, actor.Team)


func _player_turn(actor: JRPGBaseBattleChar) -> void:
	var bus := JRPGSignalBus.instance
	_actor = actor
	turn = 1
	for hero in PlayerTeam:
		hero.AvailableAction = (hero == actor)
	SelectedCharacter = actor
	bus.ResultToUI.emit(actor.Char.species.get_display_name() + "'s turn")
	bus.SetHighlightState.emit(JRPGEnums.HighlightState.SELECTABLE_PLAYER)
	bus.SelectedChar.emit(actor)

	await ActorDone

	turn = 0
	actor.AvailableAction = false
	_actor = null
	SelectedCharacter = null
	bus.SelectedChar.emit(null)
	bus.SetHighlightState.emit(JRPGEnums.HighlightState.NONE)


func _enemy_turn(actor: JRPGBaseBattleChar) -> void:
	var context := JRPGContext.new()
	var allies: Array[JRPGBaseBattleChar] = []
	for e in EnemyTeam:
		if e.Char.IsAlive():
			allies.append(e)
	# Heróis invisíveis (Boné) não entram na lista de alvos — a não ser que todos estejam.
	var visible_heroes: Array[JRPGBaseBattleChar] = []
	var alive_heroes: Array[JRPGBaseBattleChar] = []
	for h in PlayerTeam:
		if h.Char.IsAlive():
			alive_heroes.append(h)
			if not h.IsInvisible():
				visible_heroes.append(h)
	context.Allies = allies
	context.Enemies = visible_heroes if not visible_heroes.is_empty() else alive_heroes

	JRPGSignalBus.instance.ResultToUI.emit(actor.Char.species.get_display_name() + "'s turn")
	actor.AITurn(context)
	await JRPGSignalBus.instance.DidAction


## Chamado pelo código herdado depois de cada ação do herói.
func CheckPlayerTurn():
	if _actor != null and not _actor.AvailableAction:
		ActorDone.emit()


func _check_end() -> bool:
	var heroes_alive := false
	for h in PlayerTeam:
		if h.Char.IsAlive():
			heroes_alive = true
	var enemies_alive := false
	for e in EnemyTeam:
		if e.Char.IsAlive():
			enemies_alive = true
	if heroes_alive and enemies_alive:
		return false

	_over = true
	var bus := JRPGSignalBus.instance
	bus.SetHighlightState.emit(JRPGEnums.HighlightState.NONE)
	bus.SelectedChar.emit(null)
	bus.ResultToUI.emit("Victory!" if heroes_alive else "Defeat...")
	bus.BattleEnded.emit(heroes_alive)
	return true
