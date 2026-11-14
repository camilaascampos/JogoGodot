extends Node2D
class_name JRPGBaseBattleChar

var Animator: AnimationPlayer
var AIControl: JRPGAIController
var Char: JRPGCharInstance
var StatusEffects: Dictionary[JRPGBaseEffect,int]
var Team: JRPGEnums.Team

var HitChance: float = 1;
var Defense: float = 1;
var Strength: float = 1;
var Speed: float = 0;
## Escudo (Escudo de água): absorve dano antes do HP.
var Shield: int = 0

var AvailableAction := false

func _ready() -> void:
	print("BASEBATTLECHAR CARREGADO")
	Animator = $Animationplayer
	AIControl = $AIControl
	
	JRPGSignalBus.instance.StartTurn.connect(ApplyEffect.bind(true))
	JRPGSignalBus.instance.EndTurn.connect(ApplyEffect.bind(false))

func playstart(pos : Vector2):
	var tween = get_tree().create_tween()
	
	var time := 0.01 * global_position.distance_to(pos)
	tween.tween_property(self, "global_position", pos, time)
	
	if pos.x > global_position.x:
		Animator.play("WalkRight")
	elif pos.x < global_position.x:
		Animator.play("WalkLeft")
		
	await tween.finished
	Animator.play("Idle")
	JRPGSignalBus.instance.StartDone.emit()

func AITurn(Context: JRPGContext):
	AIControl.ChooseAction(self, Context);

func ApplySkill(Amount: int, DamageType: JRPGEnums.DamageType, Element: JRPGEnums.Elements, Caster: JRPGBaseBattleChar, Crit: bool = false) -> int:
	if DamageType != JRPGEnums.DamageType.Damage:
		return 0

	var damage := float(Amount) * Defense
	if Element == Char.species.Strength:
		damage *= 1.0 - JRPGRules.RESIST_REDUCTION
	var final_damage := maxi(roundi(damage), 0)

	var absorbed := mini(Shield, final_damage)
	Shield -= absorbed
	final_damage -= absorbed

	Char.current_hp = maxi(Char.current_hp - final_damage, 0)

	var text := "-%d" % final_damage
	if absorbed > 0:
		text += " (escudo %d)" % absorbed
	if Crit:
		text += "!"
	FloatText(text, Color(1.0, 0.85, 0.2) if Crit else Color.WHITE)

	var caster_name := Caster.Char.species.get_display_name()
	JRPGSignalBus.instance.ResultToUI.emit("%s hit %s for %d%s" % [caster_name, Char.species.get_display_name(), final_damage, " (CRIT!)" if Crit else ""])
	_check_death()
	return final_damage

func ApplyEffect(_character: JRPGBaseBattleChar, turn_team: JRPGEnums.Team, start_of_turn: bool):
	if Char == null or not Char.IsAlive():
		return
	# Gerenciador por personagem manda o dono do turno; o por time manda null + o time.
	if _character != null:
		if _character != self:
			return
	elif turn_team != Team:
		return

	var remove: Array[JRPGBaseEffect] = []
	for effect: JRPGBaseEffect in StatusEffects.keys():
		if effect.isStartOfTurn == start_of_turn:
			effect.Apply(self)
			StatusEffects[effect] -= 1
			if StatusEffects[effect] <= 0:
				remove.append(effect)
	for item: JRPGBaseEffect in remove:
		item.Remove(self)
		StatusEffects.erase(item)

	if not start_of_turn and Char.IsAlive():
		Char.tick_cooldowns()
		FillMagi(Char.species.Magi_Regen)

func IsActionBlocked() -> bool:
	for effect: JRPGBaseEffect in StatusEffects.keys():
		if effect.PreventsAction:
			return true
	return false

func IsImmobilized() -> bool:
	for effect: JRPGBaseEffect in StatusEffects.keys():
		if effect.PreventsDodge:
			return true
	return false

func IsInvisible() -> bool:
	for effect: JRPGBaseEffect in StatusEffects.keys():
		if effect.MakesInvisible:
			return true
	return false

func TryDodge() -> bool:
	if IsImmobilized():
		return false
	var chance := minf(Char.species.Speed * JRPGRules.DODGE_PER_SPEED, JRPGRules.DODGE_CAP)
	return randf() * 100.0 < chance

func AddShield(Amount: int) -> void:
	Shield += Amount
	FloatText("+%d escudo" % Amount, Color(0.5, 0.8, 1.0))

func TakeDamage(Amount: int, Effect: JRPGBaseEffect = null):
	var damage := absi(Amount)
	Char.current_hp = maxi(Char.current_hp - damage, 0)
	FloatText("-%d" % damage, Color(1.0, 0.5, 0.2))

	if Effect:
		JRPGSignalBus.instance.ResultToUI.emit(Effect.Name + " damaged " + Char.species.get_display_name() + " for " + str(damage) + " health")
	_check_death()

