extends Node

# class member variables go here, for example:
onready var ownr = get_parent()

export(String) var use_function = ''
export(bool) var indestructible

func use():
	if use_function.empty():
		RPG.broadcast("The " +ownr.name+ " cannot be used", RPG.COLOR_DARK_GREY)
		return
	if has_method(use_function):
		var result = call(use_function)
		if result != "OK":
			RPG.broadcast(result,RPG.COLOR_DARK_GREY)
			return
		if not indestructible:
			ownr.kill()

func pickup():
	pass

func drop():
	pass

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	ownr.item = self
	
	#pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass