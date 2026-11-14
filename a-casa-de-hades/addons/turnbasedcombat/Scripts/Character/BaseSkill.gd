extends Resource
class_name JRPGBaseSkill

@export_group("UI & Identity")
@export var Name: String
@export_multiline var Description: String
@export var Icon: Texture2D
## Name of the animation in the AnimationPlayer instance of BaseBattle.
@export var AnimationName: String

@export_group("Targeting & Costs")
## Defines who can be targeted by this skill (e.g., Single Enemy, All Allies, Self).
@export var Target: JRPGEnums.Target
## What resource type this skill consumes.
@export var CostType: JRPGEnums.CostType = JRPGEnums.CostType.Magi
## How much of the CostType resource is consumed. 0 = no cost.
@export var Cost: int = 0

@export_group("Accuracy & Attributes")
## Chance (0 to 100) that the skill will successfully hit the target. (Usually 100 for healing/buffs).
@export_range(0, 100) var HitChance: int = 100
## Is this skill meant to deal damage or heal?
@export var DamageType: JRPGEnums.DamageType
## Elemental attribute of the attack (used to calculate target strengths and weaknesses).
@export var Element: JRPGEnums.Elements

@export_group("Mechanics & Math")
## Base power of the skill before stat calculations are applied.
@export var BaseDamage: int
## How many times this skill strikes the target(s) per use.[br]
## [color=red][b]NOT YET IMPLEMENTED[/b][/color]
@export var HitCount: int = 1

@export_group("Extras")
## Turnos em que a skill fica indisponível depois de usada (0 = sem recarga).
@export var Cooldown: int = 0
## Para DamageType.Health: cura essa % do HP máximo do alvo (se 0, cura BaseDamage).
@export_range(0, 100) var HealPercent: int = 0
## Para DamageType.PositiveStat: escudo que absorve esse tanto de dano.
@export var ShieldAmount: int = 0
## Só pode ser usada com a ultimate cheia e zera a carga ao usar.
@export var RequiresUltimate: bool = false
## Se false, nunca dá acerto crítico.
@export var CanCrit: bool = true
## Item do JRPGInventory necessário (ex.: "yankees_cap"). Sem o item, a skill nem aparece no menu.
@export var RequiredItem: String = ""
## Se true, usar a skill gasta 1 unidade de RequiredItem (itens quantitativos).
@export var ConsumeItem: bool = false

@export_group("Status Effects")
## An optional status effect that can linger on the target over multiple turns after the skill hits.
@export var Effect: JRPGBaseEffect

## Aparece no menu? (o item exigido foi pego antes da batalha?)
func IsUnlocked() -> bool:
	return RequiredItem == "" or JRPGInventory.has(RequiredItem)

func CanUse(inst: JRPGCharInstance) -> bool:
	if not IsUnlocked():
		return false
	if inst.cooldown_left(self) > 0:
		return false
	if RequiresUltimate and inst.ultimate_charge < inst.ultimate_max:
		return false
	if CostType == JRPGEnums.CostType.Health:
		return inst.current_hp > Cost
	return inst.current_magi >= Cost

func PayCost(Caster: JRPGBaseBattleChar) -> void:
	var inst := Caster.Char
	if Cost > 0:
		if CostType == JRPGEnums.CostType.Health:
			inst.current_hp = maxi(inst.current_hp - Cost, 1)
		else:
			inst.current_magi = maxi(inst.current_magi - Cost, 0)
	if ConsumeItem and RequiredItem != "":
		JRPGInventory.take(RequiredItem)
	if RequiresUltimate:
		inst.ultimate_charge = 0.0
	if Cooldown > 0:
		inst.start_cooldown(self)

func Activate(Caster: JRPGBaseBattleChar, Targets: Array[JRPGBaseBattleChar]):
	if !Caster:
		push_error("Error: No caster specified")
		return
	if !Caster.Animator:
		push_error("Error: Caster has no AnimationPlayer specified")
		return
	# AnimationName vazio = sem animação (itens, poções, etc.)
	var has_anim := AnimationName.strip_edges() != ""
	if has_anim and !Caster.Animator.has_animation(AnimationName):
		push_error("Error: Casters AnimationPlayer does not have animation: " + AnimationName)
		return

	PayCost(Caster)
	JRPGSignalBus.instance.SetHighlightState.emit(JRPGEnums.HighlightState.NONE)
	if has_anim:
		Caster.Animator.play(AnimationName)
		await Caster.Animator.SkillDone

	for target in Targets:
		if target == null or not target.Char.IsAlive():
			continue

		match DamageType:
			JRPGEnums.DamageType.Damage:
				_hit(Caster, target)
			JRPGEnums.DamageType.Health:
				var amount := BaseDamage
				if HealPercent > 0:
					amount = ceili(target.Char.max_hp * HealPercent / 100.0)
				target.Heal(amount)
				JRPGSignalBus.instance.ResultToUI.emit("%s used %s on %s" % [Caster.Char.species.get_display_name(), Name, target.Char.species.get_display_name()])
			JRPGEnums.DamageType.PositiveStat, JRPGEnums.DamageType.NegativeStat:
				if ShieldAmount > 0:
					target.AddShield(ShieldAmount)
				JRPGSignalBus.instance.ResultToUI.emit("%s used %s on %s" % [Caster.Char.species.get_display_name(), Name, target.Char.species.get_display_name()])

		# Skills sem dano (buff/debuff/cura) também aplicam o efeito; as de dano aplicam dentro do _hit.
		if DamageType != JRPGEnums.DamageType.Damage and Effect:
			Effect.Attach(Caster, target)

func _hit(Caster: JRPGBaseBattleChar, target: JRPGBaseBattleChar) -> void:
	var target_name := target.Char.species.get_display_name()

	if randi_range(0, 99) >= HitChance:
		JRPGSignalBus.instance.ResultToUI.emit(Name + " missed " + target_name)
		target.FloatText("MISS", Color(0.8, 0.8, 0.8))
		return
	if target.TryDodge():
		JRPGSignalBus.instance.ResultToUI.emit(target_name + " dodged " + Name)
		target.FloatText("ESQUIVOU", Color(0.6, 0.85, 1.0))
		return

	var damage := float(BaseDamage) * randf_range(JRPGRules.DAMAGE_VARIANCE_MIN, JRPGRules.DAMAGE_VARIANCE_MAX)
	var crit := CanCrit and randf() < JRPGRules.CRIT_CHANCE
	if crit:
		damage *= JRPGRules.CRIT_MULTIPLIER

	var dealt := target.ApplySkill(roundi(damage), DamageType, Element, Caster, crit)

	# Bênção de Poseidon: acumula o dano causado.
	if Caster.Char.species.HasUltimate and not RequiresUltimate:
		Caster.Char.add_ultimate(dealt)

	if Effect:
		Effect.Attach(Caster, target)
