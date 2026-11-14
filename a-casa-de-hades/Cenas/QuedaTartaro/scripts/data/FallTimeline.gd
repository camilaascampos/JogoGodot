class_name FallTimeline
## Roteiro da queda em dados: fases, perigos, falas, dicas e câmera.
## Tempos em segundos desde o início da sequência. Em eventos "spawn", `t` é o instante em que
## o perigo CHEGA à altura do grupo (o diretor calcula quando ele precisa aparecer).
## Para balancear, mexa aqui; nenhum outro script precisa mudar.

const FINALE_T := 330.0


static func phases() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in [
		["A queda", 0.0, 220.0],
		["Primeiros perigos", 35.0, 250.0],
		["Contracorrente", 80.0, 260.0],
		["Escudo de água", 135.0, 280.0],
		["Jato de água", 185.0, 300.0],
		["Escalada", 235.0, 330.0],
		["Clímax", 295.0, 360.0],
		["O rio", FINALE_T, 360.0],
	]:
		out.append({ "name": p[0], "start": p[1], "speed": p[2] })
	return out


static func events() -> Array[Dictionary]:
	var ev: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260512

	# ---------------------------------------------------------- 1. Início da queda
	_say(ev, 1.0, "Percy", "Sabe, já caí de lugares piores. Não lembro quais, mas devem existir.", "smirk")
	_say(ev, 4.5, "Annabeth", "Menos piadas, mais atenção. Incline o corpo para o lado e a gente desvia.", "alert")
	_prompt(ev, 5.0, "move", ["← →", "A D"], "DESVIAR", 10.0)
	for t in [9.0, 13.0, 17.0, 21.0]:
		_spawn(ev, t, "rock_small", rng.randf_range(0.15, 0.85))
	_say(ev, 14.0, "Annabeth", "Rochas soltas das paredes. Vão ficar mais frequentes.", "neutral")
	_spawn(ev, 25.0, "rock_large", 0.5)
	_say(ev, 24.0, "Percy", "Está bem aí atrás?", "worried")
	_say(ev, 27.0, "Annabeth", "Estou. Olhe para frente.", "neutral")
	_spawn(ev, 29.0, "rock_small", 0.2)
	_spawn(ev, 29.0, "rock_small", 0.8)
	_spawn(ev, 32.5, "rock_small", 0.5)

	# ---------------------------------------------------------- 2. Primeiros perigos
	_say(ev, 36.0, "Annabeth", "Tem algo se movendo nas paredes. Não encoste nelas.", "alert")
	var t := 38.0
	var i := 0
	var last_lane := 0.5
	while t < 78.0:
		var lane := rng.randf_range(0.1, 0.9)
		while absf(lane - last_lane) < 0.25:
			lane = rng.randf_range(0.1, 0.9)
		last_lane = lane
		_spawn(ev, t, "rock_large" if i % 3 == 2 else "rock_small", lane)
		if i % 4 == 3:
			_spawn(ev, t, "rock_small", fposmod(lane + 0.45, 1.0))
		t += 2.6
		i += 1
	_spawn(ev, 52.0, "creature_small", 0.3)
	_spawn(ev, 64.0, "creature_small", 0.7)
	_spawn(ev, 75.0, "creature_small", 0.5)
	_spawn(ev, 58.0, "creature_small", 0.0, { "burst": true, "side": "L" })
	_spawn(ev, 71.0, "creature_small", 0.0, { "burst": true, "side": "R" })
	_say(ev, 49.0, "Percy", "Que acolhedor. Tem até comitê de boas-vindas.", "smirk")
	_say(ev, 61.0, "Annabeth", "Elas reagem ao movimento. Não fique parado no caminho delas.", "alert")
	_say(ev, 76.0, "Percy", "Annabeth... eu cansei de fugir.", "alert")

	# ---------------------------------------------------------- 3. Combate
	_say(ev, 81.0, "Annabeth", "Contracorrente. Chegue perto da criatura e golpeie quando ela estiver ao alcance.", "alert")
	_unlock(ev, 81.5, "sword")
	_prompt(ev, 82.0, "sword", ["Z"], "ESPADA", 14.0)
	_spawn(ev, 84.0, "creature_small", 0.3)
	_spawn(ev, 88.0, "creature_small", 0.7)
	_say(ev, 95.0, "Percy", "Agora sim, esse é o meu estilo.", "smirk")
	_spawn(ev, 92.0, "rock_small", 0.5)
	_spawn(ev, 97.0, "creature_small", 0.25)
	_spawn(ev, 97.0, "creature_small", 0.75)
	_spawn(ev, 103.0, "creature_mid", 0.5)
	_spawn(ev, 109.0, "creature_mid", 0.3)
	_spawn(ev, 109.0, "creature_small", 0.75)
	_say(ev, 108.0, "Annabeth", "Aquela é maior. Aguenta mais de um golpe. Não recue!", "alert")
	_cam(ev, 112.0, 1.25, Vector2(0, 90), 4.0)
	_spawn(ev, 116.0, "creature_brute", 0.5)
	_spawn(ev, 123.0, "creature_small", 0.2)
	_spawn(ev, 124.0, "creature_small", 0.5)
	_spawn(ev, 125.0, "creature_small", 0.8)
	_spawn(ev, 130.0, "creature_mid", 0.6)
	_say(ev, 128.0, "Percy", "Fácil. Quase.", "smirk")

	# ---------------------------------------------------------- 4. Defesa
	_say(ev, 136.0, "Annabeth", "Percy! Parede da direita, tem uma abertura. Tem alguma coisa ali dentro!", "alert")
	_cam(ev, 137.0, 1.2, Vector2(60, 40), 3.5)
	_say(ev, 138.0, "Annabeth", "Ela vai cuspir veneno! Segure X, o escudo de água!", "alert")
	_unlock(ev, 138.0, "shield")
	_prompt(ev, 138.2, "shield", ["X"], "ESCUDO (SEGURAR)", 14.0)
	_spawn(ev, 141.5, "spitter", 0.0, { "side": "R", "shots": 1 })
	_spawn(ev, 148.0, "spitter", 0.0, { "side": "L", "shots": 2 })
	_say(ev, 152.0, "Percy", "A água serve pra isso também. Anotado.", "smirk")
	_spawn(ev, 154.0, "creature_mid", 0.5)
	_spawn(ev, 159.0, "spitter", 0.0, { "side": "R", "shots": 2 })
	_spawn(ev, 160.0, "rock_small", 0.4)
	_spawn(ev, 165.0, "creature_small", 0.3)
	_spawn(ev, 166.0, "creature_small", 0.7)
	_say(ev, 169.0, "Annabeth", "Observe os dois lados. Eles se revezam.", "neutral")
	_spawn(ev, 170.0, "spitter", 0.0, { "side": "L", "shots": 3 })
	_spawn(ev, 176.0, "creature_brute", 0.5)
	_spawn(ev, 178.0, "spitter", 0.0, { "side": "R", "shots": 1 })
	_spawn(ev, 182.5, "creature_mid", 0.3)
	_spawn(ev, 182.5, "creature_mid", 0.7)

	# ---------------------------------------------------------- 5. Jato de água
	_say(ev, 187.0, "Annabeth", "Bloqueado! É rocha maciça, o escudo não resolve. Use o jato de água, C!", "alert")
	_unlock(ev, 187.5, "jet")
	_prompt(ev, 188.0, "jet", ["C"], "JATO DE ÁGUA", 14.0)
	_spawn(ev, 192.0, "barrier", 0.5)
	_spawn(ev, 197.0, "rock_small", 0.3)
	_spawn(ev, 197.0, "rock_small", 0.7)
	_spawn(ev, 201.0, "barrier", 0.5)
	_say(ev, 204.0, "Percy", "Isso gasta energia. Dá pra sentir.", "worried")
	_say(ev, 206.0, "Annabeth", "A água é um recurso. Não desperdice.", "neutral")
	_spawn(ev, 208.0, "rock_large", 0.5)
	_spawn(ev, 212.0, "creature_mid", 0.5)
	_spawn(ev, 213.0, "spitter", 0.0, { "side": "L", "shots": 1 })
	_say(ev, 214.0, "Annabeth", "Olhe o tamanho disso! Não dá pra desviar. Use o jato mais de uma vez!", "alert")
	_cam(ev, 215.0, 1.2, Vector2(0, 100), 5.0)
	_spawn(ev, 222.0, "creature_giant", 0.5)
	_spawn(ev, 229.0, "barrier", 0.5)
	_spawn(ev, 232.0, "creature_small", 0.4)
	_say(ev, 230.0, "Percy", "Um dia eu ainda quero conhecer a mãe dessa criatura. Só pra reclamar.", "smirk")

	# ---------------------------------------------------------- 6. Escalada
	_say(ev, 236.0, "Annabeth", "Ficou mais rápido. Agora vem tudo junto. Use o que aprendemos.", "alert")
	var patterns := [
		[["creature_mid", 0.3], ["spitter", "R"]],
		[["barrier", 0.5]],
		[["creature_brute", 0.5]],
		[["rock_small", 0.2], ["rock_small", 0.5], ["rock_small", 0.8]],
		[["creature_small", 0.2], ["creature_small", 0.5], ["creature_small", 0.8]],
		[["spitter", "L"], ["creature_mid", 0.7]],
	]
	t = 240.0
	i = 0
	while t < 290.0:
		var pat: Array = patterns[(i + rng.randi_range(0, 2)) % patterns.size()]
		for item in pat:
			if item[0] == "spitter":
				_spawn(ev, t, "spitter", 0.0, { "side": item[1], "shots": 2 })
			else:
				_spawn(ev, t, item[0], item[1])
		t += 4.6
		i += 1
	_say(ev, 262.0, "Percy", "Annabeth, está ficando pior.", "worried")
	_say(ev, 266.0, "Annabeth", "Eu sei. Calma: estratégia primeiro, instinto depois.", "neutral")
	_spawn(ev, 283.0, "creature_giant", 0.5)
	_cam(ev, 279.0, 1.25, Vector2(0, 100), 5.0)
	_say(ev, 280.0, "Annabeth", "Aquilo é um guardião! Escudo, espada e jato, nessa ordem se precisar!", "alert")

	# ---------------------------------------------------------- 7. Clímax
	_say(ev, 296.0, "Percy", "A gente não vai parar, né?", "worried")
	_say(ev, 298.0, "Annabeth", "Não até o fim.", "neutral")
	_spawn(ev, 300.0, "creature_brute", 0.5)
	_spawn(ev, 304.0, "spitter", 0.0, { "side": "R", "shots": 2 })
	_spawn(ev, 305.0, "creature_small", 0.2)
	_spawn(ev, 305.0, "creature_small", 0.8)
	_cam(ev, 306.0, 1.2, Vector2(0, 80), 3.0)
	_spawn(ev, 309.0, "barrier", 0.5)
	_spawn(ev, 313.0, "creature_mid", 0.3)
	_spawn(ev, 313.0, "creature_mid", 0.7)
	_spawn(ev, 316.0, "spitter", 0.0, { "side": "L", "shots": 3 })
	_say(ev, 312.0, "Annabeth", "Percy... lá embaixo. Aquele brilho. É água.", "alert")
	_say(ev, 316.0, "Percy", "Eu sinto. É um rio.", "alert")
	_spawn(ev, 320.0, "barrier", 0.5)
	_say(ev, 322.0, "Annabeth", "Aguente mais um pouco. Quando eu disser, faça o que você sabe fazer.", "neutral")

	ev.append({ "type": "finale", "t": FINALE_T })
	return ev


# ---------------------------------------------------------------- auxiliares

static func _spawn(ev: Array[Dictionary], t: float, kind: String, lane: float, extra: Dictionary = {}) -> void:
	var d := { "type": "spawn", "t": t, "kind": kind, "x": lane }
	d.merge(extra)
	ev.append(d)


static func _say(ev: Array[Dictionary], t: float, who: String, text: String, mood: String) -> void:
	ev.append({ "type": "say", "t": t, "who": who, "text": text, "mood": mood })


static func _prompt(ev: Array[Dictionary], t: float, id: String, keys: Array, label: String, dur: float) -> void:
	ev.append({ "type": "prompt", "t": t, "id": id, "keys": keys, "label": label, "dur": dur })


static func _unlock(ev: Array[Dictionary], t: float, what: String) -> void:
	ev.append({ "type": "unlock", "t": t, "what": what })


static func _cam(ev: Array[Dictionary], t: float, zoom: float, offset: Vector2, hold: float) -> void:
	ev.append({ "type": "cam", "t": t, "zoom": zoom, "offset": offset, "hold": hold })
