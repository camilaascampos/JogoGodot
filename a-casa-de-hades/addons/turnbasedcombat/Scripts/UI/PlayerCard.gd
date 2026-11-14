extends PanelContainer
class_name JRPGPlayerCard
## Cartão de um herói (retrato, nome, HP e EN) no canto inferior esquerdo.

## Clique no cartão = clique no herói em campo (seleciona o herói).
signal clicked(bc: JRPGBaseBattleChar)

var battle_char: JRPGBaseBattleChar
var inst: JRPGCharInstance
var accent: Color = JRPGHudTheme.COL_PLAYER_DEFAULT
var selected := false

var _hp_bar: ProgressBar
var _hp_value: Label
var _en_bar: ProgressBar
var _en_value: Label


func setup(bc: JRPGBaseBattleChar) -> void:
	battle_char = bc
	inst = bc.Char
	accent = inst.species.HudColor
	custom_minimum_size = Vector2(218, 110)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_border()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	var portrait := JRPGHudTheme.make_portrait(JRPGHudTheme.portrait_for(bc), 78, accent)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)

	col.add_child(JRPGHudTheme.make_label(inst.species.get_display_name().to_upper(), 17, accent))

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 4)
	col.add_child(hp_row)
	var hp_tag := JRPGHudTheme.make_label("HP", 12, JRPGHudTheme.COL_HP)
	hp_tag.custom_minimum_size.x = 20
	hp_row.add_child(hp_tag)
	_hp_bar = JRPGHudTheme.make_bar(JRPGHudTheme.COL_HP, 16)
	_hp_value = _hp_bar.get_node("Value") as Label
	hp_row.add_child(_hp_bar)

	if inst.max_magi > 0:
		var en_row := HBoxContainer.new()
		en_row.add_theme_constant_override("separation", 4)
		col.add_child(en_row)
		var en_tag := JRPGHudTheme.make_label("EN", 12, JRPGHudTheme.COL_EN)
		en_tag.custom_minimum_size.x = 20
		en_row.add_child(en_tag)
		_en_bar = JRPGHudTheme.make_bar(JRPGHudTheme.COL_EN, 16)
		_en_value = _en_bar.get_node("Value") as Label
		en_row.add_child(_en_bar)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(battle_char)


func set_selected(value: bool) -> void:
	selected = value
	_apply_border()


func _apply_border() -> void:
	var border := JRPGHudTheme.COL_GOLD if selected else accent.darkened(0.25)
	var sb := JRPGHudTheme.panel_style(border, JRPGHudTheme.COL_BG, 3 if selected else 2)
	sb.set_content_margin_all(8)
	add_theme_stylebox_override("panel", sb)


func _process(delta: float) -> void:
	if inst == null:
		return
	_hp_bar.max_value = inst.max_hp
	_hp_bar.value = move_toward(_hp_bar.value, inst.current_hp, maxf(inst.max_hp, 1) * 1.5 * delta)
	_hp_value.text = "%d/%d" % [maxi(inst.current_hp, 0), inst.max_hp]

	if _en_bar != null:
		_en_bar.max_value = inst.max_magi
		_en_bar.value = move_toward(_en_bar.value, inst.current_magi, maxf(inst.max_magi, 1) * 1.5 * delta)
		_en_value.text = "%d/%d" % [maxi(inst.current_magi, 0), inst.max_magi]

	# Fica mais apagado quando já agiu neste turno (ou está caído).
	var can_act := inst.IsAlive() and battle_char.AvailableAction
	modulate = Color.WHITE if (can_act or selected) else Color(0.75, 0.75, 0.75, 1.0)
