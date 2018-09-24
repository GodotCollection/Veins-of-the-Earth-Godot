extends Control

# class member variables go here, for example:
onready var messagebox = get_node('frame/right/Panel/MessageBox')
onready var playerinfo = get_node('frame/left/PlayerInfo')
onready var inventory = get_node('frame/right/map/InventoryPanel')

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	RPG.game = self
	messagebox.set_scroll_follow(true)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
