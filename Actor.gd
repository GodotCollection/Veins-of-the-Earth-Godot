extends Node

# class member variables go here, for example:
	
onready var ownr = get_parent()

#export(int) var power = 1
var damage = [1,6]
export(int) var defense = 1

signal hp_changed(current,full)

export(int) var max_hp = 10 setget _set_max_hp
var hp = 10 setget _set_hp

# stats
var strength = 8
var dexterity = 8
var constitution = 8
var intelligence = 8
var wisdom = 8
var charisma = 8

var base_armor = 0 #setget _get_armor # damage reduction

# skills
var melee = 55

var body_parts = []

export(int) var faction_id = 1
enum faction { PLAYER = 0, ENEMY = 1, NEUTRAL = 2}

export(Array, String) var conversations


func get_armor():
	var armor = base_armor
	var object_bonuses = []

	for o in ownr.container.get_equipped_objects():
		if o.item.armor > 0:
			object_bonuses.append(o.item.armor)
			
	for v in object_bonuses:
		armor += v
		
#	print("Armor: " + str(armor))
	return armor


func fill_hp():
	self.hp = self.max_hp

# d100 roll under
func skill_test(skill):
	if ownr.is_visible():
		RPG.broadcast("Making a test for " + skill + " target " + str(get(skill)), RPG.COLOR_GREEN)
		
	var result = RPG.roll(1,100)
	
	if result < get(skill):
		#print("Skill test succeeded")
		
		if ownr == RPG.player:
			# check how much we gain in current skill
			var tick = RPG.roll(1,100)
			# roll OVER the current skill
			if tick > get(skill):
				# +1d4 if we succeeded
				var gain = RPG.roll(1,4)
				set(skill, get(skill) + gain)
				RPG.broadcast("You gain " + str(gain) + " skill points!", RPG.COLOR_GREEN)
			else:
				# +1 if we didn't
				set(skill, get(skill) + 1)
				RPG.broadcast("You gain 1 skill point", RPG.COLOR_GREEN)
		
		
		return true
	else:
		if ownr == RPG.player:
			# if we failed, the check for gain is different
			var tick = RPG.roll(1,100)
			# roll OVER the current skill
			if tick > get(skill):
				# +1 if we succeeded, else nothing
				set(skill, get(skill) + 1)
				RPG.broadcast("You learn from your failure and gain 1 skill point", RPG.COLOR_GREEN)
		
		
		#print("Skill test failed")
		return false


func fight(who):
	# paranoia
	if not who.fighter:
		return
		
	var react = faction_reaction[int(who.fighter.faction_id)]
	var self_react = faction_reaction[int(faction_id)]
#	print(who.get_name() + " reaction: " + str(react))
	if (RPG.player == self.ownr and react < -50) or self_react < -50: # hack for now
		# attack
		if skill_test("melee"):
		#var melee = RPG.roll(1,100)
		#if melee < 55:
			var dmg = RPG.roll(damage[0], damage[1])
			var mod = int(floor((strength - 10)/2))
			RPG.broadcast(ownr.read_name + " hits " + who.read_name + "!", RPG.COLOR_LIGHT_BLUE)
			who.fighter.take_damage(ownr, max(0,dmg + mod - who.fighter.get_armor())) #self.power)
			who.add_splash(0, max(0,dmg + mod - who.fighter.get_armor()))
		else:
			who.add_splash(1)
			RPG.broadcast(ownr.read_name + " misses " + who.read_name + "!")
	else:
		print("Not a hostile")
		if RPG.player == self.ownr and react == 0:
			# dialogue
			RPG.game.dialogue_panel.initial_dialogue(who.fighter)
			RPG.game.dialogue_panel.show()
			# prevents accidentally doing other stuff
			get_tree().set_pause(true)

func random_body_part():
	var loc = RPG.roll(1,20)
	if loc < 3:
		return body_parts[4] # left "leg"
	elif loc < 6:
		return body_parts[5] # right leg
	elif loc < 13:
		return body_parts[1] # torso
	elif loc < 16:
		return body_parts[2] # left arm
	elif loc < 19:
		return body_parts[3] # right arm
	else:
		return body_parts[0] # head
		
func take_damage(from, amount):
	# determine body part hit
	var part = random_body_part()
	# log
	broadcast_damage_taken(from,amount,part[0])
	
	#self.hp -= amount
	part[1] -= amount
	if RPG.player == self.ownr:
		emit_signal("hp_changed", part[1], part[2], part[0])
	
	if (part[0] == "torso" or part[0] == "head") and part[1] <= 0:
		die()

func die():
	get_parent().kill()

func _set_hp(value):
	hp = value
	#emit_signal('hp_changed', hp, self.max_hp)
	if hp <= 0:
		die()

func _set_max_hp(what):
	max_hp = what
	#emit_signal('hp_changed', self.hp, self.max_hp)

# this is where we apply stat bonus (after we have it)
func set_real_max_hp(what):
#	print(get_parent().get_name() + " bonus hp: " + str(int(floor(constitution - 10)/2)))
	max_hp = what + int(floor(constitution - 10)/2)
	#print(get_parent().get_name() + " " + str(max_hp))
	#emit_signal('hp_changed', self.hp, self.max_hp)


var body = { "humanoid": ["head", "torso", "arm", "arm2", "leg", "leg2"] }

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	
	# roll dice for stats
	for s in ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"]:
		#self[s] = RPG.roll_dice(3,6)
		set(s, RPG.roll_dice(3,6))
	
	
	ownr.fighter = self
	set_real_max_hp(self.max_hp)
	fill_hp()
	
	# set applicable marker color
	ownr.get_node("marker").set_modulate(get_marker_color())
	
	set_body_parts(body["humanoid"])


func set_body_parts(parts):
	print("Setting body parts...")
	
	var BP_TO_HP = {
			"head": 0.33,
			"torso": 0.4,
			"arm": 0.25, "arm2": 0.25,
			"leg": 0.25, "leg2": 0.25,
		}
	
	for p in parts:
		if p in BP_TO_HP:
			var hp = int(BP_TO_HP[p]*max_hp)
			#print("Looking up hp.." + str(hp))
			body_parts.append([p, hp, hp])


# log message
func broadcast_damage_taken(from, amount, part):
	var n = from.name
	var m = str(amount)
	var color = RPG.COLOR_DARK_GREY
	if ownr == RPG.player:
		color = RPG.COLOR_RED
	RPG.broadcast(n+ " hits " +ownr.read_name+ " in the " + str(part) + " for " +str(amount)+ " HP",color)

var faction_reaction = { faction.PLAYER: 100, faction.ENEMY: -100, faction.NEUTRAL: 0 }
func get_marker_color():
	var react = faction_reaction[faction_id]
	print(str(react))
	
	if react < -50:
		return Color(1.0, 0, 0) #"red"
	elif react < 0:
		return "orange"
	elif react == 0:
		return Color(1.0, 1.0, 0.0) #"yellow"
	elif react > 50:
		return Color(0, 1.0, 1.0)  #"cyan"
	elif react > 0:
		return "blue"

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func save():
	var data = {}
	data.damage = self.damage
	data.defense = self.defense
	data.max_hp = self.max_hp
	data.hp = self.hp
	data.strength = self.strength
	data.dexterity = self.dexterity
	data.constitution = self.constitution
	data.intelligence = self.intelligence
	data.wisdom = self.wisdom
	data.charisma = self.charisma
	data.faction_id = self.faction_id
	data.body_parts = self.body_parts
	return data

func restore(data):
	for key in data:
		if self.get(key)!=null:
			self.set(key, data[key])