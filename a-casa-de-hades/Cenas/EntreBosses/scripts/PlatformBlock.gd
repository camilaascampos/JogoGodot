extends StaticBody2D
class_name JRPGPlatform
## Chão ou plataforma da cena "entre bosses". A origem do nó é o canto SUPERIOR ESQUERDO.
## Para criar outra: Adicionar nó > JRPGPlatform, ajuste Position e Size no Inspetor.

@export var size: Vector2 = Vector2(220, 18)
## Plataforma de mão única: dá para atravessar por baixo e pular em cima.
@export var one_way: bool = true
## Desenha um bloco simples. Desligue quando a arte do cenário já mostra o chão.
@export var draw_visual: bool = true


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size * 0.5
	shape.one_way_collision = one_way
	add_child(shape)
	queue_redraw()


func _draw() -> void:
	if not draw_visual:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.17, 0.08, 0.09))
	draw_rect(Rect2(0, 0, size.x, 4), Color(0.62, 0.22, 0.12))
	draw_rect(Rect2(0, size.y - 3, size.x, 3), Color(0.07, 0.03, 0.04))
