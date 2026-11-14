extends Area2D
class_name JRPGPickup
## Item coletável da cena "entre bosses". Ao tocar, entra no JRPGInventory
## e fica disponível na batalha em turnos.
## Para criar outro: Adicionar nó > JRPGPickup, escolha o item no Inspetor.

signal collected(pickup: JRPGPickup)

@export_enum("healing_pot", "athena_blessing", "yankees_cap") var item_id: String = "healing_pot"
@export var amount: int = 1
## Arte do item. Se vazio, desenha um símbolo provisório.
@export var texture: Texture2D

var _t := randf() * TAU
var _base_y := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # camada dos heróis
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_base_y = position.y

	# O Boné é único: se já foi pego antes, não reaparece.
	if item_id == JRPGInventory.YANKEES_CAP and JRPGInventory.has(item_id):
		queue_free()
		return

	if texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		add_child(sprite)
	queue_redraw()


func display_name() -> String:
	match item_id:
		JRPGInventory.HEALING_POT:
			return "Pote de cura"
		JRPGInventory.ATHENA_BLESSING:
			return "Bênção de Atena"
		JRPGInventory.YANKEES_CAP:
			return "Boné dos Yankees"
	return item_id


func _process(delta: float) -> void:
	_t += delta * 3.0
	position.y = _base_y + sin(_t) * 5.0


func _on_body_entered(body: Node) -> void:
	if not body is JRPGPlatformHero:
		return
	JRPGInventory.give(item_id, amount)
	collected.emit(self)
	set_deferred("monitoring", false)
	queue_free()


func _draw() -> void:
	if texture != null:
		return
	match item_id:
		JRPGInventory.HEALING_POT:
			draw_circle(Vector2(0, 4), 15, Color(0.2, 0.5, 0.95))
			draw_circle(Vector2(-5, 0), 4, Color(0.7, 0.85, 1.0))
			draw_rect(Rect2(-6, -16, 12, 8), Color(0.55, 0.38, 0.2))
		JRPGInventory.ATHENA_BLESSING:
			draw_colored_polygon(PackedVector2Array([Vector2(0, -20), Vector2(14, 0), Vector2(0, 20), Vector2(-14, 0)]), Color(0.95, 0.78, 0.25))
			draw_circle(Vector2.ZERO, 5, Color(1, 1, 0.8))
		JRPGInventory.YANKEES_CAP:
			draw_circle(Vector2(0, 0), 15, Color(0.1, 0.15, 0.4))
			draw_rect(Rect2(-2, 0, 24, 5), Color(0.08, 0.1, 0.3))
			draw_rect(Rect2(-15, 0, 30, 3), Color(0.08, 0.1, 0.3))
