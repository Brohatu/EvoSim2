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


func step_new(current:Tile, prev:Tile):
	# assign river stats
	path_length += 1
	current.has_river = true
	current.river_size = path_length
	river_tiles.append(current)
	var neighbours = current.get_overlapping_areas()
	# remove previous tile from neighbours
	if prev != null:
		neighbours.erase(prev)
	# remove mountains from possible target tiles
	# remove previous tile of this river from target tiles
	for n:Tile in neighbours:
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
		step_new(prev, current)
	
	# if the river has reached the coast, terminate
	var ocean_tiles = neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.OCEAN)
	if ocean_tiles.size() == 0:
		 # if river has met another longer river, terminate
		if neighbours.filter(func(neighbour) : return neighbour.river_size > current.river_size).size() == 0:
			#otherwise pick a new tile to step to
			var next = neighbours.pick_random()
			step_new(next, current)



func step(current:Tile):
	var neighbours = current.get_overlapping_areas()
	var next:Tile = neighbours.pick_random()
	if not river_tiles.has(next):
		if not neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.OCEAN) and neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN):
			while next.biome[BIOME_ID] == Globals.Biome_ID.MOUNTAIN:
				neighbours.erase(next)
				if neighbours.size() > 0:
					next = neighbours.pick_random()
			if next != null:
				if next.has_river:
					check_river(current, next)
					step(next)
				elif next.biome[BIOME_ID] != Globals.Biome_ID.OCEAN:
					next.has_river = true
					path_length += 1
					next.river_size = path_length
					river_tiles.append(next)
					step(next)


func overrule_river(target:Tile):
	path_length += 1
	target.river_size = path_length

func check_river(current:Tile, target:Tile) -> bool:
	if current.river_size > target.river_size:
		overrule_river(target)
	else:
		return false
	return true
