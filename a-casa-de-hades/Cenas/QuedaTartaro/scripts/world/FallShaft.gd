extends Node2D
class_name FallShaft
## Poço vertical em camadas de parallax feito de segmentos que se reciclam.
## Camadas, velocidades e variantes ficam em data/FallBackground.gd; as imagens em art/.

const SEG_H := 1152.0
const PLACEHOLDER_VARIANTS := 2

var _layers: Array[Dictionary] = []


func _ready() -> void:
	for cfg: Dictionary in FallBackground.LAYERS:
		if not cfg.get("enabled", true):
			continue
		var layer_name: String = cfg["name"]
		var ids := _variant_ids(layer_name, int(cfg["max_variants"]))
		var holder := Node2D.new()
		holder.z_index = int(cfg["z"])
		holder.modulate.a = float(cfg.get("alpha", 1.0))
		add_child(holder)
		var sprites: Array[FallSprite] = []
		for i in 3:
			var s := FallSprite.new()
			s.centered = false
			s.setup(ids[randi() % ids.size()], Vector2(1152.0, SEG_H))
			s.position = Vector2(0, float(i) * SEG_H)
			holder.add_child(s)
			sprites.append(s)
		_layers.append({ "factor": float(cfg["factor"]), "ids": ids, "sprites": sprites })


## IDs reais encontrados em art/ (shaft_<camada>_0, _1...). Sem nenhum, usa o provisório.
func _variant_ids(layer_name: String, max_variants: int) -> Array[String]:
	var real: Array[String] = []
	for v in max_variants:
		var id := "shaft_%s_%d" % [layer_name, v]
		if FallArt.has_art(id):
			real.append(id)
	if not real.is_empty():
		return real
	var fallback: Array[String] = []
	for v in PLACEHOLDER_VARIANTS:
		fallback.append("shaft_%s_%d" % [layer_name, v])
	return fallback


## Rola o cenário. px = distância de queda neste quadro.
func scroll(px: float) -> void:
	for layer in _layers:
		var factor: float = layer["factor"]
		if factor == 0.0:
			continue
		var sprites: Array = layer["sprites"]
		var ids: Array = layer["ids"]
		for s: FallSprite in sprites:
			s.position.y -= px * factor
		for s: FallSprite in sprites:
			if s.position.y <= -SEG_H:
				s.position.y += SEG_H * float(sprites.size())
				s.set_art(ids[randi() % ids.size()])
