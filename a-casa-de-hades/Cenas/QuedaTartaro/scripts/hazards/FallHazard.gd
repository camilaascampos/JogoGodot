extends Node2D
class_name FallHazard
## Obstáculo, criatura ou projétil da queda. Tudo é descrito em KINDS (dados);
## a arte vem do FallArt e é esticada para a caixa `box`, então trocar a imagem
## não altera colisão nem comportamento.
##
##   sword : a espada (Z) pode ferir      jet  : o jato (C) pode ferir/destruir
##   mult  : velocidade de queda relativa ao cenário (<1 = criatura que se aproxima devagar)
##   homing: velocidade lateral com que persegue o grupo
##   lethal: encostar no grupo = falha

signal fire_requested(hazard: FallHazard)

const KINDS := {
	"rock_small": { "art": "rock_small", "box": Vector2(56, 56), "hp": 1, "sword": false, "jet": true, "mult": 1.0, "homing": 0.0, "lethal": true },
	"rock_large": { "art": "rock_large", "box": Vector2(120, 110), "hp": 1, "sword": false, "jet": true, "mult": 1.0, "homing": 0.0, "lethal": true },
	"creature_small": { "art": "creature_small", "box": Vector2(64, 56), "hp": 1, "sword": true, "jet": true, "mult": 0.7, "homing": 55.0, "lethal": true },
	"creature_mid": { "art": "creature_mid", "box": Vector2(96, 88), "hp": 2, "sword": true, "jet": true, "mult": 0.65, "homing": 85.0, "lethal": true, "knock": 30 },
	"creature_brute": { "art": "creature_brute", "box": Vector2(150, 130), "hp": 4, "sword": true, "jet": true, "mult": 0.55, "homing": 40.0, "lethal": true, "knock": 38, "jet_dmg": 2 },
	"creature_giant": { "art": "creature_giant", "box": Vector2(360, 240), "hp": 3, "sword": false, "jet": true, "mult": 0.4, "homing": 0.0, "lethal": true, "jet_dmg": 1 },
	"barrier": { "art": "barrier", "box": Vector2(1152, 64), "hp": 1, "sword": false, "jet": true, "mult": 1.0, "homing": 0.0, "lethal": true },
	"spitter": { "art": "spitter", "box": Vector2(120, 72), "hp": 999, "sword": false, "jet": false, "mult": 1.0, "homing": 0.0, "lethal": false, "once": true, "fps": 12.0  },
	"poison": { "art": "poison", "box": Vector2(100, 60), "hp": 1, "sword": false, "jet": false, "mult": 0.0, "homing": 0.0, "lethal": true },
}

var kind := ""
var cfg: Dictionary = {}
var box := Vector2(50, 50)
var hp := 1
var alive := true
var burst := false
var shots_left := 0
var fire_cd := 0.9
var vel := Vector2.ZERO
## Espelha a arte (o verme da parede direita cospe para a esquerda).
var flip := false

var _sprite: Sprite2D
var _flash := 0.0
var _last_slash := -1
var _last_jet := -1
var _anim_started := false


static func box_of(kind_name: String) -> Vector2:
	return KINDS[kind_name]["box"]


static func create(kind_name: String) -> FallHazard:
	var h := FallHazard.new()
	h.kind = kind_name
	h.cfg = KINDS[kind_name]
	h.box = h.cfg["box"]
	h.hp = int(h.cfg["hp"])
	return h


func _ready() -> void:
	var fs := FallSprite.new()
	fs.setup(cfg["art"], box)
	if cfg.get("once", false):
		fs.configure(float(cfg.get("fps", FallArt.DEFAULT_FPS)), false)
	else:
		fs.randomize_phase()
	fs.flip_h = flip
	_sprite = fs
	add_child(_sprite)


func tick(delta: float, world_speed: float, party: FallParty) -> void:
	if not alive:
		return
	if _flash > 0.0:
		_flash -= delta
		_sprite.modulate = Color(1.7, 1.7, 1.7) if _flash > 0.0 else Color.WHITE

	match kind:
		"poison":
			position += vel * delta
			if position.y > 780.0 or position.y < -120.0 or position.x < -160.0 or position.x > 1320.0:
				_remove()
			return
		"spitter":
			position.y -= world_speed * delta
			_tick_spitter(delta, party)
		_:
			position.y -= world_speed * float(cfg["mult"]) * delta
			var homing := 190.0 if burst else float(cfg["homing"])
			if homing > 0.0 and position.y > party.position.y:
				position.x += clampf(party.position.x - position.x, -1.0, 1.0) * homing * delta
	if position.y < -260.0:
		_remove()


func _tick_spitter(delta: float, party: FallParty) -> void:
	if shots_left <= 0:
		return
	if position.y > 600.0 or position.y < party.position.y - 60.0:
		return
	fire_cd -= delta
	if fire_cd <= 0.0:
		shots_left -= 1
		fire_cd = 1.1
		_anim_started = false
		_sprite.modulate = Color.WHITE
		fire_requested.emit(self)
	elif fire_cd < 0.7:
		var p := 0.5 + 0.5 * sin(fire_cd * 40.0)
		_sprite.modulate = Color(1.0 + p, 0.6, 0.6)
		# A animação de cuspir começa um pouco antes do tiro, para o jato sair junto com o disparo.
		if fire_cd < 0.3 and not _anim_started:
			_anim_started = true
			if not (_sprite as FallSprite).loop:
				(_sprite as FallSprite).play_once()


func overlaps(r: Rect2) -> bool:
	return Rect2(position - box * 0.45, box * 0.9).intersects(r)


func hit_rect() -> Rect2:
	return Rect2(position - box * 0.45, box * 0.9)


## Retorna true se foi destruído.
func take_hit(source: String, amount: int, hit_id: int) -> bool:
	if not alive:
		return false
	if source == "sword":
		if not cfg["sword"] or hit_id == _last_slash:
			return false
		_last_slash = hit_id
	elif source == "jet":
		if not cfg["jet"] or hit_id == _last_jet:
			return false
		_last_jet = hit_id
	hp -= amount
	_flash = 0.12
	if hp <= 0:
		_remove()
		return true
	position.y += float(cfg.get("knock", 0))
	return false


func jet_damage() -> int:
	return int(cfg.get("jet_dmg", 99))


func absorb() -> void:
	_remove()


func _remove() -> void:
	alive = false
	queue_free()
