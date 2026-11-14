extends Node2D
## Diretor da sequência "Queda no Tártaro".
## Monta o mundo, lê o roteiro (FallTimeline), cuida de colisões, falha/checkpoint e do final.
## Roda sozinho (F6 em queda_tartaro.tscn) ou integrado (veja FallState.gd).

signal sequence_finished(result: Dictionary)

enum State { PLAY, FAILING, FINALE, DONE }

const PARTY_Y := 250.0
const SPAWN_Y := 740.0
const POISON_SPEED := 700.0
const GRACE := 2.0  # após um checkpoint, perigos que chegariam em menos que isso não são recriados

## Cena aberta ao terminar. Vazio = FallState.next_scene.
@export_file("*.tscn") var NextScenePath := ""
## Fase inicial (0..7). Também pode vir de FallState.set_entry({"start_phase": n}).
@export var StartPhase := 0
## F1..F8 pula para a fase · H mostra caixas de colisão · G invencível.
@export var DebugKeys := false
@export var ShowHitboxes := false

var world_speed := 160.0

var _state := State.PLAY
var _t := 0.0
var _cursor := 0
var _events: Array[Dictionary] = []
var _phases: Array[Dictionary] = []
var _phase_idx := -1
var _cp_time := 0.0
var _deaths := 0
var _sword_t := 0.0
var _god := false
var _moved := false

var _world: Node2D
var _hazards: Node2D
var _shaft: FallShaft
var _party: FallParty
var _cam: FallCamera
var _dialogue: FallDialogue
var _prompts: FallPrompt
var _hud: FallHud
var _dbg: Node2D


func _ready() -> void:
	_phases = FallTimeline.phases()
	_build_events()

	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	var back := ColorRect.new()
	back.color = FallBackground.COLOR
	back.position = Vector2(-300, -300)
	back.size = Vector2(1752, 1248)
	back.z_index = -40
	_world.add_child(back)
	_shaft = FallShaft.new()
	_shaft.name = "Shaft"
	_world.add_child(_shaft)
	_hazards = Node2D.new()
	_hazards.name = "Hazards"
	_hazards.z_index = 2
	_world.add_child(_hazards)
	_party = FallParty.new()
	_party.name = "Party"
	_party.position = Vector2(576, PARTY_Y)
	_world.add_child(_party)
	_dbg = Node2D.new()
	_dbg.z_index = 50
	_dbg.draw.connect(_draw_debug)
	_world.add_child(_dbg)

	_cam = FallCamera.new()
	_cam.name = "Camera"
	add_child(_cam)
	_cam.party = _party

	_dialogue = FallDialogue.new()
	add_child(_dialogue)
	_prompts = FallPrompt.new()
	add_child(_prompts)
	_hud = FallHud.new()
	add_child(_hud)

	_party.slashed.connect(_on_slashed)
	_party.shield_changed.connect(func(on: bool) -> void:
		if on:
			_prompts.hide_prompt("shield"))
	_party.jet_fired.connect(_on_jet_fired)

	var entry := FallState.take_entry()
	var phase := clampi(int(entry.get("start_phase", StartPhase)), 0, _phases.size() - 1)
	_restart_at(float(_phases[phase]["start"]))
	_hud.fade_to(0.0, 1.2)


# ------------------------------------------------------------------ roteiro

func _build_events() -> void:
	for src in FallTimeline.events():
		var e: Dictionary = src.duplicate()
		var t: float = e["t"]
		if e["type"] == "spawn":
			var kind: String = e["kind"]
			var mult: float = FallHazard.KINDS[kind]["mult"]
			var y := SPAWN_Y + FallHazard.box_of(kind).y * 0.5
			var travel := (y - PARTY_Y) / (_speed_at(t) * maxf(mult, 0.1))
			e["exec"] = maxf(0.0, t - travel)
		else:
			e["exec"] = t
		_events.append(e)
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["exec"] < b["exec"])


func _speed_at(t: float) -> float:
	var s := float(_phases[0]["speed"])
	for p in _phases:
		if float(p["start"]) <= t:
			s = p["speed"]
	return s


func _phase_at(t: float) -> int:
	var idx := 0
	for i in _phases.size():
		if float(_phases[i]["start"]) <= t:
			idx = i
	return idx


func _handle(e: Dictionary) -> void:
	match e["type"]:
		"spawn":
			_spawn_hazard(e, SPAWN_Y + FallHazard.box_of(e["kind"]).y * 0.5)
		"say":
			_dialogue.say(e["who"], e["text"], e["mood"])
		"prompt":
			_prompts.show_prompt(e["id"], e["keys"], e["label"], e["dur"])
		"unlock":
			_party.unlocked[e["what"]] = true
			FallFx.pop(_world, _party.position, Color(0.4, 0.9, 1.0), 70.0, 0.6)
		"cam":
			_cam.focus(e["zoom"], e["offset"], e["hold"])
		"finale":
			_run_finale()


