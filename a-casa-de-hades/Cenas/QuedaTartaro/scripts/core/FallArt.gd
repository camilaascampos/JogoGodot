class_name FallArt
## Catálogo de arte da sequência de queda.
##
## Cada elemento tem um ID (ver art/LEIA-ME.md). Para usar a arte definitiva basta salvar
## um PNG em res://Cenas/QuedaTartaro/arte/ — ele substitui automaticamente o provisório,
## sem mexer em nenhum script. Hitboxes não dependem do tamanho da imagem.
##
## Nomes aceitos (o ID é a parte inicial):
##   party.png                  imagem estática
##   party_4x2.png              grade animada: 4 colunas x 2 linhas (lida da esquerda p/ direita, de cima p/ baixo)
##   party_4x2_12fps.png        idem, a 12 quadros por segundo (padrão: 8)
##   party_6x1.png              faixa horizontal de 6 quadros
##   party/  (pasta)            um PNG por quadro (party/1.png, party/2.png...); "party_12fps/" muda a velocidade
##   party/  (pasta de direções) 8 PNGs com os nomes south, south-east, east, north-east, north, north-west,
##                              west, south-west (saída de "rotações" do PixelLab). Não é animação: o jogo escolhe
##                              a vista pedindo o id "party@south-east". Sem "@", usa "south".

const ART_DIR := "res://Cenas/QuedaTartaro/arte/"
const DEFAULT_FPS := 8.0
## true = pixel art (sem suavização). Mude para false se sua arte não for pixel art.
const PIXEL_ART := true

static var _info_cache: Dictionary = {}
static var _files: Dictionary = {}
static var _folders: Dictionary = {}
static var _dirs: Dictionary = {}

## false = pastas com nomes de direção (south.png, east.png...) tocam como animação, uma imagem após a outra
## (comportamento original). true = tratadas como 8 vistas fixas escolhidas por "party@south-east".
const TREAT_DIRECTIONS_AS_VIEWS := false
const DIRECTIONS := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
static var _scanned := false


## Dados da arte: { "texture", "cols", "rows", "fps" }. Usa o arquivo se existir, senão o provisório.
static func info(id: String) -> Dictionary:
	if _info_cache.has(id):
		return _info_cache[id]
	_scan()
	var base := id.get_slice("@", 0)
	var dir := id.get_slice("@", 1) if id.contains("@") else "south"
	var out := { "texture": null, "cols": 1, "rows": 1, "fps": DEFAULT_FPS }
	if _files.has(base):
		var f: Dictionary = _files[base]
		var tex := load(f["path"]) as Texture2D
		if tex != null:
			out = { "texture": tex, "cols": f["cols"], "rows": f["rows"], "fps": f["fps"] }
	elif _dirs.has(base):
		var views: Dictionary = _dirs[base]
		var path: String = views.get(dir, views.get("south", views.values()[0]))
		out["texture"] = load(path) as Texture2D
	elif _folders.has(base):
		out = _build_from_folder(_folders[base])
	if out["texture"] == null:
		out["texture"] = ImageTexture.create_from_image(_placeholder(base))
	_info_cache[id] = out
	return out


## Existe um arquivo de arte real (não provisório) para este ID?
static func has_art(id: String) -> bool:
	_scan()
	var base := id.get_slice("@", 0)
	return _files.has(base) or _folders.has(base) or _dirs.has(base)


## Textura de uma imagem só. Se o arquivo for uma grade, devolve o primeiro quadro.
static func texture(id: String) -> Texture2D:
	var d := info(id)
	var tex: Texture2D = d["texture"]
	var cols: int = d["cols"]
	var rows: int = d["rows"]
	if cols * rows <= 1:
		return tex
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(0, 0, tex.get_width() / cols, tex.get_height() / rows)
	return at


