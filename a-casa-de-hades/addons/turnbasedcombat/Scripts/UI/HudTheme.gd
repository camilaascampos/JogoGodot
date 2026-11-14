class_name JRPGHudTheme
## Cores, fontes e "fábricas" de widgets usados pela HUD de batalha.
## Para mudar o visual do jogo inteiro, mexa só aqui.

const COL_BG := Color(0.09, 0.04, 0.04, 0.93)
const COL_BG_ROW := Color(0.15, 0.07, 0.06, 1.0)
const COL_BG_ROW_ACTIVE := Color(0.42, 0.10, 0.08, 1.0)
const COL_TEXT := Color(0.96, 0.90, 0.80, 1.0)
const COL_TEXT_DIM := Color(0.55, 0.46, 0.42, 1.0)
const COL_GOLD := Color(0.88, 0.64, 0.26, 1.0)
const COL_BRONZE := Color(0.55, 0.36, 0.18, 1.0)
const COL_ENEMY := Color(0.65, 0.15, 0.12, 1.0)
const COL_PLAYER_DEFAULT := Color(0.88, 0.64, 0.26, 1.0)
const COL_HP := Color(0.82, 0.12, 0.10, 1.0)
const COL_EN := Color(0.22, 0.46, 0.95, 1.0)
const COL_ULT := Color(0.25, 0.62, 0.88, 1.0)
const COL_BAR_BG := Color(0.04, 0.02, 0.02, 1.0)

const FONT_PATH := "res://Assets/Fontes/Pixelify_Sans,Silkscreen/Pixelify_Sans/static/PixelifySans-Bold.ttf"

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH) as Font
	return _font


## Caixa com borda (estilo painel do mockup).
static func panel_style(border: Color, bg: Color = COL_BG, border_width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(6)
	return sb


static func make_label(text: String, size: int = 14, color: Color = COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 3)
	var f := font()
	if f != null:
		l.add_theme_font_override("font", f)
	return l


## Barra de HP/EN. Se with_text = true, o texto "atual/max" fica por cima da barra
## (acessível por bar.get_node("Value")).
static func make_bar(fill: Color, height: int = 16, with_text: bool = true) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = Vector2(0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.step = 0.01

	var bg := panel_style(Color(0.35, 0.2, 0.15, 1.0), COL_BAR_BG, 1)
	bg.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", bg)

	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(0)
	fg.set_content_margin_all(0)
	bar.add_theme_stylebox_override("fill", fg)

	if with_text:
		var value := make_label("", maxi(height - 6, 9))
		value.name = "Value"
		value.set_anchors_preset(Control.PRESET_FULL_RECT)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.add_theme_constant_override("outline_size", 2)
		bar.add_child(value)
	return bar


## Retrato do personagem. Usa species.Portrait se existir; senão recorta o
## busto do sprite de batalha (frame 0 da spritesheet).
static func portrait_for(battle_char: JRPGBaseBattleChar) -> Texture2D:
	var species: JRPGSpecies = battle_char.Char.species
	if species.Portrait != null:
		return species.Portrait

	var tex := battle_char.get("texture") as Texture2D
	if tex == null:
		return null
	var frames: int = 1
	var hf = battle_char.get("hframes")
	if hf != null:
		frames = maxi(int(hf), 1)
	var fw := float(tex.get_width()) / float(frames)
	var fh := float(tex.get_height())
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	# Busto (cabeça e tronco) do frame 0. Ajuste aqui se trocar o sprite.
	atlas.region = Rect2(fw * 0.19, fh * 0.15, fw * 0.5, fh * 0.5)
	return atlas


static func make_portrait(tex: Texture2D, size: int, border: Color) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(size, size)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := panel_style(border, Color(0.05, 0.02, 0.02, 1.0), 2)
	sb.set_content_margin_all(2)
	frame.add_theme_stylebox_override("panel", sb)
	var rect := TextureRect.new()
	rect.name = "Image"
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(rect)
	return frame