## Coloca o jogo no instante `time` (início, checkpoint ou salto de debug).
func _restart_at(time: float) -> void:
	for c in _hazards.get_children():
		c.queue_free()
	_dialogue.clear()
	_prompts.clear()
	_cam.reset_focus()
	_party.unlocked = { "sword": false, "shield": false, "jet": false }
	_t = time
	_cp_time = time
	_phase_idx = _phase_at(time)
	world_speed = float(_phases[_phase_idx]["speed"])
	_cursor = 0
	while _cursor < _events.size() and float(_events[_cursor]["exec"]) < time:
		var e := _events[_cursor]
		if e["type"] == "unlock":
			_party.unlocked[e["what"]] = true
		elif e["type"] == "spawn" and float(e["t"]) > time + GRACE:
			var mult: float = FallHazard.KINDS[e["kind"]]["mult"]
			var y := PARTY_Y + (float(e["t"]) - time) * world_speed * maxf(mult, 0.1)
			_spawn_hazard(e, y)
		_cursor += 1
	_party.reset_for_checkpoint(Vector2(576, PARTY_Y))
	_party.invuln = 1.6
	_sword_t = 0.0
	_state = State.PLAY


func _spawn_hazard(e: Dictionary, y: float) -> void:
	var kind: String = e["kind"]
	var h := FallHazard.create(kind)
	var x := lerpf(FallParty.MIN_X, FallParty.MAX_X, float(e["x"]))
	var flip := false
	if e.has("side"):
		var left: bool = e["side"] == "L"
		flip = not left
		if kind == "spitter":
			x = 150.0 if left else 1002.0
		else:
			x = 110.0 if left else 1042.0
	if kind == "barrier":
		x = 576.0
	h.position = Vector2(x, y)
	h.flip = flip and kind == "spitter"
	h.burst = bool(e.get("burst", false))
	if kind == "spitter":
		h.shots_left = int(e.get("shots", 1))
		h.fire_requested.connect(_on_fire)
	_hazards.add_child(h)


func _on_fire(h: FallHazard) -> void:
	var p := FallHazard.create("poison")
	p.position = h.position
	p.vel = (_party.position - h.position).normalized() * POISON_SPEED
	p.rotation = p.vel.angle()
	_hazards.add_child(p)


# ------------------------------------------------------------------ laço principal

func _process(delta: float) -> void:
	_hud.set_energy(_party.energy, _party.unlocked["shield"] or _party.unlocked["jet"])
	if DebugKeys:
		_hud.set_debug("%s  t=%.0f  v=%.0f  mortes=%d%s" % [_phases[maxi(_phase_idx, 0)]["name"], _t, world_speed, _deaths, "  [G]" if _god else ""])
	if ShowHitboxes:
		_dbg.queue_redraw()
	match _state:
		State.PLAY:
			_play(delta)
		State.FINALE:
			_shaft.scroll(world_speed * delta)


func _play(delta: float) -> void:
	_t += delta
	_sword_t = maxf(0.0, _sword_t - delta)

	var idx := _phase_at(_t)
	if idx != _phase_idx:
		_phase_idx = idx
		_cp_time = float(_phases[idx]["start"])
		if idx < _phases.size() - 1:
			_hud.show_checkpoint()
	world_speed = move_toward(world_speed, float(_phases[_phase_idx]["speed"]), 45.0 * delta)
	_shaft.scroll(world_speed * delta)

	if not _moved and absf(_party.position.x - 576.0) > 50.0:
		_moved = true
		_prompts.hide_prompt("move")

	while _state == State.PLAY and _cursor < _events.size() and float(_events[_cursor]["exec"]) <= _t:
		var e := _events[_cursor]
		_cursor += 1
		_handle(e)
	if _state != State.PLAY:
		return

	for c in _hazards.get_children():
		var h := c as FallHazard
		if h == null or not h.alive:
			continue
		h.tick(delta, world_speed, _party)
		if not h.alive:
			continue
		if h.kind == "poison" and _party.shield_on and h.overlaps(_party.shield_rect()):
			h.absorb()
			FallFx.pop(_world, h.position, Color(0.5, 0.95, 1.0), 44.0, 0.3)
			continue
		if _sword_t > 0.0 and h.cfg["sword"] and h.overlaps(_party.slash_rect()):
			if h.take_hit("sword", 1, _party.slash_id):
				FallFx.pop(_world, h.position, Color(1, 1, 1), 50.0, 0.35)
				_cam.shake(0.25)
			else:
				FallFx.pop(_world, h.position, Color(0.8, 0.9, 1.0), 26.0, 0.2)
		if h.alive and _party.jet_active() and h.cfg["jet"] and h.overlaps(_party.jet_rect()):
			if h.take_hit("jet", h.jet_damage(), _party.jet_id):
				FallFx.pop(_world, h.position, Color(0.4, 0.9, 1.0), 70.0, 0.45)
				_cam.shake(0.4)
		if h.alive and h.cfg["lethal"] and _party.invuln <= 0.0 and h.overlaps(_party.hit_rect()):
			_fail()
			return


