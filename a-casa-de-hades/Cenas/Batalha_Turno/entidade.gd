extends Control
#Nodes
@export var HealthNode:Node
@export var AttackNode:Node

#Target
var CurrentTarget

#Status
var Str: int 
var Dex: int
var Int: int

func LoadEntity(TargetRes):
	Str = TargetRes.Str
	Dex = TargetRes.Dex
	Int =TargetRes.Int
	HealthNode.MaxHP = TargetRes.MaxHP
	HealthNode.CurrentHP = TargetRes.CurrentHP
	AttackNode.LoafSkills(TargetRes.Skills)
	HealthNode.Death.connect(Death)
	

func _ready():
	pass

func ReciveDamage(amount, type):
	HealthNode.TakeDamage(amount,type)
	
func Death():
	queue_free()
