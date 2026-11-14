extends CharacterBody2D
class_name JRPGPlatformHero
## Herói da cena de plataforma. O líder é controlado pelo jogador; o seguidor
## repete o caminho do líder com um pequeno atraso.
## Controles: ← → ou A D para andar, Espaço / ↑ / W para pular.

const SPEED := 280.0
const JUMP_VELOCITY := -690.0
const GRAVITY := 1900.0
const SHEET := "res://addons/turnbasedcombat/assets/Human Male Model/Human Male Model-Sheet.png"
const SPRITE_SCALE := 3.5
const TRAIL_LENGTH := 90

## Nome só para identificação.
var display_name := ""
var tint := Color.WHITE
## Se definido, este herói é o seguidor.
var leader: JRPGPlatformHero
var follow_delay := 26
var controls_enabled := true
var min_x := 40.0
var max_x := 100000.0

var facing := 1
var trail: Array[Dictionary] = []

var _sprite: Sprite2D
var _anim_t := 0.0
var _jump_was_down := false


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load(SHEET) as Texture2D
	_sprite.hframes = 254
	_sprite.modulate = tint
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.position = Vector2(0, -15.0 * SPRITE_SCALE) # pés (linha 31 do frame) em y = 0
	add_child(_sprite)

	if leader == null:
		collision_layer = 2 # camada dos heróis (pickups e portão olham para ela)
		collision_mask = 1  # chão e plataformas
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(36, 84)
		shape.shape = rect
		shape.position = Vector2(0, -42)
		add_child(shape)
	else:
		collision_layer = 0
		collision_mask = 0


func _physics_process(delta: float) -> void:
	if leader != null:
		_follow()
		return

	var dir := 0.0
	var jump_down := false
	if controls_enabled:
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			dir -= 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			dir += 1.0
		jump_down = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)

	velocity.x = move_toward(velocity.x, dir * SPEED, 2600.0 * delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif jump_down and not _jump_was_down:
		velocity.y = JUMP_VELOCITY
	_jump_was_down = jump_down

	move_and_slide()
	position.x = clampf(position.x, min_x, max_x)

	if absf(dir) > 0.0:
		facing = 1 if dir > 0.0 else -1
	var walking := absf(velocity.x) > 25.0 and is_on_floor()
	_show(walking, not is_on_floor(), delta)

	trail.append({ "pos": global_position, "facing": facing, "walking": walking, "air": not is_on_floor() })
	if trail.size() > TRAIL_LENGTH:
		trail.pop_front()


func _follow() -> void:
	var trail_data := leader.trail
	if trail_data.is_empty():
		return
	var index := maxi(trail_data.size() - 1 - follow_delay, 0)
	var step := trail_data[index]
	global_position = step["pos"]
	facing = step["facing"]
	_show(step["walking"], step["air"], get_physics_process_delta_time())


func _show(walking: bool, airborne: bool, delta: float) -> void:
	_sprite.flip_h = facing < 0
	if airborne:
		_sprite.frame = 10
	elif walking:
		_anim_t += delta
		_sprite.frame = 8 + int(_anim_t * 9.0) % 6
	else:
		_anim_t = 0.0
		_sprite.frame = 0
