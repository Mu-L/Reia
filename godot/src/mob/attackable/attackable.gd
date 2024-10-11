class_name Attackable extends CharacterBody3D

@export_category("Attackable Stats")
@export var stats := AttackableStats.new()
@export var status := AttackableStatus.new()

func init(_name := "Attackable") -> void:
	name = _name # + _uuid

func hit(attacker: Attackable) -> void:
	if status.state != AttackableStatus.Status.ALIVE:
		return

	stats.damage(attacker)

	if stats.health == 0:
		status.die(attacker)
		print_debug("%s has killed %s" % [attacker.get_name(), get_name()])
		return

func attack(attackable: Attackable) -> void: # , ability: Ability
	attackable.hit(self)
