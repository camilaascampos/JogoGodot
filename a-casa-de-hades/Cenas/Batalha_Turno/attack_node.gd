extends Node

var Cooldowns:Array= []
var Skills:Array= []

func Attack_turn(skill):
	var Targets = get_parent().CurrentTargets
	var Damage = CalculateDamage(skill)
	for target in Targets:
		target.ReciveDamage(Damage, skill.SkillType)
	RefreshCooldowns()
		
	

func CalculateDamage(skill):
	var Damage = get_parent().get(skill.SkillType)
	Damage*= skill.SkillPower
	return Damage 
	
func LoadSkills(skills):
	for skill in skills:
		Skills.append(skill)
		Cooldowns.append(skill.SkillCooldown)
		
		
func RefreshCooldowns():
	for cooldowm in Cooldowns:
		cooldowm = max(cooldowm-1,0)
	
	
