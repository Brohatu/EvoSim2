extends Node

class_name River
# River walker is instantiated at a mountain that gets x rain.
# Each step it finds a neighbouring tile and checks its biome and whether a
# river already exists there.
# If it finds a mountain it chooses a different tile
# If it finds an ocean tile it terminates
# if it finds another river it checks how big that river is
#	if the new river is larger it terminates
#	if the new river is smaller it overrules that river
# Once the river terminates it increases the precipitation in all of its tiles
# by an appropriate amount

const BIOME_ID = 0
const BIOME_NAME = 1
const BIOME_COLOR = 2
const BIOME_BASE_FOOD = 3
const BIOME_RAINFALL = 4

var path_length:int = 0
var river_tiles:Array = []
var source

var additive_rivers:bool = false

func begin(src) -> bool:
	source = src
	#source.river_sources.append(source)
	#Globals.river_counter += 1
	var valid = step(source)
	#if valid:
		#river_tiles.append(src)
	return valid


# 1) check for non-mountain tiles
# 2) check if the ocean has been reached *consider swapping 1) and 2)
# 3) filter out upstream tiles
# 4) check if we've hit a bigger river
# 5) step normally to random remaining tile option
func step(current) -> bool:
	# path_length increments when assigning value to tile.
	# If the river has to be retracted to an earlier tile, path_length become
	# the value at that tile
	
	# If current already has a river, we're overwriting it with a bigger river
	
	var valid:bool
	path_length += 1
	Globals.river_counter += 1
	print("Id: ", current.id, "  River increment: ", Globals.river_counter)
	current.river_size = path_length
	river_tiles.append(current)
	var next
	var neighbours = current.get_overlapping_tiles()
	
	# check whether there are any non mountain neighbours
	var non_mountains = neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN)
	if non_mountains:
		# check for neighbouring rivers. If one exists, attach this river to it
		var adjacent_river_tiles = non_mountains.filter(func(neighbour) : return neighbour.has_river)
		if adjacent_river_tiles:
				adjacent_river_tiles.sort_custom(func(a, b) : return a.river_size > b.river_size)
				next = adjacent_river_tiles[0]
				next.river_sources.append(current)
				return true
		
			#else:
				## check if other river is bigger
				#var valid_junctions_bigger = adjacent_river_tiles.filter(func(neighbour:Tile) : return neighbour.river_size >= current.river_size)
				## if other river is bigger, river is valid
				#if valid_junctions_bigger:
					#return true
				## if other river is smaller, follow its path and overwrite it
				#var valid_junctions_smaller = adjacent_river_tiles.filter(func(neighbour:Tile) : return neighbour.river_size < current.river_size)
				#if valid_junctions_smaller:
					#next = valid_junctions_smaller.pick_random()
					##river_tiles.append(next)
					#valid = step(next)
					#if valid:
						#next.river_sources.append(current)
		
		# there are no neighbouring rivers, so pick a random tile
		else:
			# If we've reached the ocean, the river is finished. Return true.
			var oceans = non_mountains.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.OCEAN)
			if oceans:
				current.river_sink = oceans.pick_random()
				return true
			
			# Remove previous tiles from this river from potential targets
			var upstream_tiles = non_mountains.filter(func(neighbour) : return river_tiles.has(neighbour))
			if upstream_tiles:
				for t in upstream_tiles:
					non_mountains.erase(t)
			
			if not non_mountains:
				return false 
			else:
				next = non_mountains.pick_random()
				valid = step(next)
				# if this path ends up being invalid, erase next from list
				# and pick again
				while not valid:
					non_mountains.erase(next)
					#river_tiles.erase(next)
					# if there are no more neighbours, the river can't find a path to the sea
					# retract the river to the last valid tile
					if not non_mountains:
						river_tiles.erase(current)
						return false
					next = non_mountains.pick_random()
					#river_tiles.append(next)
					valid = step(next)
				#river_tiles.append(next)
				next.river_sources.append(current)
				return valid
	# if all neighbours are mountains this is blatently invalid
	river_tiles.erase(current)
	return false



func step_2(current, prev):
	# assign river stats
	path_length += 1
	current.has_river = true
	current.river_size = path_length
	river_tiles.append(current)
	var neighbours = current.get_overlapping_tiles()
	# remove previous tile from neighbours
	if prev != null:
		neighbours.erase(prev)
	# remove mountains from possible target tiles
	# remove previous tile of this river from target tiles
	for n in neighbours:
		match n.biome[BIOME_ID]:
			Globals.Biome_ID.MOUNTAIN:
				neighbours.erase(n)
			_:
				pass
		if river_tiles.has(n):
			neighbours.erase(n)
	
	if neighbours.size() == 0:
		path_length -= 1
		current.has_river = false
		current.river_size = 0
		river_tiles.erase(current)
		step_2(prev, current)
	
	# if the river has reached the coast, terminate
	var ocean_tiles = neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.OCEAN)
	if ocean_tiles.size() == 0:
		 # if river has met another longer river, terminate
		if neighbours.filter(func(neighbour) : return neighbour.river_size > current.river_size).size() == 0:
			#otherwise pick a new tile to step to
			var next = neighbours.pick_random()
			step_2(next, current)



func step_old(current):
	var neighbours = current.get_overlapping_tiles()
	var next = neighbours.pick_random()
	if not river_tiles.has(next):
		if not neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.OCEAN) and neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN):
			while next.biome[BIOME_ID] == Globals.Biome_ID.MOUNTAIN:
				neighbours.erase(next)
				if neighbours.size() > 0:
					next = neighbours.pick_random()
			if next != null:
				if next.has_river:
					check_river(current, next)
					step_old(next)
				elif next.biome[BIOME_ID] != Globals.Biome_ID.OCEAN:
					next.has_river = true
					path_length += 1
					next.river_size = path_length
					river_tiles.append(next)
					step_old(next)


func overrule_river(target):
	path_length += 1
	target.river_size = path_length

func check_river(current, target) -> bool:
	if current.river_size > target.river_size:
		overrule_river(target)
	else:
		return false
	return true
