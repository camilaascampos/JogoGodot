extends Node2D
class_name FallParty
## Percy e Annabeth como uma única entidade (abraçados) caindo juntos.
## Controles: ← → / A D mover · Z espada · X escudo (segurar) · C jato de água.
## Habilidades só funcionam depois de liberadas em `unlocked` (o diretor libera no tutorial).

signal slashed(slash_id: int)
signal shield_changed(active: bool)
signal jet_fired(jet_id: int)

const MIN_X := 190.0
const MAX_X := 962.0
const SPEED_X := 380.0
const ART_HEIGHT := 96.0
## Vistas usadas da arte de 8 direções (arte/party/south.png etc.). Troque aqui se preferir outra.
const FACING_IDLE := "south"
const FACING_LEFT := "south-west"
const FACING_RIGHT := "south-east"
const ENERGY_MAX := 100.0
const JET_COST := 40.0
const JET_TIME := 0.7
const SHIELD_DRAIN := 24.0
const REGEN := 16.0

var controls := true
var unlocked := { "sword": false, "shield": false, "jet": false }
var energy := ENERGY_MAX
var shield_on := false
var invuln := 0.0
var slash_id := 0
var jet_id := 0
## Coluna de água contínua usada no final (não é o jato ofensivo).
var column := false

var _vx := 0.0
var _slash_t := 0.0
var _slash_cd := 0.0
var _jet_t := 0.0
var _jet_cd := 0.0
var _clock := 0.0
var _prev_sword := false
var _prev_jet := false
var _sprite: FallSprite


func _ready() -> void:
	z_index = 5
	_sprite = FallSprite.new()
	_sprite.setup("party", Vector2(0, ART_HEIGHT))
	add_child(_sprite)


func _process(delta: float) -> void:
	_clock += delta
	var dir := 0.0
	var want_sword := false
	var want_shield := false
	var want_jet := false
	if controls:
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			dir -= 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			dir += 1.0
		want_sword = Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_J)
		want_shield = Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_K)
		want_jet = Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_L)

	var slow := 0.45 if _jet_t > 0.0 else (0.8 if shield_on else 1.0)
	_vx = move_toward(_vx, dir * SPEED_X * slow, 2600.0 * delta)
	position.x = clampf(position.x + _vx * delta, MIN_X, MAX_X)

	_slash_cd -= delta
	_slash_t -= delta
	_jet_cd -= delta
	_jet_t -= delta

	if want_sword and not _prev_sword and unlocked["sword"] and _slash_cd <= 0.0 and not shield_on:
		slash_id += 1
		_slash_t = 0.22
		_slash_cd = 0.42
		slashed.emit(slash_id)

	var shield_wanted: bool = want_shield and unlocked["shield"] and energy > 6.0 and _jet_t <= 0.0
	if shield_wanted != shield_on:
		shield_on = shield_wanted
		shield_changed.emit(shield_on)
	if shield_on:
		energy = maxf(0.0, energy - SHIELD_DRAIN * delta)

	if want_jet and not _prev_jet and unlocked["jet"] and _jet_cd <= 0.0 and energy >= JET_COST and not shield_on:
		energy -= JET_COST
		jet_id += 1
		_jet_t = JET_TIME
		_jet_cd = 1.0
		jet_fired.emit(jet_id)

	if not shield_on and _jet_t <= 0.0:
		energy = minf(ENERGY_MAX, energy + REGEN * delta)

	_prev_sword = want_sword
	_prev_jet = want_jet
	invuln = maxf(0.0, invuln - delta)

	# Animações opcionais por estado (só se você fornecer art/party_slash*.png etc.).
	var want := "party"
	if _slash_t > 0.0 and FallArt.has_art("party_slash"):
		want = "party_slash"
	elif _jet_t > 0.0 and FallArt.has_art("party_jet"):
		want = "party_jet"
	elif shield_on and FallArt.has_art("party_shield"):
		want = "party_shield"
	var facing := FACING_IDLE
	if _vx < -80.0:
		facing = FACING_LEFT
	elif _vx > 80.0:
		facing = FACING_RIGHT
	_sprite.set_art(want + "@" + facing if FallArt.TREAT_DIRECTIONS_AS_VIEWS else want)

	_sprite.rotation = clampf(_vx / SPEED_X * 0.2, -0.25, 0.25) + sin(_clock * 2.2) * 0.03
	_sprite.position.y = sin(_clock * 3.1) * 2.5
	_sprite.modulate.a = (0.5 + 0.5 * sin(_clock * 32.0)) if invuln > 0.0 else 1.0
	queue_redraw()


func jet_active() -> bool:
	return _jet_t > 0.0


## Caixa de colisão (menor que o sprite, para ser justa).
func hit_rect() -> Rect2:
	return Rect2(position + Vector2(-24, -34), Vector2(48, 66))


func slash_rect() -> Rect2:
	return Rect2(position + Vector2(-100, -10), Vector2(200, 125))


func jet_rect() -> Rect2:
	return Rect2(position + Vector2(-70, 30), Vector2(140, 760))


func shield_rect() -> Rect2:
	return Rect2(position + Vector2(-72, -72), Vector2(144, 144))


func reset_for_checkpoint(spawn: Vector2) -> void:
	position = spawn
	_vx = 0.0
	energy = ENERGY_MAX
	shield_on = false
	column = false
	_slash_t = 0.0
	_jet_t = 0.0
	invuln = 1.6
	controls = true


func _draw() -> void:
	if shield_on:
		draw_circle(Vector2.ZERO, 66.0, Color(0.3, 0.8, 1.0, 0.18))
		draw_arc(Vector2.ZERO, 66.0, 0.0, TAU, 48, Color(0.6, 0.95, 1.0, 0.9), 3.0)
	if _slash_t > 0.0:
		var a := _slash_t / 0.22
		draw_arc(Vector2(0, 10), 82.0, deg_to_rad(10), deg_to_rad(170), 20, Color(1, 1, 1, a), 7.0)
		draw_arc(Vector2(0, 10), 70.0, deg_to_rad(20), deg_to_rad(160), 20, Color(0.6, 0.9, 1.0, a * 0.7), 4.0)
	if _jet_t > 0.0:
		var w := 90.0 + 12.0 * sin(_clock * 40.0)
		draw_rect(Rect2(-w * 0.5, 34, w, 760), Color(0.25, 0.8, 1.0, 0.45))
		draw_rect(Rect2(-w * 0.2, 34, w * 0.4, 760), Color(0.9, 1.0, 1.0, 0.65))
	if column:
		var w2 := 130.0 + 14.0 * sin(_clock * 12.0)
		draw_rect(Rect2(-w2 * 0.5, 40, w2, 900), Color(0.2, 0.7, 1.0, 0.35))
		draw_rect(Rect2(-w2 * 0.25, 40, w2 * 0.5, 900), Color(0.8, 1.0, 1.0, 0.5))
