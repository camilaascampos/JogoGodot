extends Sprite2D
class_name FallSprite
## Sprite que entende arte estática OU animada (grade/faixa), vinda do FallArt.
##   setup("party", Vector2(0, 96))  -> altura 96, largura proporcional
##   setup("barrier", Vector2(1152, 64)) -> estica para o tamanho dado
## O tamanho final é sempre o `target`, não importa o tamanho do PNG.

var fps := FallArt.DEFAULT_FPS
## true = repete sem parar; false = só toca quando chamarem play_once() (fica no quadro 0).
var loop := true

var _id := ""
var _target := Vector2.ZERO
var _t := 0.0
var _frames := 1


func setup(art_id: String, target: Vector2 = Vector2.ZERO) -> void:
	_target = target
	_id = ""
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if FallArt.PIXEL_ART else CanvasItem.TEXTURE_FILTER_LINEAR
	set_art(art_id)


## Troca a arte (ex.: do estado parado para o de ataque). Reinicia a animação.
func set_art(art_id: String) -> void:
	if art_id == _id:
		return
	_id = art_id
	var d := FallArt.info(art_id)
	texture = d["texture"]
	hframes = int(d["cols"])
	vframes = int(d["rows"])
	fps = float(d["fps"])
	_frames = hframes * vframes
	frame = 0
	_t = 0.0
	_apply_scale()
	set_process(_frames > 1 and loop)


## Ajusta velocidade e se repete. Use logo depois de setup().
func configure(new_fps: float, looping: bool) -> void:
	fps = new_fps
	loop = looping
	frame = 0
	_t = 0.0
	set_process(_frames > 1 and loop)


## Toca a animação uma vez, do quadro 0 ao último, e volta ao quadro 0.
func play_once() -> void:
	if _frames <= 1:
		return
	_t = 0.0
	set_process(true)


## Começa em um ponto aleatório da animação (evita criaturas idênticas em sincronia).
func randomize_phase() -> void:
	_t = randf() * 10.0


func _apply_scale() -> void:
	var fs := texture.get_size() / Vector2(hframes, vframes)
	if _target.x > 0.0 and _target.y > 0.0:
		scale = _target / fs
	elif _target.y > 0.0:
		scale = Vector2.ONE * (_target.y / fs.y)
	elif _target.x > 0.0:
		scale = Vector2.ONE * (_target.x / fs.x)
	else:
		scale = Vector2.ONE


func _process(delta: float) -> void:
	_t += delta
	var f := int(_t * fps)
	if loop:
		frame = f % _frames
	elif f >= _frames:
		frame = 0
		set_process(false)
	else:
		frame = f
