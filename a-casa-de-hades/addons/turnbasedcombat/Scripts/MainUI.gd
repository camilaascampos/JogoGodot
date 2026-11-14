extends Control
## HUD de batalha (montada em código). Layout baseado no mockup:
##  - topo esquerdo : HP dos inimigos
##  - baixo esquerdo: cartões dos heróis + barra de ultimate
##  - baixo centro  : menu de comandos + descrição
##  - baixo direito : PRÓXIMO TURNO + dicas de teclas (Z / X)
## Para mexer em posições, mude as constantes POS_* / SIZE_* abaixo.

const SCREEN_SIZE := Vector2(1152, 648)
const POS_ENEMIES := Vector2(8, 8)
const POS_HEROES := Vector2(12, 446)
const POS_ULTIMATE := Vector2(12, 570)
const POS_MENU := Vector2(475, 430)
const POS_DESC := Vector2(670, 451)
const SIZE_DESC := Vector2(182, 93)
const POS_TURNS := Vector2(672, 561)
const SIZE_TURNS := Vector2(277, 71)
const POS_KEYS := Vector2(961, 573)
const SIZE_KEYS := Vector2(179, 61)

enum State { NONE, MAIN, SKILLS, ITEMS, TARGETING }

var _state := State.NONE
var _selected: JRPGBaseBattleChar
var _players: Array[JRPGBaseBattleChar] = []
var _enemies: Array[JRPGBaseBattleChar] = []
var _cards: Array[JRPGPlayerCard] = []
var _log: Array[String] = []
var _battle_over := false
var _player_won := false
## Preenchido pelo Combat.gd (menu ITEM).
var item_skills: Array[JRPGBaseSkill] = []

var _menu: JRPGCommandMenu
var _desc_title: Label
var _desc_body: Label
var _turn_strip: JRPGTurnOrderStrip


func _ready() -> void:
	custom_minimum_size = SCREEN_SIZE
	size = SCREEN_SIZE
	var bus := JRPGSignalBus.instance
	bus.SelectedChar.connect(_on_selected_char)
	bus.ResultToUI.connect(_on_log)
	bus.TurnOrderChanged.connect(_on_turn_order)
	bus.BattleEnded.connect(_on_battle_ended)


## Chamado pelo Combat.gd depois de criar os personagens.
func setup_hud(players: Array[JRPGBaseBattleChar], enemies: Array[JRPGBaseBattleChar]) -> void:
	_players = players
	_enemies = enemies

	# Inimigos (topo esquerdo)
	var enemy_col := VBoxContainer.new()
	enemy_col.position = POS_ENEMIES
	enemy_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_col.add_theme_constant_override("separation", 11)
	add_child(enemy_col)
	for e in enemies:
		var panel := JRPGEnemyHpPanel.new()
		enemy_col.add_child(panel)
		panel.setup(e)

	# Heróis (baixo esquerdo)
	var hero_row := HBoxContainer.new()
	hero_row.position = POS_HEROES
	hero_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_row.add_theme_constant_override("separation", 9)
	add_child(hero_row)
	for p in players:
		var card := JRPGPlayerCard.new()
		hero_row.add_child(card)
		card.setup(p)
		card.clicked.connect(func(bc): JRPGSignalBus.instance.Clicked.emit(bc))
		_cards.append(card)

	# Ultimate: primeiro herói que tem
	for p in players:
		if p.Char.species.HasUltimate:
			var ult := JRPGUltimateBar.new()
			ult.position = POS_ULTIMATE
			add_child(ult)
			ult.setup(p)
			break

	# Menu de comandos
	_menu = JRPGCommandMenu.new()
	_menu.position = POS_MENU
	add_child(_menu)
	_menu.activated.connect(_on_menu_activated)
	_menu.entry_focused.connect(_on_entry_focused)

	# Descrição
	var desc := PanelContainer.new()
	desc.position = POS_DESC
	desc.custom_minimum_size = SIZE_DESC
	desc.size = SIZE_DESC
	desc.clip_contents = true
	desc.add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_BRONZE, JRPGHudTheme.COL_BG, 3))
	add_child(desc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	desc.add_child(col)
	_desc_title = JRPGHudTheme.make_label("", 15, JRPGHudTheme.COL_GOLD)
	col.add_child(_desc_title)
	_desc_body = JRPGHudTheme.make_label("", 12)
	_desc_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desc_body.add_theme_constant_override("outline_size", 2)
	col.add_child(_desc_body)

	# Próximo turno
	_turn_strip = JRPGTurnOrderStrip.new()
	_turn_strip.position = POS_TURNS
	_turn_strip.custom_minimum_size = SIZE_TURNS
	add_child(_turn_strip)
	var order: Array[JRPGBaseBattleChar] = []
	order.append_array(players)
	order.append_array(enemies)
	_turn_strip.set_order(order)

	# Dicas de teclas
	var keys := PanelContainer.new()
	keys.position = POS_KEYS
	keys.custom_minimum_size = SIZE_KEYS
	keys.add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_BRONZE, JRPGHudTheme.COL_BG, 3))
	keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(keys)
	var kcol := VBoxContainer.new()
	kcol.add_theme_constant_override("separation", 6)
	keys.add_child(kcol)
	kcol.add_child(_key_hint("Z", "SELECIONAR"))
	kcol.add_child(_key_hint("X", "VOLTAR"))

	_set_state(State.NONE)


