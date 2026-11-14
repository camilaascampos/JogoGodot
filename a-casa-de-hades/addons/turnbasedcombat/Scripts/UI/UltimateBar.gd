extends PanelContainer
class_name JRPGUltimateBar
## Barra "ULTIMATE DE PERCY  65%" no canto inferior esquerdo.
## Só lê inst.ultimate_charge / inst.ultimate_max — quem enche a barra é a sua mecânica.

var inst: JRPGCharInstance
var _bar: ProgressBar
var _percent: Label


func setup(bc: JRPGBaseBattleChar) -> void:
	inst = bc.Char
	var accent := JRPGHudTheme.COL_ULT
	add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(accent.darkened(0.2), JRPGHudTheme.COL_BG, 3))
	custom_minimum_size = Vector2(445, 56)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	var title := JRPGHudTheme.make_label("ULTIMATE DE %s" % inst.species.get_display_name().to_upper(), 15, accent)
	row.add_child(title)

	_bar = JRPGHudTheme.make_bar(accent, 16, false)
	row.add_child(_bar)

	_percent = JRPGHudTheme.make_label("0%", 15)
	_percent.custom_minimum_size.x = 44
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_percent)


func _process(delta: float) -> void:
	if inst == null:
		return
	_bar.max_value = maxf(inst.ultimate_max, 1.0)
	_bar.value = move_toward(_bar.value, inst.ultimate_charge, _bar.max_value * 1.5 * delta)
	_percent.text = "%d%%" % roundi(100.0 * inst.ultimate_charge / _bar.max_value)
