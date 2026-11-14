extends CanvasLayer
class_name FallPrompt
## Dicas de controle contextuais (canto inferior esquerdo), mostradas só quando a
## habilidade é apresentada e escondidas assim que o jogador a usa.

var _box: VBoxContainer
var _rows: Dictionary = {}


func _ready() -> void:
	layer = 7
	_box = VBoxContainer.new()
	_box.position = Vector2(20, 520)
	_box.add_theme_constant_override("separation", 8)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)


func show_prompt(id: String, keys: Array, label: String, seconds: float) -> void:
	hide_prompt(id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_BRONZE, Color(0.09, 0.04, 0.04, 0.88), 2))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for k in keys:
		var cap := PanelContainer.new()
		cap.custom_minimum_size = Vector2(30, 26)
		cap.add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_TEXT, JRPGHudTheme.COL_BG_ROW, 1))
		var l := JRPGHudTheme.make_label(str(k), 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_child(l)
		row.add_child(cap)
	row.add_child(JRPGHudTheme.make_label(label, 15, JRPGHudTheme.COL_GOLD))
	panel.modulate.a = 0.0
	_box.add_child(panel)
	_rows[id] = panel
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	if seconds > 0.0:
		tween.tween_interval(seconds)
		tween.tween_callback(hide_prompt.bind(id))


func hide_prompt(id: String) -> void:
	if not _rows.has(id):
		return
	var panel: Control = _rows[id]
	_rows.erase(id)
	if is_instance_valid(panel):
		var tween := create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(panel.queue_free)


func clear() -> void:
	for id in _rows.keys():
		var panel: Control = _rows[id]
		if is_instance_valid(panel):
			panel.queue_free()
	_rows.clear()