## Junta os PNGs de uma pasta (um por quadro) numa faixa horizontal.
static func _build_from_folder(f: Dictionary) -> Dictionary:
	var images: Array[Image] = []
	for path: String in f["paths"]:
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		images.append(img)
	var out := { "texture": null, "cols": 1, "rows": 1, "fps": f["fps"] }
	if images.is_empty():
		return out
	var w := images[0].get_width()
	var h := images[0].get_height()
	var strip := Image.create(w * images.size(), h, false, Image.FORMAT_RGBA8)
	for i in images.size():
		strip.blit_rect(images[i], Rect2i(0, 0, mini(w, images[i].get_width()), mini(h, images[i].get_height())), Vector2i(i * w, 0))
	out["texture"] = ImageTexture.create_from_image(strip)
	out["cols"] = images.size()
	return out


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	var rx := RegEx.new()
	rx.compile("^(.+?)(?:_(\\d+)x(\\d+))?(?:_(\\d+)fps)?\\.png$")
	for raw in DirAccess.get_files_at(ART_DIR):
		# Em jogo exportado os arquivos aparecem como "x.png.import" / "x.png.remap".
		var name := raw.trim_suffix(".import").trim_suffix(".remap")
		var m := rx.search(name)
		if m == null:
			continue
		_files[m.get_string(1)] = {
			"path": ART_DIR + name,
			"cols": maxi(1, int(m.get_string(2))) if m.get_string(2) != "" else 1,
			"rows": maxi(1, int(m.get_string(3))) if m.get_string(3) != "" else 1,
			"fps": float(m.get_string(4)) if m.get_string(4) != "" else DEFAULT_FPS,
		}
	# Pastas: art/<id>/ ou art/<id>_12fps/ com um PNG por quadro (ordem alfabética/numérica).
	var frx := RegEx.new()
	frx.compile("^(.+?)(?:_(\\d+)fps)?$")
	for dir_name in DirAccess.get_directories_at(ART_DIR):
		var fm := frx.search(dir_name)
		if fm == null:
			continue
		var names: Array[String] = []
		for raw in DirAccess.get_files_at(ART_DIR + dir_name):
			var fname := raw.trim_suffix(".import").trim_suffix(".remap")
			if fname.ends_with(".png") and not names.has(fname):
				names.append(fname)
		if names.is_empty():
			continue
		var is_directional := true
		for n in names:
			if not DIRECTIONS.has(n.get_basename()):
				is_directional = false
		if is_directional and TREAT_DIRECTIONS_AS_VIEWS:
			var views := {}
			for n in names:
				views[n.get_basename()] = ART_DIR + dir_name + "/" + n
			_dirs[fm.get_string(1)] = views
			continue
		names.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
		var paths: Array[String] = []
		for n in names:
			paths.append(ART_DIR + dir_name + "/" + n)
		_folders[fm.get_string(1)] = {
			"paths": paths,
			"fps": float(fm.get_string(2)) if fm.get_string(2) != "" else DEFAULT_FPS,
		}


# ---------------------------------------------------------------- primitivas

static func _new(w: int, h: int, c: Color = Color(0, 0, 0, 0)) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return img


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var x0 := maxi(0, int(cx - rx))
	var x1 := mini(img.get_width() - 1, int(cx + rx))
	var y0 := maxi(0, int(cy - ry))
	var y1 := mini(img.get_height() - 1, int(cy + ry))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := (float(x) - cx) / rx
			var dy := (float(y) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c)


# ---------------------------------------------------------------- provisórios

static func _placeholder(id: String) -> Image:
	if id.begins_with("shaft_"):
		return _shaft(id)
	if id.begins_with("portrait_"):
		return _portrait(id)
	match id:
		"party":
			return _party()
		"rock_small":
			return _rock(56, 56)
		"rock_large":
			return _rock(120, 110)
		"creature_small":
			return _creature(64, 56, Color(0.45, 0.2, 0.55), Color(1.0, 0.2, 0.2), 0.0)
		"creature_mid":
			return _creature(96, 88, Color(0.6, 0.15, 0.15), Color(1.0, 0.85, 0.2), 0.4)
		"creature_brute":
			return _creature(150, 130, Color(0.35, 0.08, 0.12), Color(1.0, 0.5, 0.1), 0.6)
		"creature_giant":
			return _giant()
		"spitter":
			return _spitter()
		"poison":
			var img := _new(100, 60)
			_ellipse(img, 50, 30, 48, 28, Color(0.35, 0.85, 0.2, 0.75))
			_ellipse(img, 44, 24, 18, 10, Color(0.7, 1.0, 0.4, 0.8))
			return img
		"barrier":
			return _barrier()
		"river":
			return _river()
	var fallback := _new(32, 32, Color(1, 0, 1))
	return fallback


static func _party() -> Image:
	var img := _new(72, 88)
	# Annabeth (atrás, à direita)
	_rect(img, 40, 42, 24, 40, Color(0.9, 0.5, 0.15))
	_ellipse(img, 52, 28, 11, 11, Color(0.95, 0.8, 0.6))
	_ellipse(img, 52, 22, 12, 9, Color(0.95, 0.8, 0.3))
	# Percy (à frente, à esquerda)
	_rect(img, 10, 38, 28, 44, Color(0.2, 0.35, 0.8))
	_ellipse(img, 24, 25, 12, 12, Color(0.95, 0.8, 0.65))
	_ellipse(img, 24, 17, 13, 9, Color(0.08, 0.08, 0.1))
	# braço de Percy envolvendo Annabeth
	_rect(img, 30, 48, 22, 7, Color(0.95, 0.8, 0.65))
	# espada (braço livre)
	_rect(img, 4, 44, 4, 38, Color(0.75, 0.9, 1.0))
	_rect(img, 2, 62, 8, 3, Color(0.8, 0.7, 0.2))
	return img