func _key_hint(key: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var cap := PanelContainer.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.custom_minimum_size = Vector2(22, 22)
	cap.add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_TEXT, JRPGHudTheme.COL_BG_ROW, 1))
	var l := JRPGHudTheme.make_label(key, 13)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(l)
	row.add_child(cap)
	row.add_child(JRPGHudTheme.make_label(text, 14))
	return row


# ---------------------------------------------------------------- estados

func _set_state(new_state: State, skill: JRPGBaseSkill = null) -> void:
	_state = new_state
	for card in _cards:
		card.set_selected(card.battle_char == _selected)

	match new_state:
		State.NONE:
			_menu.set_entries(_main_entries(false), false)
			_show_log()
		State.MAIN:
			_menu.set_entries(_main_entries(true), true)
		State.SKILLS:
			_menu.set_entries(_skill_entries(_visible_skills()), true)
		State.ITEMS:
			_menu.set_entries(_skill_entries(_visible_items()), true)
		State.TARGETING:
			_menu.set_entries(_main_entries(false), false)
			var name_text := skill.Name if skill != null else ""
			var hint := "Executando..."
			if skill != null and skill.Target == JRPGEnums.Target.Enemy:
				hint = "Clique em um inimigo.\nX para cancelar."
			elif skill != null and skill.Target == JRPGEnums.Target.Ally:
				hint = "Clique em um aliado.\nX para cancelar."
			_show_text(name_text.to_upper(), hint)


func _main_entries(enabled: bool) -> Array:
	var basic := _basic_attack()
	return [
		{ "id": "attack", "label": "ATACAR", "enabled": enabled and basic != null and basic.CanUse(_selected.Char), "skill": basic,
			"description": "Ataque básico com a arma equipada." },
		{ "id": "skills", "label": "HABILIDADES", "enabled": enabled and _selected != null and not _visible_skills().is_empty(),
			"description": "Usa uma habilidade especial." },
		{ "id": "defend", "label": "DEFENDER", "enabled": enabled,
			"description": "Passa a vez em postura defensiva." },
		{ "id": "items", "label": "ITEM", "enabled": enabled and _selected != null and not _visible_items().is_empty(),
			"description": "Usa um item da mochila." },
	]


## Skills do herói que o jogador já "desbloqueou" (RequiredItem pego antes da batalha).
func _visible_skills() -> Array[JRPGBaseSkill]:
	var result: Array[JRPGBaseSkill] = []
	if _selected == null:
		return result
	for skill: JRPGBaseSkill in _selected.Char.equipped_skills:
		if skill.IsUnlocked():
			result.append(skill)
	return result


func _visible_items() -> Array[JRPGBaseSkill]:
	var result: Array[JRPGBaseSkill] = []
	for skill: JRPGBaseSkill in item_skills:
		if skill.IsUnlocked():
			result.append(skill)
	return result


func _skill_entries(skills: Array[JRPGBaseSkill]) -> Array:
	var entries: Array = []
	if _selected == null:
		return entries
	for skill: JRPGBaseSkill in skills:
		var unit := "HP" if skill.CostType == JRPGEnums.CostType.Health else "EN"
		var cd := _selected.Char.cooldown_left(skill)
		var label := skill.Name
		if skill.ConsumeItem and skill.RequiredItem != "":
			label += "  x%d" % JRPGInventory.count(skill.RequiredItem)
		elif cd > 0:
			label += "  CD%d" % cd
		elif skill.Cost > 0:
			label += "  %d" % skill.Cost
		var desc := skill.Description
		if skill.Cost > 0:
			desc += "\nCusto: %d %s" % [skill.Cost, unit]
		if skill.Cooldown > 0:
			desc += "\nRecarga: %d turnos" % skill.Cooldown
		if skill.RequiresUltimate:
			desc += "\nRequer ultimate cheia."
		entries.append({ "id": "skill", "label": label, "skill": skill,
			"enabled": skill.CanUse(_selected.Char), "description": desc })
	return entries


