extends PanelContainer
class_name JRPGTurnOrderStrip
## Faixa "PRÓXIMO TURNO" com o retrato de cada combatente.
##
## Hoje o TurnManagerPerTeam age por time (heróis e depois inimigos), então a
## ordem mostrada é heróis -> inimigos. Quando você criar um turn manager por
## velocidade, chame set_order() com a ordem real a cada mudança de turno.

var _icons: Array[Dictionary] = [] # { "char": JRPGBaseBattleChar, "frame": PanelContainer, "color": Color }
var _row: HBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_BRONZE, JRPGHudTheme.COL_BG, 2))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	add_child(col)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 6)
	col.add_child(_row)

	var title := JRPGHudTheme.make_label("PRÓXIMO TURNO", 11, JRPGHudTheme.COL_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)


func set_order(order: Array[JRPGBaseBattleChar]) -> void:
	order = order.slice(0, 5)
	for icon in _icons:
		var old := icon["frame"] as Node
		_row.remove_child(old)
		old.queue_free()
	_icons.clear()

	for bc in order:
		var color := JRPGHudTheme.COL_ENEMY
		if bc.Team == JRPGEnums.Team.Player:
			color = bc.Char.species.HudColor
		if _icons.is_empty():
			color = JRPGHudTheme.COL_GOLD # quem age agora
		var frame := JRPGHudTheme.make_portrait(JRPGHudTheme.portrait_for(bc), 42, color)
		_row.add_child(frame)
		_icons.append({ "char": bc, "frame": frame, "color": color })


func _process(_delta: float) -> void:
	for icon in _icons:
		var bc := icon["char"] as JRPGBaseBattleChar
		var frame := icon["frame"] as PanelContainer
		if bc == null or not is_instance_valid(bc) or bc.Char == null:
			continue
		frame.modulate = Color.WHITE if bc.Char.IsAlive() else Color(0.5, 0.5, 0.5, 0.8)