static func _rock(w: int, h: int) -> Image:
	var img := _new(w, h)
	_ellipse(img, w * 0.5, h * 0.55, w * 0.48, h * 0.42, Color(0.28, 0.2, 0.2))
	_ellipse(img, w * 0.42, h * 0.45, w * 0.3, h * 0.28, Color(0.4, 0.3, 0.28))
	_ellipse(img, w * 0.62, h * 0.7, w * 0.2, h * 0.14, Color(0.18, 0.12, 0.13))
	_rect(img, int(w * 0.46), 0, int(maxf(4.0, w * 0.06)), int(h * 0.25), Color(0.28, 0.2, 0.2))
	return img


static func _creature(w: int, h: int, body: Color, eye: Color, horns: float) -> Image:
	var img := _new(w, h)
	var cx := w * 0.5
	_rect(img, 0, int(h * 0.25), int(w * 0.22), int(h * 0.12), body.darkened(0.3))
	_rect(img, int(w * 0.78), int(h * 0.25), int(w * 0.22), int(h * 0.12), body.darkened(0.3))
	_ellipse(img, cx, h * 0.55, w * 0.36, h * 0.38, body)
	_ellipse(img, cx - w * 0.14, h * 0.45, w * 0.07, h * 0.07, eye)
	_ellipse(img, cx + w * 0.14, h * 0.45, w * 0.07, h * 0.07, eye)
	_ellipse(img, cx, h * 0.72, w * 0.18, h * 0.1, Color(0.08, 0.02, 0.04))
	if horns > 0.0:
		_rect(img, int(w * 0.2), 0, int(w * 0.07), int(h * horns * 0.5), Color(0.85, 0.8, 0.7))
		_rect(img, int(w * 0.73), 0, int(w * 0.07), int(h * horns * 0.5), Color(0.85, 0.8, 0.7))
	return img


static func _giant() -> Image:
	var img := _new(360, 240)
	_ellipse(img, 180, 130, 170, 105, Color(0.28, 0.07, 0.14))
	_ellipse(img, 180, 100, 120, 70, Color(0.4, 0.1, 0.18))
	for i in 7:
		var ex := 70.0 + i * 36.0
		var ey := 85.0 + 18.0 * sin(i * 1.7)
		_ellipse(img, ex, ey, 11, 11, Color(1.0, 0.85, 0.2))
		_ellipse(img, ex, ey, 4, 6, Color(0.1, 0.0, 0.0))
	_ellipse(img, 180, 175, 90, 28, Color(0.07, 0.01, 0.03))
	for i in 9:
		_rect(img, 100 + i * 20, 160, 8, 18, Color(0.9, 0.85, 0.75))
	return img


static func _spitter() -> Image:
	var img := _new(90, 64)
	_ellipse(img, 45, 34, 44, 28, Color(0.22, 0.14, 0.14))
	_ellipse(img, 45, 34, 32, 20, Color(0.04, 0.03, 0.04))
	_ellipse(img, 45, 38, 16, 9, Color(0.35, 0.9, 0.2, 0.8))
	return img


static func _barrier() -> Image:
	var img := _new(1152, 64)
	_rect(img, 0, 10, 1152, 44, Color(0.2, 0.14, 0.13))
	var x := 0
	var i := 0
	while x < 1152:
		var w := 70 + (i * 37) % 60
		_rect(img, x + 2, 4 + (i * 13) % 12, w - 4, 52, Color(0.3 + 0.05 * (i % 3), 0.2, 0.18))
		_rect(img, x + 2, 50 + (i * 7) % 8, w - 4, 6, Color(0.12, 0.07, 0.08))
		x += w
		i += 1
	return img


static func _river() -> Image:
	var img := _new(1152, 320)
	for y in 320:
		var t := float(y) / 320.0
		_rect(img, 0, y, 1152, 1, Color(0.1, 0.55, 0.85).lerp(Color(0.02, 0.12, 0.35), t))
	for i in 18:
		var ry := 6 + (i * 17) % 90
		var rx := (i * 211) % 1100
		_rect(img, rx, ry, 70, 3, Color(0.7, 0.95, 1.0, 0.7))
	_rect(img, 0, 0, 1152, 4, Color(0.8, 1.0, 1.0))
	return img


