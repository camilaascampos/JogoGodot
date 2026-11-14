extends Resource
class_name JRPGSpecies

## Nome interno. Também é o nome da pasta em Cenas/Batalha/BattleChars/ — não mude sem renomear a pasta.
@export var Name : String
@export_group("HUD")
## Nome mostrado na tela. Se vazio, usa Name sem o prefixo "Arai_" (ex.: Arai_Kelli -> KELLI).
@export var DisplayName : String = ""
## Retrato nos cartões da HUD. Se vazio, a HUD recorta o busto do sprite de batalha.
@export var Portrait : Texture2D
## Cor da borda/nome do cartão do herói.
@export var HudColor : Color = Color(0.88, 0.64, 0.26, 1.0)
## Se marcado, a barra de ultimate ("ULTIMATE DE ...") aparece na HUD.
@export var HasUltimate : bool = false
@export_group("Stats")
## Habilidade usada pelo comando ATACAR. Se vazio, usa a primeira habilidade equipada.
@export var BasicAttack : JRPGBaseSkill
## Velocidade: influencia a chance de esquiva (ver JRPGRules).
@export var Speed : int = 10
## Quanto de dano causado enche a ultimate (só importa se HasUltimate).
@export var UltimateMax : int = 300
@export var Max_Base_HP : int
@export var Max_Base_Magi : int
@export var HP_Growth : int
@export var Magi_Growth : int
@export var Magi_Regen: int
@export var Weakness : JRPGEnums.Elements
@export var Strength : JRPGEnums.Elements
@export var Base_Skills : Array[JRPGBaseSkill] # Skills every instance starts with
@export var Learnable_Skills : Array[JRPGBaseSkill] # Skills the instance can learn


func get_display_name() -> String:
	if DisplayName != "":
		return DisplayName
	return Name.replace("Arai_", "").replace("_", " ")
