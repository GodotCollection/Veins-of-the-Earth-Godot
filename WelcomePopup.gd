extends Popup

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and is_visible():
			print("Clicked")
			
			hide()
			
			get_parent().get_node("CharacterCreation").roll()
			get_parent().get_node("CharacterCreation").show()


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