func Heal(Amount: int, Effect: JRPGBaseEffect = null):
	var before := Char.current_hp
	Char.current_hp = clampi(Char.current_hp + Amount, Char.current_hp, Char.max_hp)
	FloatText("+%d" % (Char.current_hp - before), Color(0.4, 1.0, 0.5))
	if Effect:
		JRPGSignalBus.instance.ResultToUI.emit(Effect.Name + " healed " + Char.species.get_display_name() + " for " + str(Amount) + " health")

func DrainMagi(Amount: int, Effect: JRPGBaseEffect = null):
	Char.current_magi = maxi(Char.current_magi - absi(Amount), 0)
	if Effect:
		JRPGSignalBus.instance.ResultToUI.emit(Effect.Name + " drained " + str(absi(Amount)) + " magi from " + Char.species.get_display_name())

func FillMagi(Amount: int, Effect: JRPGBaseEffect = null):
	Char.current_magi = clampi(Char.current_magi + Amount, Char.current_magi, Char.max_magi)
	if Effect:
		JRPGSignalBus.instance.ResultToUI.emit(Effect.Name + " filled " + Char.species.get_display_name() + "'s magi for " + str(Amount))

func _check_death() -> void:
	if Char.IsAlive():
		return
	AvailableAction = false
	modulate = Color(1, 1, 1, 0.3)
	var area := get_node_or_null("SelectArea") as Area2D
	if area != null:
		area.input_pickable = false
	JRPGSignalBus.instance.ResultToUI.emit(Char.species.get_display_name() + " was defeated")

## Texto que sobe e some sobre o personagem (dano, cura, MISS...).
func FloatText(text: String, color: Color = Color.WHITE) -> void:
	var label := JRPGHudTheme.make_label(text, 18, color)
	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector2(-20, -70)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -50), 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

func update_state_highlight(state: JRPGEnums.HighlightState, selected: JRPGBaseBattleChar, hovered: JRPGBaseBattleChar) -> void:
	match state:
		JRPGEnums.HighlightState.SELECTABLE_PLAYER:
			if Team != JRPGEnums.Team.Player: 
				HighLight(false, Color(0.781, 0.781, 0.781, 1.0))
				return
				
			if self == selected:
				HighLight(true, Color(0.97, 1.0, 0.445, 1.0))
			elif self == hovered && AvailableAction:
				HighLight(true, Color(0.97, 1.0, 0.445, 1.0))
			elif AvailableAction:
				HighLight(true, Color(0.644, 0.357, 0.0, 1.0))

		JRPGEnums.HighlightState.TARGET_ENEMY:
			# Special case: Always keep the acting player highlighted yellow
			if self == selected:
				HighLight(true, Color(0.97, 1.0, 0.445, 1.0))
				return
				
			if Team == JRPGEnums.Team.Enemy:
				var red = Color(1.0, 0.242, 0.242, 1.0) if self == hovered else Color(0.473, 0.0, 0.0, 1.0)
				HighLight(true, red)
			else:
				HighLight(false, Color(0.781, 0.781, 0.781, 1.0))

		JRPGEnums.HighlightState.TARGET_ALLY:
			if Team == JRPGEnums.Team.Player:
				if self == hovered:
					HighLight(true, Color(0.0, 0.742, 0.0, 1.0))
				elif self == selected:
					HighLight(true, Color(0.97, 1.0, 0.445, 1.0))
				else:
					HighLight(true, Color(0.0, 0.512, 0.0, 1.0))
			else:
				HighLight(false, Color(0.781, 0.781, 0.781, 1.0))

func _on_select_area_mouse_entered() -> void:
	JRPGSignalBus.instance.MouseOver.emit(self)

func _on_select_area_mouse_exited() -> void:
	JRPGSignalBus.instance.MouseOut.emit(self)

func _on_select_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			JRPGSignalBus.instance.Clicked.emit(self)

func HighLight(enable: bool, color: Color):
	material.set_shader_parameter("outline_enabled", enable)
	material.set_shader_parameter("outline_color", color)
	
func update_hp_bar():
	if Char == null:
		return

	var hp_bar = get_node_or_null("ProgressBar")
	if hp_bar == null:
		return

	hp_bar.max_value = Char.max_hp
	hp_bar.value = Char.current_hp	
func _process(_delta: float) -> void:
	update_hp_bar()
	if Char != null and Char.IsAlive():
		modulate.a = 0.45 if IsInvisible() else 1.0
