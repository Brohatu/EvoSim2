extends World


func generate_world_terrain():
	
	# generate biome for random tile
	# find the 6 adjacent tiles
	# generate biome for each of these tiles based on their surrounding tiles
	
	
	# Odds for surrounding tiles for a given biome
	# Ocean: Ocean(70%), Desert, Grassland, Rainforest, Mountain, 
	# Mountain: Mountain(50%), Woods(20%), Desert(20%), Rainforest(5%), Ocean(5%), Grassland(10%)
	
	
	
	var initial = tiles.pick_random() as Tile
	
	initial.random_biome()
	var neighbours:Array = initial.get_overlapping_areas()
	for t in neighbours:
		generate_terrain(t)
		
	#generate_terrain(initial)


func generate_terrain(current:Tile):
	var neighbours:Array = current.get_overlapping_areas()
	var adjacent_terrain:Array
	var terrain_chance:Array
	# find all of the surrounding terrain
	for t in neighbours:
		adjacent_terrain.append(t.biome[BIOME_ID])
	# determine the current tile's terrain based on the surrounding terrain
	# undetermined tiles don't contribute to the calculation
	for at in adjacent_terrain:
		match at:
			-1: # Don't add anything. Because the original tile has a non-default biome, at least one neighbour must have
				# a legitimate tile ID
				pass
			0: #Grassland: Grassland(60%), Desert(10%), Ocean(5%), Mountain(5%), Woods(10%), Rainforest(10%)
				terrain_chance.append_array([0,0,0,0,0,0,0,0,0,0,0,0])
				terrain_chance.append_array([1,1])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3])
				terrain_chance.append_array([4,4])
				terrain_chance.append_array([5,5])
			1: #Desert: Grassland(20%), Desert(50%), Ocean(10%), Mountain(20%)
				terrain_chance.append_array([0,0,0,0,0,0])
				terrain_chance.append_array([1,1])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3])
			2: #Ocean: Grassland(5%), Desert(5%), Ocean(70%), Mountain(5%), Woods(5%), Rainforest(5%),
				terrain_chance.append_array([0])
				terrain_chance.append_array([1])
				terrain_chance.append_array([2,2,2,2,2,2,2,2,2,2,2,2,2,2])
				terrain_chance.append_array([3])
				terrain_chance.append_array([4])
				terrain_chance.append_array([5])
			3: #Mountain: Grassland(5%), Desert(10%), Ocean(5%), Mountain(60%), Woods(10%), Rainforest(10%),
				terrain_chance.append_array([0])
				terrain_chance.append_array([1,1])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3,3,3,3,3,3,3,3,3,3,3])
				terrain_chance.append_array([4,4])
				terrain_chance.append_array([5,5])
			4: #Woods: Grassland(10%), Desert(0), Ocean(5%), Mountain(15%), Woods(60%), Rainforest(10%)
				terrain_chance.append_array([0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3,3])
				terrain_chance.append_array([4,4,4,4,4,4,4,4,4,4,4,4])
				terrain_chance.append_array([5,5])
			5: #Rainforest: Grassland(20%), Desert(0), Ocean(10%), Mountain(10%), Woods(10%), Rainforest(50%)
				terrain_chance.append_array([0,0,0,0])
				terrain_chance.append_array([2,2])
				terrain_chance.append_array([3,3])
				terrain_chance.append_array([4,4])
				terrain_chance.append_array([5,5,5,5,5,5,5,5,5,5])
	var picked_biome = adjacent_terrain.pick_random()
	var key:String
	match picked_biome:
		0:
			key = "Grassland"
		1:
			key = "Desert"
		2:
			key = "Ocean"
		3:
			key = "Mountain"
		4:
			key = "Woods"
		5:
			key = "Rainforest"
	current.biome = Globals.Biomes[key]
	current.update()
	
