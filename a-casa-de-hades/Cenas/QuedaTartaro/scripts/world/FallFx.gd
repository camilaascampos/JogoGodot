extends Node2D
class_name FallFx
## Efeito curto desenhado em código (anel que se expande, respingo).

var color := Color.WHITE
var radius := 40.0
var life := 0.35
var _t := 0.0


static func pop(parent: Node, pos: Vector2, fx_color: Color, fx_radius: float = 40.0, fx_life: float = 0.35) -> void:
	var fx := FallFx.new()
	fx.position = pos
	fx.color = fx_color
	fx.radius = fx_radius
	fx.life = fx_life
	fx.z_index = 20
	parent.add_child(fx)


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / life
	var c := Color(color.r, color.g, color.b, color.a * (1.0 - k))
	draw_arc(Vector2.ZERO, radius * (0.3 + 0.9 * k), 0.0, TAU, 32, c, 5.0 * (1.0 - k) + 1.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		draw_circle(Vector2.from_angle(a) * radius * (0.2 + 1.1 * k), 4.0 * (1.0 - k) + 1.0, c)
