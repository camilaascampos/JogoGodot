extends CanvasLayer
class_name FallHud
## HUD mínima e cinematográfica: barra de água (só depois de liberada), aviso de checkpoint,
## tela de falha, flash e fade.

var _energy: ProgressBar
var _energy_box: Control
var _fade: ColorRect
var _flash: ColorRect
var _message: Label
var _sub: Label
var _checkpoint: Label
var _debug: Label


func _ready() -> void:
	layer = 20
	_energy_box = Control.new()
	_energy_box.position = Vector2(20, 18)
	_energy_box.visible = false
	_energy_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_energy_box)
	var caption := JRPGHudTheme.make_label("ÁGUA", 12, JRPGHudTheme.COL_ULT)
	_energy_box.add_child(caption)
	_energy = JRPGHudTheme.make_bar(JRPGHudTheme.COL_ULT, 12, false)
	_energy.position = Vector2(0, 18)
	_energy.custom_minimum_size = Vector2(200, 12)
	_energy.size = Vector2(200, 12)
	_energy.max_value = FallParty.ENERGY_MAX
	_energy_box.add_child(_energy)

	_checkpoint = JRPGHudTheme.make_label("CHECKPOINT", 14, JRPGHudTheme.COL_GOLD)
	_checkpoint.position = Vector2(500, 18)
	_checkpoint.size = Vector2(152, 24)
	_checkpoint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_checkpoint.modulate.a = 0.0
	add_child(_checkpoint)

	_flash = _full_rect(Color(1, 1, 1, 0))
	_fade = _full_rect(Color(0, 0, 0, 1))

	_message = JRPGHudTheme.make_label("", 56, JRPGHudTheme.COL_ENEMY)
	_message.size = Vector2(1152, 80)
	_message.position = Vector2(0, 230)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.modulate.a = 0.0
	add_child(_message)
	_sub = JRPGHudTheme.make_label("", 18)
	_sub.size = Vector2(1152, 30)
	_sub.position = Vector2(0, 318)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.modulate.a = 0.0
	add_child(_sub)

	_debug = JRPGHudTheme.make_label("", 12, JRPGHudTheme.COL_TEXT_DIM)
	_debug.position = Vector2(900, 8)
	add_child(_debug)


func _full_rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.size = Vector2(1152, 648)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func set_energy(value: float, show_bar: bool) -> void:
	_energy_box.visible = show_bar
	_energy.value = value


func set_debug(text: String) -> void:
	_debug.text = text


func fade_to(alpha: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, seconds)
	await tween.finished


func flash() -> void:
	_flash.color.a = 0.9
	create_tween().tween_property(_flash, "color:a", 0.0, 0.7)


func show_checkpoint() -> void:
	var tween := create_tween()
	tween.tween_property(_checkpoint, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.4)
	tween.tween_property(_checkpoint, "modulate:a", 0.0, 0.5)


func show_message(title: String, sub: String = "") -> void:
	_message.text = title
	_sub.text = sub
	_message.modulate.a = 1.0
	_sub.modulate.a = 1.0


func hide_message() -> void:
	_message.modulate.a = 0.0
	_sub.modulate.a = 0.0
