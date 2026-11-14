extends Camera2D
class_name FallCamera
## Câmera híbrida: mantém o grupo no alto-centro, olha um pouco para o lado em que
## ele se move, mostra o que vem de baixo e muda zoom/foco em momentos de tensão.

const BASE_ZOOM := 1.15
const BASE_OFFSET := Vector2(0, 40)

var party: Node2D
var _target_zoom := BASE_ZOOM
var _target_offset := BASE_OFFSET
var _hold := 0.0
var _shake := 0.0


func _ready() -> void:
	position = Vector2(576, 324)
	zoom = Vector2.ONE * BASE_ZOOM
	offset = BASE_OFFSET
	make_current()


## Foco temporário. O zoom nunca fica abaixo de BASE_ZOOM (o cenário tem 1152 de largura).
func focus(zoom_level: float, offset_to: Vector2, hold_seconds: float) -> void:
	_target_zoom = maxf(zoom_level, BASE_ZOOM)
	_target_offset = Vector2(clampf(offset_to.x, -60.0, 60.0), offset_to.y)
	_hold = hold_seconds


func reset_focus() -> void:
	_hold = 0.0
	_target_zoom = BASE_ZOOM
	_target_offset = BASE_OFFSET


func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


func _process(delta: float) -> void:
	if _hold > 0.0:
		_hold -= delta
		if _hold <= 0.0:
			reset_focus()
	var look := Vector2.ZERO
	if party != null and _hold <= 0.0:
		look.x = clampf((party.position.x - 576.0) * 0.06, -24.0, 24.0)
	var k := clampf(3.0 * delta, 0.0, 1.0)
	zoom = zoom.lerp(Vector2.ONE * _target_zoom, k)
	offset = offset.lerp(_target_offset + look, k)
	if _shake > 0.0:
		offset += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake * 10.0
		_shake = maxf(0.0, _shake - 2.5 * delta)