func _basic_attack() -> JRPGBaseSkill:
	if _selected == null:
		return null
	var species := _selected.Char.species
	if species.BasicAttack != null:
		return species.BasicAttack
	if not _selected.Char.equipped_skills.is_empty():
		return _selected.Char.equipped_skills[0]
	return null


# ---------------------------------------------------------------- eventos

func _on_selected_char(bc: JRPGBaseBattleChar) -> void:
	_selected = bc
	_set_state(State.NONE if bc == null else State.MAIN)


func _on_log(text: String) -> void:
	_log.append(text)
	if _log.size() > 3:
		_log.pop_front()
	if _state == State.NONE:
		_show_log()


func _on_entry_focused(entry: Dictionary) -> void:
	_show_text(String(entry.get("label", "")), String(entry.get("description", "")))


func _on_menu_activated(entry: Dictionary) -> void:
	if not entry.get("enabled", true):
		return
	match String(entry.get("id", "")):
		"attack", "skill":
			_use_skill(entry["skill"])
		"skills":
			_set_state(State.SKILLS)
		"items":
			_set_state(State.ITEMS)
		"defend":
			JRPGSignalBus.instance.DefendChosen.emit(_selected)


func _use_skill(skill: JRPGBaseSkill) -> void:
	if skill == null:
		return
	_set_state(State.TARGETING, skill) # antes do emit: skills instantâneas voltam para NONE sozinhas
	JRPGSignalBus.instance.SelectedSkill.emit(skill)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if _battle_over:
		if key.keycode == KEY_Z or key.keycode == KEY_ENTER:
			_finish_battle()
			get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_Z:
		_confirm()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_X:
		_back()
		get_viewport().set_input_as_handled()


func _confirm() -> void:
	match _state:
		State.NONE:
			for bc in _players:
				if bc.Char.IsAlive() and bc.AvailableAction:
					JRPGSignalBus.instance.Clicked.emit(bc)
					break
		State.MAIN, State.SKILLS, State.ITEMS:
			_menu.activate_focused()


func _back() -> void:
	match _state:
		State.SKILLS, State.ITEMS:
			_set_state(State.MAIN)
		State.TARGETING:
			JRPGSignalBus.instance.CancelCommand.emit()
			_set_state(State.MAIN)
		State.MAIN:
			JRPGSignalBus.instance.CancelCommand.emit()


# ---------------------------------------------------------------- descrição

func _show_text(title: String, body: String) -> void:
	_desc_title.text = title
	_desc_body.text = body


func _show_log() -> void:
	_show_text("BATALHA", "\n".join(PackedStringArray(_log)) if not _log.is_empty() else "Selecione um herói.")


# ---------------------------------------------------------------- ordem / fim de batalha

func _on_turn_order(order: Array) -> void:
	if _turn_strip == null:
		return
	var typed: Array[JRPGBaseBattleChar] = []
	for bc in order:
		typed.append(bc)
	_turn_strip.set_order(typed)


func _on_battle_ended(player_won: bool) -> void:
	_battle_over = true
	_selected = null
	_set_state(State.NONE)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.size = SCREEN_SIZE
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.size = SCREEN_SIZE
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	center.add_child(col)

	var title := JRPGHudTheme.make_label("VITÓRIA" if player_won else "DERROTA", 72,
		JRPGHudTheme.COL_GOLD if player_won else JRPGHudTheme.COL_ENEMY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_player_won = player_won
	var button := Button.new()
	button.text = "CONTINUAR" if player_won else "TENTAR NOVAMENTE"
	button.custom_minimum_size = Vector2(300, 52)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_font_override("font", JRPGHudTheme.font())
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(c, JRPGHudTheme.COL_TEXT)
	var normal := JRPGHudTheme.panel_style(JRPGHudTheme.COL_BRONZE, JRPGHudTheme.COL_BG_ROW, 2)
	var active := JRPGHudTheme.panel_style(JRPGHudTheme.COL_GOLD, JRPGHudTheme.COL_BG_ROW_ACTIVE, 3)
	button.add_theme_stylebox_override("normal", normal)
	for s in ["hover", "focus", "pressed"]:
		button.add_theme_stylebox_override(s, active)
	button.pressed.connect(_finish_battle)
	col.add_child(button)
	button.call_deferred("grab_focus")

	var hint := JRPGHudTheme.make_label("Z  CONFIRMAR", 14, JRPGHudTheme.COL_TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


## Vitória: avisa a história (Combat.battle_finished). Derrota: recomeça a luta.
func _finish_battle() -> void:
	if _player_won:
		JRPGSignalBus.instance.EndBattle.emit()
	else:
		JRPGSignalBus.instance.RetryBattle.emit()
