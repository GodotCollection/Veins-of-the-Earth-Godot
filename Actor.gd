extends Node

# class member variables go here, for example:
	
onready var ownr = get_parent()

export(int) var power = 1
export(int) var defense = 1

signal hp_changed(current,full)

export(int) var max_hp = 5 setget _set_max_hp
var hp = 5 setget _set_hp


func fill_hp():
	self.hp = self.max_hp

func fight(who):
	if who.fighter:
		who.fighter.take_damage(ownr, self.power)

func take_damage(from, amount):
	#print(get_parent().get_name() + " takes " + str(amount) + " damage!")
	broadcast_damage_taken(from,amount)
	self.hp -= amount

func die():
	get_parent().kill()

func _set_hp(value):
	hp = value
	emit_signal('hp_changed', hp, self.max_hp)
	if hp <= 0:
		die()

func _set_max_hp(what):
	max_hp = what
	emit_signal('hp_changed', self.hp, self.max_hp)

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	ownr.fighter = self
	fill_hp()
	
	#pass

func broadcast_damage_taken(from, amount):
	var n = from.name
	var m = str(amount)
	var color = RPG.COLOR_DARK_GREY
	if ownr == RPG.player:
		color = RPG.COLOR_RED
	RPG.broadcast(n+ " hits " +ownr.name+ " for " +str(amount)+ " HP",color)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func save():
	var data = {}
	data.power = self.power
	data.defense = self.defense
	data.max_hp = self.max_hp
	data.hp = self.hp
	return data

func restore(data):
	for key in data:
		if self.get(key)!=null:
			self.set(key, data[key])