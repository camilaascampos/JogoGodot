class_name JRPGInventory
## Itens que o jogador "pegou" antes da batalha. É estático: o valor sobrevive à troca de cena,
## então a história só precisa fazer, antes de abrir a luta:
##
##   JRPGInventory.give(JRPGInventory.YANKEES_CAP)           # Boné (booleano: tem ou não tem)
##   JRPGInventory.give(JRPGInventory.ATHENA_BLESSING, 2)    # Bênção de Atena (quantidade)
##   JRPGInventory.give(JRPGInventory.HEALING_POT, 3)        # Pote de cura (quantidade)
##
## Uma skill só aparece no menu se tiver RequiredItem preenchido e o jogador possuir o item.

const YANKEES_CAP := "yankees_cap"
const ATHENA_BLESSING := "athena_blessing"
const HEALING_POT := "healing_pot"

static var items: Dictionary = {}

## A cena "entre bosses" marca true: a batalha então NÃO sobrescreve o inventário com o de teste.
static var managed_by_story: bool = false
## Cena carregada depois de vencer a batalha ("" = nenhuma; a cena de teste só reinicia).
static var after_victory_scene: String = ""


static func count(id: String) -> int:
	return int(items.get(id, 0))


static func has(id: String) -> bool:
	return count(id) > 0


static func give(id: String, amount: int = 1) -> void:
	items[id] = count(id) + amount


## Gasta 'amount' unidades. Retorna false (e não gasta nada) se não houver o bastante.
static func take(id: String, amount: int = 1) -> bool:
	if count(id) < amount:
		return false
	items[id] = count(id) - amount
	return true


static func clear() -> void:
	items.clear()
