extends Node2D
## Cena de plataforma "entre bosses": o grupo anda, coleta itens (potes de cura,
## Bênção de Atena, Boné dos Yankees) e, ao chegar no portão, abre a batalha em turnos.
## O que for coletado fica no JRPGInventory e aparece na batalha.
##
## Para adaptar a outro chefe: duplique a cena, mexa nos nós de "Level" e troque
## NextBattleScenePath / AfterVictoryScenePath no Inspetor do nó raiz.

const SCREEN := Vector2(1152, 648)

@export_file("*.tscn") var NextBattleScenePath: String = "res://Cenas/Batalha/Battle3v2.tscn"
## Cena que abre depois de VENCER a batalha (próxima fase). Vazio = só reinicia a batalha (teste).
@export_file("*.tscn") var AfterVictoryScenePath: String = ""
@export var Background: Texture2D
@export var LevelLength: float = 4400.0
@export var AreaTitle: String = "TÁRTARO"
@export var BossText: String = "Os chefes se aproximam..."
## Zera o inventário ao entrar. Desligue se uma fase anterior já deu itens ao jogador.
@export var ResetInventoryOnStart: bool = true

var leader: JRPGPlatformHero
var follower: JRPGPlatformHero
var _cam: Camera2D
var _fade: ColorRect
var _banner: Label
var _hud_labels: Dictionary = {}
var _transitioning := false


## _enter_tree roda antes do _ready dos itens: o Boné já pego não pode reaparecer com inventário velho.
func _enter_tree() -> void:
	if ResetInventoryOnStart:
		JRPGInventory.clear()
	JRPGInventory.managed_by_story = true
	JRPGInventory.after_victory_scene = AfterVictoryScenePath


func _ready() -> void:
	_build_background()
	_spawn_party()
	_build_camera()
	_build_hud()

	var gate := get_node_or_null("Level/BossGate") as JRPGBossGate
	if gate != null:
		gate.entered.connect(_on_gate_entered)
	else:
		push_warning("Sem nó Level/BossGate: a batalha nunca será aberta.")

	_show_banner(AreaTitle, 2.5)


func _physics_process(delta: float) -> void:
	if leader == null:
		return
	var half := SCREEN.x * 0.5
	var target := clampf(leader.global_position.x, half, maxf(LevelLength - half, half))
	_cam.global_position.x = lerpf(_cam.global_position.x, target, clampf(8.0 * delta, 0.0, 1.0))
	_update_hud()


# ---------------------------------------------------------------- montagem

func _build_background() -> void:
	var tex := Background
	if tex == null:
		return
	var bg := Node2D.new()
	bg.z_index = -10
	add_child(bg)
	var s := SCREEN.x / float(tex.get_width())
	var tile_w := tex.get_width() * s
	var tiles := int(ceil(LevelLength / tile_w)) + 1
	for i in tiles:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		sprite.scale = Vector2(s, s)
		sprite.position = Vector2(i * tile_w, 0)
		# Ladrilhos alternados espelhados: a emenda fica sem corte.
		if i % 2 == 1:
			sprite.flip_h = true
		bg.add_child(sprite)


func _spawn_party() -> void:
	var start := get_node_or_null("Level/Start") as Marker2D
	var pos := start.global_position if start != null else Vector2(160, 448)

	follower = JRPGPlatformHero.new()
	follower.display_name = "Annabeth"
	follower.tint = Color(1.12, 1.0, 0.8)
	follower.leader = null # definido abaixo
	follower.position = pos + Vector2(-70, 0)

	leader = JRPGPlatformHero.new()
	leader.display_name = "Percy"
	leader.tint = Color(0.82, 0.92, 1.15)
	leader.position = pos
	leader.max_x = LevelLength - 40.0

	follower.leader = leader
	add_child(follower) # atrás
	add_child(leader)


func _build_camera() -> void:
	_cam = Camera2D.new()
	_cam.position = Vector2(SCREEN.x * 0.5, SCREEN.y * 0.5)
	add_child(_cam)
	_cam.make_current()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.add_theme_stylebox_override("panel", JRPGHudTheme.panel_style(JRPGHudTheme.COL_BRONZE, JRPGHudTheme.COL_BG, 3))
	layer.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	col.add_child(JRPGHudTheme.make_label("MOCHILA", 13, JRPGHudTheme.COL_GOLD))
	for id in [JRPGInventory.HEALING_POT, JRPGInventory.ATHENA_BLESSING, JRPGInventory.YANKEES_CAP]:
		var label := JRPGHudTheme.make_label("", 15)
		col.add_child(label)
		_hud_labels[id] = label

	var hint := JRPGHudTheme.make_label("← → / A D  andar      ESPAÇO  pular", 13, JRPGHudTheme.COL_TEXT_DIM)
	hint.position = Vector2(12, SCREEN.y - 30)
	layer.add_child(hint)

	_banner = JRPGHudTheme.make_label("", 44)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position = Vector2(0, 90)
	_banner.size = Vector2(SCREEN.x, 70)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	layer.add_child(_banner)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.size = SCREEN
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.6)


func _update_hud() -> void:
	_set_hud(JRPGInventory.HEALING_POT, "POTE DE CURA  x%d" % JRPGInventory.count(JRPGInventory.HEALING_POT), JRPGInventory.has(JRPGInventory.HEALING_POT))
	_set_hud(JRPGInventory.ATHENA_BLESSING, "BÊNÇÃO DE ATENA  x%d" % JRPGInventory.count(JRPGInventory.ATHENA_BLESSING), JRPGInventory.has(JRPGInventory.ATHENA_BLESSING))
	_set_hud(JRPGInventory.YANKEES_CAP, "BONÉ DOS YANKEES" + ("  ✔" if JRPGInventory.has(JRPGInventory.YANKEES_CAP) else ""), JRPGInventory.has(JRPGInventory.YANKEES_CAP))


func _set_hud(id: String, text: String, owned: bool) -> void:
	var label := _hud_labels[id] as Label
	label.text = text
	label.modulate = Color.WHITE if owned else Color(1, 1, 1, 0.4)


func _show_banner(text: String, seconds: float) -> void:
	_banner.text = text
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.4)
	tween.tween_interval(seconds)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


# ---------------------------------------------------------------- portão do chefe

func _on_gate_entered() -> void:
	if _transitioning:
		return
	_transitioning = true
	leader.controls_enabled = false
	_show_banner(BossText, 1.2)

	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(_fade, "color:a", 1.0, 0.8)
	await tween.finished

	if NextBattleScenePath == "" or not ResourceLoader.exists(NextBattleScenePath):
		push_error("NextBattleScenePath inválido: " + NextBattleScenePath)
		return
	get_tree().change_scene_to_file(NextBattleScenePath)
