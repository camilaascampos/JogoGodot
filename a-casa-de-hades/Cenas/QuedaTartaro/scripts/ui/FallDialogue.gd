extends CanvasLayer
class_name FallDialogue
## Caixa de diálogo no canto inferior direito, com retrato e nome. Não bloqueia o jogo:
## cada fala some sozinha depois de alguns segundos. Use wait_idle() para esperar o fim.
## Retratos: arte provisória ou art/portrait_<annabeth|percy>_<neutral|alert|worried|smirk>.png

signal idle

const BOX_POS := Vector2(716, 508)
const BOX_SIZE := Vector2(424, 124)

var _queue: Array[Dictionary] = []
var _busy := false
var _panel: PanelContainer
var _portrait: TextureRect
var _name: Label
var _text: Label
var _time := 0.0
var _duration := 0.0
var _chars := 0.0


func _ready() -> void:
	layer = 8
	_panel = PanelContainer.new()
	_panel.position = BOX_POS
	_panel.custom_minimum_size = BOX_SIZE
	_panel.size = BOX_SIZE
	_panel.modulate.a = 0.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_BRONZE, Color(0.09, 0.04, 0.04, 0.88), 3))
	add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_panel.add_child(row)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(84, 84)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	_name = JRPGHudTheme.make_label("", 15, JRPGHudTheme.COL_GOLD)
	col.add_child(_name)
	_text = JRPGHudTheme.make_label("", 14)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_text)


func say(who: String, text: String, mood: String = "neutral") -> void:
	_queue.append({ "who": who, "text": text, "mood": mood })
	if not _busy:
		_next()


func clear() -> void:
	_queue.clear()
	_busy = false
	_panel.modulate.a = 0.0


func is_idle() -> bool:
	return not _busy and _queue.is_empty()


func wait_idle() -> void:
	if is_idle():
		return
	await idle


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		create_tween().tween_property(_panel, "modulate:a", 0.0, 0.3)
		idle.emit()
		return
	_busy = true
	var line: Dictionary = _queue.pop_front()
	var who: String = line["who"]
	_name.text = who.to_upper()
	_name.add_theme_color_override("font_color", JRPGHudTheme.COL_GOLD if who == "Annabeth" else Color(0.45, 0.7, 1.0))
	_portrait.texture = FallArt.texture("portrait_%s_%s" % [who.to_lower(), line["mood"]])
	_text.text = line["text"]
	_text.visible_characters = 0
	_chars = 0.0
	_time = 0.0
	_duration = maxf(2.6, float(_text.text.length()) * 0.05 + 1.4)
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.2)


func _process(delta: float) -> void:
	if not _busy:
		return
	_time += delta
	_chars += delta * 45.0
	_text.visible_characters = int(_chars)
	if _time >= _duration:
		_next()
