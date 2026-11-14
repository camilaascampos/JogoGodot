extends PanelContainer
class_name JRPGCommandMenu
## Menu vertical de comandos (ATACAR / HABILIDADES / ...). Também serve para
## listar as habilidades. Funciona com mouse e com teclado (setas + Z / X).
##
## Cada entrada é um Dictionary:
##   { "id": "attack", "label": "ATACAR", "description": "...", "enabled": true }

signal activated(entry: Dictionary)
signal entry_focused(entry: Dictionary)

const ROW_HEIGHT := 36
const VISIBLE_ROWS := 4

var _scroll: ScrollContainer
var _list: VBoxContainer
var _arrow: Polygon2D
var _rows: Array[Button] = []
var _row_entries: Dictionary = {}


func _ready() -> void:
	add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_BRONZE, JRPGHudTheme.COL_BG, 3))
	custom_minimum_size = Vector2(185, ROW_HEIGHT * VISIBLE_ROWS + 12 + 3 * 4)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.follow_focus = true
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16) # espaço para a seta
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(margin)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	margin.add_child(_list)

	_arrow = Polygon2D.new()
	_arrow.polygon = PackedVector2Array([Vector2(0, 0), Vector2(9, 7), Vector2(0, 14)])
	_arrow.color = JRPGHudTheme.COL_GOLD
	_arrow.visible = false
	add_child(_arrow)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_entries(entries: Array, take_focus: bool = true) -> void:
	for row in _rows:
		_list.remove_child(row)
		row.queue_free()
	_rows.clear()
	_row_entries.clear()
	_arrow.visible = false

	for entry: Dictionary in entries:
		var row := _make_row(entry)
		_list.add_child(row)
		_rows.append(row)
		_row_entries[row] = entry

	_wire_focus_neighbors()
	_scroll.scroll_vertical = 0
	if take_focus:
		for row in _rows:
			if not row.disabled:
				row.call_deferred("grab_focus")
				break


func has_focus_in_rows() -> bool:
	var focused := get_viewport().gui_get_focus_owner()
	return focused != null and _row_entries.has(focused)


func release_focus_from_rows() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _row_entries.has(focused):
		focused.release_focus()


func activate_focused() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _row_entries.has(focused):
		activated.emit(_row_entries[focused])


func _make_row(entry: Dictionary) -> Button:
	var enabled: bool = entry.get("enabled", true)
	var b := Button.new()
	b.text = String(entry.get("label", "?"))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.disabled = not enabled
	b.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_PASS
	if entry.get("icon") is Texture2D:
		b.icon = entry["icon"]
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 22)
	b.add_theme_font_size_override("font_size", 16)
	var f := JRPGHudTheme.font()
	if f != null:
		b.add_theme_font_override("font", f)
	var txt := JRPGHudTheme.COL_TEXT if enabled else JRPGHudTheme.COL_TEXT_DIM
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, txt)

	var normal := JRPGHudTheme.panel_style(Color(0.30, 0.16, 0.12, 1.0), JRPGHudTheme.COL_BG_ROW, 1)
	var active := JRPGHudTheme.panel_style(JRPGHudTheme.COL_GOLD, JRPGHudTheme.COL_BG_ROW_ACTIVE, 2)
	normal.set_content_margin_all(6)
	active.set_content_margin_all(6)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_stylebox_override("hover", active)
	b.add_theme_stylebox_override("focus", active)
	b.add_theme_stylebox_override("pressed", active)
	b.add_theme_stylebox_override("hover_pressed", active)

	b.mouse_entered.connect(func():
		if b.disabled:
			entry_focused.emit(entry) # só mostra a descrição
		else:
			b.grab_focus())
	b.focus_entered.connect(func(): entry_focused.emit(entry))
	b.pressed.connect(func(): activated.emit(entry))
	return b


func _wire_focus_neighbors() -> void:
	# Mantém o foco dentro do menu (cima do primeiro = último, e vice-versa).
	if _rows.size() < 2:
		return
	_rows[0].focus_neighbor_top = _rows[-1].get_path()
	_rows[-1].focus_neighbor_bottom = _rows[0].get_path()


func _process(_delta: float) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _row_entries.has(focused):
		_arrow.visible = true
		var top_left := focused.global_position - global_position
		_arrow.position = Vector2(5, top_left.y + (focused.size.y - 14.0) * 0.5)
	else:
		_arrow.visible = false
