extends GridContainer

# class member variables go here, for example:
onready var objects = get_node('../InventoryObjects')
onready var name_label = get_node('../ItemName')

# Get the first free inventoryslot
func get_free_slot():
	for node in get_children():
		if node.contents.empty():
			return node

# find an inventoryslot which contains an item
func get_matching_slot(item):
	for node in get_children():
		if not node.contents.empty():
			if node.contents[0].name == item.name:
				return node

# add an item to an inventoryslot
func add_to_inventory(item):
	# find a matching slot
	var slot = get_matching_slot(item)
	# find free slot if no matches found
	if !slot: slot = get_free_slot()
	# break if no slots free
	if !slot: return
	
	# remove from world objects group
	if item.is_in_group('entities'):
		item.remove_from_group('entities')
	# add to inventory group
	if not item.is_in_group('inventory'):
		item.add_to_group('inventory')

	# shift item parent from Map to InventoryObjects
	item.get_parent().remove_child(item)
	objects.add_child(item)
	
	# assign the item to the slot
	slot.add_contents(item)

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	RPG.inventory = self

# moue support
func _on_slot_mouse_enter(slot):
	var name = '' if slot.contents.empty() else slot.contents[0].name
	var count = slot.contents.size()
	var nt = '' if count < 2 else str(count)+'x '
	name_label.set_text(nt + name)

func _on_slot_mouse_exit():
	name_label.set_text('')

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass