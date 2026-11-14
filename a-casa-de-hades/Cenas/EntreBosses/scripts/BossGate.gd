extends Area2D
class_name JRPGBossGate
## Entrada da arena do chefe: quando o herói encosta, a cena chama a batalha em turnos.
## A origem do nó é o canto SUPERIOR ESQUERDO.

signal entered

@export var size: Vector2 = Vector2(80, 300)

var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size * 0.5
	add_child(shape)
	body_entered.connect(func(body: Node):
		if body is JRPGPlatformHero:
			entered.emit())


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.28 + 0.1 * sin(_t * 3.0)
	for i in 6:
		var w := size.x * (1.0 - i / 6.0)
		draw_rect(Rect2((size.x - w) * 0.5, 0, w, size.y), Color(0.9, 0.15, 0.08, pulse * 0.35))
