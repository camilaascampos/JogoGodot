extends PanelContainer
class_name JRPGEnemyHpPanel
## Painel pequeno do canto superior esquerdo: nome do inimigo + barra de HP.

var inst: JRPGCharInstance
var _bar: ProgressBar
var _value: Label


func setup(battle_char: JRPGBaseBattleChar) -> void:
	inst = battle_char.Char
	add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_ENEMY))
	custom_minimum_size = Vector2(217, 57)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	row.add_child(JRPGHudTheme.make_portrait(
		JRPGHudTheme.portrait_for(battle_char), 38, JRPGHudTheme.COL_ENEMY))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)

	col.add_child(JRPGHudTheme.make_label(inst.species.get_display_name().to_upper(), 15))

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 4)
	col.add_child(hp_row)
	hp_row.add_child(JRPGHudTheme.make_label("HP", 11, JRPGHudTheme.COL_GOLD))
	_bar = JRPGHudTheme.make_bar(JRPGHudTheme.COL_HP, 15)
	_value = _bar.get_node("Value") as Label
	hp_row.add_child(_bar)


func _process(delta: float) -> void:
	if inst == null or _bar == null:
		return
	_bar.max_value = inst.max_hp
	_bar.value = move_toward(_bar.value, inst.current_hp, maxf(inst.max_hp, 1) * 1.5 * delta)
	_value.text = "%d/%d" % [maxi(inst.current_hp, 0), inst.max_hp]
	modulate = Color.WHITE if inst.IsAlive() else Color(1, 1, 1, 0.4)
