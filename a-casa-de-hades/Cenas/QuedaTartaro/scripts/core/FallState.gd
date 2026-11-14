class_name FallState
## Encaixe da sequência de queda com o resto do jogo.
##
## ENTRADA: a cutscene anterior (ou qualquer cena) pode, antes de abrir queda_tartaro.tscn:
##     FallState.set_entry({"start_phase": 0})
## Chaves previstas (todas opcionais):
##     "start_phase": int  -> fase em que começar (0 = início)
## Rodando a cena sozinha (F6) nada disso é necessário: valem os padrões.
##
## SAÍDA: ao terminar, a cena grava FallState.result e abre FallState.next_scene.

const DEFAULT_NEXT_SCENE := "res://Cenas/EntreBosses/entre_bosses.tscn"

static var entry: Dictionary = {}
static var next_scene: String = DEFAULT_NEXT_SCENE
## Preenchido no final: {"completed": bool, "deaths": int, "time": float}
static var result: Dictionary = {}


static func set_entry(data: Dictionary) -> void:
	entry = data


## Devolve o estado de entrada e o zera (a cena só o consome uma vez).
static func take_entry() -> Dictionary:
	var data := entry
	entry = {}
	return data


static func finish(data: Dictionary) -> void:
	result = data