static func _portrait(id: String) -> Image:
	# id: portrait_<annabeth|percy>_<neutral|alert|worried|smirk>
	var parts := id.split("_")
	var who := parts[1] if parts.size() > 1 else "annabeth"
	var mood := parts[2] if parts.size() > 2 else "neutral"
	var img := _new(56, 56, Color(0.12, 0.08, 0.1))
	var hair := Color(0.95, 0.8, 0.3) if who == "annabeth" else Color(0.08, 0.08, 0.1)
	var eyes := Color(0.6, 0.65, 0.7) if who == "annabeth" else Color(0.1, 0.6, 0.5)
	_ellipse(img, 28, 30, 18, 20, Color(0.95, 0.8, 0.65))
	_ellipse(img, 28, 18, 20, 13, hair)
	if who == "annabeth":
		_ellipse(img, 44, 26, 5, 15, hair)
	_rect(img, 18, 28, 7, 5, eyes)
	_rect(img, 31, 28, 7, 5, eyes)
	match mood:
		"alert":
			_ellipse(img, 28, 42, 4, 5, Color(0.5, 0.15, 0.15))
			_rect(img, 16, 23, 10, 2, hair)
			_rect(img, 30, 23, 10, 2, hair)
		"worried":
			_rect(img, 23, 42, 10, 2, Color(0.5, 0.15, 0.15))
			_rect(img, 16, 25, 9, 2, hair)
			_rect(img, 31, 23, 9, 2, hair)
		"smirk":
			_rect(img, 27, 41, 10, 2, Color(0.5, 0.15, 0.15))
			_rect(img, 35, 39, 3, 2, Color(0.5, 0.15, 0.15))
		_:
			_rect(img, 23, 41, 10, 2, Color(0.5, 0.15, 0.15))
	return img


# ---------------------------------------------------------------- cenário (periódico em y)
# Todas as variantes valem o mesmo na borda superior/inferior (só senos com fase 0 e
# elementos que não cruzam a borda), então qualquer variante emenda com qualquer outra.

static func _shaft(id: String) -> Image:
	var parts := id.split("_")
	var layer := parts[1]
	var v := int(parts[2])
	match layer:
		"far":
			return _shaft_far(v)
		"mid":
			return _shaft_mid(v)
	return _shaft_near(v)


static func _shaft_far(v: int) -> Image:
	var s := 144
	var img := _new(s, s)
	for y in s:
		var t := float(y) / float(s)
		var glow := 0.5 + 0.5 * sin(TAU * float(1 + v) * t)
		var c := Color(0.07, 0.03, 0.11).lerp(Color(0.32, 0.09, 0.1), glow * 0.55)
		_rect(img, 0, y, s, 1, c)
	for i in 7:
		var x := (i * 23 + v * 11) % (s - 10)
		_rect(img, x, 0, 6 + (i % 3) * 3, s, Color(0.03, 0.01, 0.05, 0.55))
	return img


static func _shaft_mid(v: int) -> Image:
	var s := 288
	var img := _new(s, s)
	for y in s:
		var t := float(y) / float(s)
		var wl := 28.0 + 8.0 * sin(TAU * float(2 + v) * t) + 5.0 * sin(TAU * float(5 + 2 * v) * t)
		var wr := 28.0 + 8.0 * sin(TAU * float(3 + v) * t) + 5.0 * sin(TAU * float(6 + v) * t)
		var shade := 0.5 + 0.5 * sin(TAU * 9.0 * t)
		var rock := Color(0.12, 0.06, 0.07).lerp(Color(0.2, 0.1, 0.1), shade)
		_rect(img, 0, y, int(wl), 1, rock)
		_rect(img, int(wl) - 2, y, 2, 1, Color(0.75, 0.28, 0.1, 0.8))
		_rect(img, s - int(wr), y, int(wr), 1, rock)
		_rect(img, s - int(wr), y, 2, 1, Color(0.75, 0.28, 0.1, 0.8))
	for i in 10:
		var gy := 12 + (i * 53 + v * 17) % (s - 24)
		_rect(img, 6 + (i * 7) % 18, gy, 3, 2, Color(1.0, 0.45, 0.1))
		_rect(img, s - 10 - (i * 5) % 18, (gy + 100) % (s - 24) + 12, 3, 2, Color(1.0, 0.45, 0.1))
	return img


static func _shaft_near(v: int) -> Image:
	var s := 288
	var img := _new(s, s)
	var xs := [18, 70, 214, 262] if v == 0 else [30, 100, 190, 250]
	for k in xs.size():
		var base_x: int = xs[k]
		for y in s:
			var t := float(y) / float(s)
			var x := base_x + int(3.0 * sin(TAU * 2.0 * t + float(k) * 0.0))
			if (y / 5) % 2 == 0:
				_rect(img, x, y, 3, 1, Color(0.06, 0.03, 0.04, 0.85))
			else:
				_rect(img, x - 1, y, 5, 1, Color(0.1, 0.05, 0.06, 0.85))
		var by := 40 + (k * 61 + v * 29) % 180
		_ellipse(img, float(base_x) + 1.0, float(by), 8.0, 8.0, Color(0.12, 0.05, 0.07, 0.9))
		_ellipse(img, float(base_x) - 2.0, float(by) - 3.0, 3.0, 3.0, Color(0.5, 0.2, 0.2, 0.8))
	return img
