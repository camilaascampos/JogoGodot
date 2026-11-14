extends Node
class_name JRPGSignalBus

#PUT SIGNALS HERE
signal StartTurn(Character: JRPGBaseBattleChar, Team: JRPGEnums.Team) #AddCharacterRef for effects
signal EndTurn(Character: JRPGBaseBattleChar, Team: JRPGEnums.Team) #AddCharacterRef for effects
signal PlayerTurn
signal EnemyTurn
signal DidAction
## Emitido pelo gerenciador de turnos quando um lado inteiro cai.
signal BattleEnded(player_won: bool)
## Emitido pela HUD quando o jogador confirma a tela de vitória/derrota.
signal EndBattle
## Emitido pela HUD quando o jogador escolhe TENTAR NOVAMENTE depois de perder.
signal RetryBattle
## Ordem dos próximos turnos (o primeiro é quem age agora). Usado pela faixa PRÓXIMO TURNO.
signal TurnOrderChanged(order: Array)

signal SelectedSkill(Skill: JRPGBaseSkill)
## O jogador apertou VOLTAR no menu: cancela a escolha de alvo ou desfaz a seleção do herói.
signal CancelCommand
## Comando DEFENDER do menu (hoje só gasta a ação do herói; a redução de dano é com você).
signal DefendChosen(Character: JRPGBaseBattleChar)

signal Start(pos : Vector2, char : JRPGBaseBattleChar)
signal StartDone
signal Clicked(char : JRPGBaseBattleChar)
signal MouseOver(char : JRPGBaseBattleChar)
signal MouseOut(char : JRPGBaseBattleChar)

#UI Signals
signal ResultToUI(text: String)
signal UpdateHighlight()
signal SelectedChar(char : JRPGBaseBattleChar)
signal SetHighlightState(State: JRPGEnums.HighlightState)

static var instance: JRPGSignalBus

func _enter_tree():
	if instance != null and instance != self:
		queue_free()
		return
	instance = self

func _exit_tree():
	if instance == self:
		instance = null
