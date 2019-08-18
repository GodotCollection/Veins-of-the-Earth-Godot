extends TileMap

var data = null

# Draw map cells from map 2DArray
func draw_map( map ):
	for x in range( map.size() ):
		for y in range( map[x].size() ):
			set_cell( x,y, map[x][y] )

# inverse of what the old FogMap node did
func fill():
	#print("Clearing the whole map")
	for x in range(data.map.size()):
		for y in range(data.map[x].size()):
			set_cell(x, y, -1) # clear
			
func reveal(cells):
	for cell in cells:
		if get_cellv(cell) == -1:
			set_cell(cell[0],cell[1], data.map[cell[0]][cell[1]])

func _ready():
	RPG.map = self
	
func new_game():
	#data = dun_gen.Generate_random()
	data = dun_gen.Generate_BSP()
	#data = dun_gen.Generate_Town_BSP()
	draw_map( data.map )
	
	fill()
	#RPG.map_size = Vector2(data.map.size(), data.map[0].size())
	
	# Astar representation
	Astar_map.build_map(Vector2(data.map.size(), data.map[0].size()), dun_gen.get_floor_cells()) 
	
	call_deferred("spawn_player", data.start_pos, true)

func spawn_player(pos, start_game=false):
	var player = RPG.make_entity( "player/player" )
	spawn(player, pos)
	#call_deferred("spawn", player, data.start_pos)
	RPG.player = player
	var ob = RPG.player
	ob.fighter.connect("hp_changed", RPG.game.playerinfo, "hp_changed")
	ob.fighter.emit_signal("hp_changed",ob.fighter.hp, ob.fighter.max_hp)
	
	if start_game:
		# starting inventory
		var pot = RPG.make_entity("potion/potion")
		spawn(pot, pos)
		pot.item.pickup(player)
		var flask = RPG.make_entity("flask/flask")
		spawn(flask, pos)
		flask.item.pickup(player)
		var ration = RPG.make_entity("rations/rations")
		spawn(ration, pos)
		ration.item.pickup(player)
		var armor = RPG.make_entity("leather armor/leather armor")
		spawn(armor, pos)
		armor.item.pickup(player)
		# equip starting armor
		armor.item.use(player)
		
	# welcome message
	RPG.broadcast("Welcome to Veins of the Earth!", RPG.COLOR_BROWN)


func next_level():
	print("Changing level...")
	
	# nuke all entities that were on previous level
	clear_entities()
	
	data = dun_gen.Generate_BSP()
	#draw_map( data.map )
	
	# Astar representation
	Astar_map.build_map(Vector2(data.map.size(), data.map[0].size()), dun_gen.get_floor_cells())
	
	# fill it first
	fill()
	#get_node('FogMap').fill()
	
	# place player in safe spot (on floor)
	var spot_id = randi() % dun_gen.get_floor_cells().size()
	var safe_spot = dun_gen.get_floor_cells()[spot_id]
	print("Safe spot: " + str(safe_spot))
	
	RPG.player.set_map_position(safe_spot)
	
	# calculate FOV anew
	_on_player_pos_changed(RPG.player)
	
	
func clear_entities():
	for node in get_tree().get_nodes_in_group('entity'):
		if node != RPG.player:
			node.queue_free()
			

# Return TRUE if cell is a floor on the map
func is_walkable( cell ):
	var walk = [0,2,3]
	return walk.has(get_cellv( cell )) #== 0

func get_entities_in_cell(cell):
	var list = []
	for obj in get_tree().get_nodes_in_group('entity'):
		if obj.get_map_position() == cell:
			list.append(obj)
	return list
	
func get_entities_in_cell_readable(cell):
	var ret = []
	var list = get_entities_in_cell(cell)
	for obj in list:
		ret.append(obj.read_name)
	
	return ret
	
func is_stairs(cell):
	return get_cellv(cell) == 2

# MAIN LOOP!!!
# Turn-based
func _on_player_acted():
	for node in get_tree().get_nodes_in_group('entity'):
		if node != RPG.player and node.ai:
			#print(node.get_name() + " gives you a dirty look!")
			node.ai.take_turn()
		elif node == RPG.player:
			node.act()
	
# Return False if cell is an unblocked floor
# Return Object if cell has a blocking Object
func is_cell_blocked(cell):
	var blocks = not is_walkable(cell)
	var entities = get_entities_in_cell(cell)
	for e in entities:
		if e.block_move:
			blocks = e
	return blocks

func _on_player_pos_changed(player):
	# Torch (sight) radius
	var r = RPG.TORCH_RADIUS
	
	# Get FOV cells
	var cells = FOV_gen.calculate_fov(data.map, 1, player.get_map_position(), r)
	
	#print("Cells to reveal: " + str(cells))
	# Reveal cells
	reveal(cells)
	
	#$"FogMap".reveal(cells)
	# Light
	$"LightMap".reveal_all()
	$"LightMap".fill_cells(cells)
	
	for cell in cells:
		for obj in get_tree().get_nodes_in_group('entity'):
			if obj.get_map_position() == cell and not obj.is_visible():
				obj.set_visible(true)


# Spawn what path from Database, set position to where
func spawn( what, where, start_game=false ):
	print("Spawning: " + str(what.get_name()) + " @: " + str(where))
	# this is the name in the database, which is readable
	what.read_name = what.get_name()
	print("Readable name: " + str(what.read_name))
	# Add the entity to the scene and set its pos
	add_child( what, true)
	#what.set_map_pos( where )
	what.set_map_position(where)
	#print("Map position set " + str(where))
	
	if start_game:
		# starting inventory
		var sw = RPG.make_entity("longsword/longsword")
		spawn(sw, where)
		sw.item.pickup(what)	
	
func save():
	print("Saving map data...")
	var data = {}
	data.map = dun_gen.map
	data.fogmap = get_node('FogMap').get_fog_data(data.map.size(), data.map[0].size())
	return data

func restore(save_data):
	if 'map' in save_data:
		dun_gen.map = save_data.map
		data = {} # dummy
		data.map = dun_gen.map
	if 'fogmap' in save_data:
		# fill it first
		get_node('FogMap').fill()
		get_node('FogMap').reveal_from_data(save_data.fogmap)
		
	draw_map(data.map)
	Astar_map.build_map(Vector2(data.map.size(), data.map[0].size()), dun_gen.get_floor_cells())
	
func restore_object(data):
	var ob = RPG.make_entity(data.original)
	#var ob = load(data.filename)
	#print(data.filename)
	var pos = Vector2(data.x, data.y)
	if ob:
#		print(ob)
		spawn(ob, pos) 
		#ob = ob.instance().spawn(self,pos)
		ob.restore(data)
		return ob