func _on_slashed(id: int) -> void:
	_sword_t = 0.22
	_prompts.hide_prompt("sword")


func _on_jet_fired(_id: int) -> void:
	_prompts.hide_prompt("jet")
	_cam.shake(0.2)


# ------------------------------------------------------------------ falha e checkpoint

func _fail() -> void:
	if _state != State.PLAY or _god:
		return
	_state = State.FAILING
	_deaths += 1
	_party.controls = false
	FallFx.pop(_world, _party.position, Color(1.0, 0.3, 0.3), 80.0, 0.5)
	_cam.shake(1.0)
	_hud.show_message("ATINGIDOS!", "Voltando ao último checkpoint...")
	await get_tree().create_timer(1.1).timeout
	await _hud.fade_to(1.0, 0.4)
	_hud.hide_message()
	_restart_at(_cp_time)
	await _hud.fade_to(0.0, 0.5)


# ------------------------------------------------------------------ final

func _run_finale() -> void:
	_state = State.FINALE
	_prompts.clear()
	_dialogue.clear()
	for c in _hazards.get_children():
		c.queue_free()
	_party.controls = false
	_cam.focus(1.3, Vector2(0, 110), 20.0)
	_dialogue.say("Annabeth", "Agora, Percy! Toda a água que você tiver, para baixo!", "alert")

	var tw := create_tween()
	tw.tween_property(_party, "position:x", 576.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	_party.column = true
	_cam.shake(0.5)
	var river := FallSprite.new()
	river.setup("river", Vector2(1152, 320))
	river.z_index = 3
	river.position = Vector2(576, 1000)
	_world.add_child(river)
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(river, "position:y", 470.0, 5.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.tween_property(self, "world_speed", 40.0, 5.0)
	await get_tree().create_timer(1.2).timeout
	_dialogue.say("Percy", "Segura firme!", "alert")
	await t2.finished

	_hud.flash()
	_cam.shake(1.0)
	_party.column = false
	for i in 4:
		FallFx.pop(_world, Vector2(576 + (i - 1.5) * 70.0, 320.0), Color(0.6, 0.95, 1.0), 80.0, 0.8)
	var sink := create_tween().set_parallel(true)
	sink.tween_property(_party, "position:y", 390.0, 1.8).set_trans(Tween.TRANS_SINE)
	sink.tween_property(_party, "modulate:a", 0.35, 1.8)
	await sink.finished
	_cam.reset_focus()

	await get_tree().create_timer(0.6).timeout
	_dialogue.say("Annabeth", "Percy... você está bem?", "worried")
	_dialogue.say("Percy", "Estou. A água... ela nos segurou. Aquilo foi coisa sua?", "alert")
	_dialogue.say("Annabeth", "Foi sua. Eu só te dei o motivo.", "smirk")
	_dialogue.say("Percy", "Chegar ao Tártaro de cabeça. Péssima ideia, nota zero.", "smirk")
	_dialogue.say("Annabeth", "E ainda estamos só no começo.", "neutral")
	await _dialogue.wait_idle()
	await _hud.fade_to(1.0, 1.5)
	_finish()


func _finish() -> void:
	_state = State.DONE
	var result := { "completed": true, "deaths": _deaths, "time": _t }
	FallState.finish(result)
	sequence_finished.emit(result)
	var path := NextScenePath if NextScenePath != "" else FallState.next_scene
	if path != "" and ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		_hud.show_message("FIM DA QUEDA", "Nenhuma cena seguinte encontrada (NextScenePath / FallState.next_scene).")


# ------------------------------------------------------------------ debug

func _unhandled_input(event: InputEvent) -> void:
	if not DebugKeys:
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode >= KEY_F1 and k.keycode < KEY_F1 + _phases.size():
		_restart_at(float(_phases[k.keycode - KEY_F1]["start"]))
	elif k.keycode == KEY_H:
		ShowHitboxes = not ShowHitboxes
		_dbg.queue_redraw()
	elif k.keycode == KEY_G:
		_god = not _god


func _draw_debug() -> void:
	if not ShowHitboxes:
		return
	_dbg.draw_rect(_party.hit_rect(), Color(0, 1, 0, 0.5), false, 2.0)
	if _sword_t > 0.0:
		_dbg.draw_rect(_party.slash_rect(), Color(1, 1, 1, 0.4), false, 2.0)
	if _party.shield_on:
		_dbg.draw_rect(_party.shield_rect(), Color(0.3, 0.8, 1, 0.5), false, 2.0)
	for c in _hazards.get_children():
		var h := c as FallHazard
		if h != null and h.alive:
			_dbg.draw_rect(h.hit_rect(), Color(1, 0.2, 0.2, 0.6), false, 2.0)
