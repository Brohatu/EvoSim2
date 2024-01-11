extends Node2D

class_name World

var tile_scene:PackedScene = preload("res://scenes/tile/tile.tscn")

const BIOME_ID = 0
const BIOME_NAME = 1
const BIOME_COLOR = 2
const BIOME_BASE_FOOD = 3
const BIOME_RAINFALL = 4

const POLAR_N = 0.1
const POLAR_S = 1.0

const TEMPERATE_N = 0.3
const TEMPERATE_S = 0.9

const DRY_N = 0.4
const DRY_S = 0.7

const TROPICAL = 0.6

@export var parameters:WorldParameters
@export var old_gen:bool = true


var tiles:Array
var build_arr:Array

var pol_n 
var temp_n 
var dry_n 
var tropic 
var dry_s 
var temp_s 
var pol_s 

func generate_new_world():
	var offset:bool = false
	for j in parameters.dimensions.y:
		for i in parameters.dimensions.x:
			var tile = tile_scene.instantiate() as Tile
			
			tile.global_position.x = 150 + i * 225 
			if offset:
				tile.global_position.y = 130 + j * 260
			else:
				tile.global_position.y = 260 + j * 260
			tile.id = Vector2i(i,j)
			$Tiles.add_child(tile)
			offset = !offset
	$Tiles.scale = Vector2(0.5, 0.5)
	tiles = $Tiles.get_children()
	

func generate_world_terrain():
	# generate biome for random tile
	# find the 6 adjacent tiles
	# generate biome for each of these tiles based on their surrounding tiles
	
	# Odds for surrounding tiles for a given biome
	# Ocean: Ocean(70%), Desert, Grassland, Rainforest, Mountain, 
	# Mountain: Mountain(50%), Woods(20%), Desert(20%), Rainforest(5%), Ocean(5%), Grassland(10%)
	
	if old_gen:
		for t:Tile in tiles:
			t.biome = Globals.Biomes["Default"]
			t.update()
		var initial = tiles.pick_random() as Tile
		initial.random_biome()
		var neighbours:Array = initial.get_overlapping_areas()
		for t in neighbours:
			generate_terrain_old(t)
	else:
		generate_terrain_new()



func generate_terrain_new():
	# 0) create new build array with all tiles inside. Erase them from build_arr once they are finished generating
	build_arr = []
	print("placing landmasses")
	# 1) determine whether tile is land or ocean
		# select x random tiles
	for i in range(0, parameters.land_seeds):
		var land_seed:Tile = tiles.pick_random() as Tile
		while land_seed.biome[BIOME_ID] != Globals.Biome_ID.OCEAN:
			land_seed = tiles.pick_random() as Tile
		# x.biome = land
		land_seed.biome = Globals.Biomes["Default"]
		land_seed.update()
		build_arr.append(land_seed)
		
		# get x neighbours
		var neighbours = land_seed.get_overlapping_areas()
		var trim:int = randi_range(0,2)
		for j in range(trim):
			var remove = neighbours.pick_random()
			neighbours.erase(remove)
		# for t in neighbours
			# t.biome is land
		for t in neighbours:
			t.biome = Globals.Biomes["Default"]
			t.update()
			build_arr.append(t)
	
	# 2) determine temperature region borders
	pol_n = parameters.dimensions.y * POLAR_N # eg 20 * 0.1 = 2
	temp_n = parameters.dimensions.y * TEMPERATE_N
	dry_n = parameters.dimensions.y * DRY_N
	tropic = parameters.dimensions.y * TROPICAL
	dry_s = parameters.dimensions.y * DRY_S
	temp_s = parameters.dimensions.y * TEMPERATE_S
	pol_s = parameters.dimensions.y
	
	# 3) determine height of land tiles
	generate_mountains()
	
	# 4) determine precipitation levels
	generate_precipitation()
	
	# 5) apply appropriate terrain based on conditions
	generate_biomes()
	
	# 6) adjust biomes according to neighbouring tiles
	adjust_biomes()

## Mountain ranges are created by seeding a given number of tiles and walking 
## from tile to tile for a given number of steps.
## If they walk onto an ocean tile, turn the ocean tile into a default tile.
func generate_mountains():
	print("generating mountains")
	#var neighbours:Array
	var counter:int
	for i in range(0, parameters.mountain_seeds):
		counter = randi_range(4,10)
		var mountain_seed = build_arr.pick_random() as Tile
		while mountain_seed.biome[BIOME_ID] != Globals.Biome_ID.DEFAULT:
			mountain_seed = build_arr.pick_random() as Tile
		mountain_seed.biome = Globals.Biomes["Mountain"]
		mountain_seed.update()
		if counter > 0:
			walk_mountain(mountain_seed, counter)
	print("generating mountains complete")

func walk_mountain(mountain:Tile, counter:int):
	counter -= 1
	var neighbours = mountain.get_overlapping_areas()
	var next_mountain = neighbours.pick_random()
	if next_mountain.biome[BIOME_ID] == Globals.Biome_ID.OCEAN:
		next_mountain.biome = Globals.Biomes["Grassland"]
		build_arr.append(next_mountain)
	else:
		next_mountain.biome = Globals.Biomes["Mountain"]
	next_mountain.update()
	if counter > 0:
		walk_mountain(next_mountain, counter)


func generate_precipitation():
	var rain_tiles = build_arr.duplicate()
	
	for t:Tile in tiles:
		if t.biome[BIOME_ID] == Globals.Biome_ID.OCEAN:
			t.precip = 100.0
			t.update()
	var neighbours:Array
	# get coastal precip
	for t:Tile in build_arr:
		if t.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN:
			var precip_val:float = 0.0
			neighbours = t.get_overlapping_areas()
			for n:Tile in neighbours:
				match n.biome[BIOME_ID]:
					Globals.Biome_ID.OCEAN:
						precip_val += n.precip * parameters.rain_dropoff
					_:
						pass
			t.precip = precip_val
			t.update()
			if t.precip != 0:
				rain_tiles.erase(t)
		else:
			rain_tiles.erase(t)
	# get precip for inner layers from coast
	while rain_tiles.size() > 0:
		for t:Tile in rain_tiles:
			var precip_val = 0.0
			neighbours = t.get_overlapping_areas()
			for n:Tile in neighbours:
				precip_val += n.precip * parameters.rain_dropoff
			t.precip_temp = precip_val
		for t:Tile in build_arr:
			if t.precip_temp != 0:
				t.precip = t.precip_temp
				t.precip_temp = 0
				rain_tiles.erase(t)
			t.update()
	

func generate_biomes():
	print("calculating biomes")
	var lat:float
	for t:Tile in build_arr:
		if t.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN:
			lat = t.id.y
			
			# polar: 
			# always polar biome
			if lat < pol_n:
				t.biome = Globals.Biomes["Polar"]
			# temperate:
			# standard biome spread
			elif lat < temp_n:
				if t.precip > parameters.forest_precip:
					t.biome = Globals.Biomes["Woods"]
				elif t.precip > parameters.grassland_precip:
					t.biome = Globals.Biomes["Grassland"]
				else:
					t.biome = Globals.Biomes["Desert"]
			# dry:
			# values must be higher by a factor to match temperate
			elif lat < dry_n:
				if t.precip > parameters.forest_precip * 1.4:
					t.biome = Globals.Biomes["Woods"]
				elif t.precip > parameters.grassland_precip * 1.4:
					t.biome = Globals.Biomes["Grassland"]
				else:
					t.biome = Globals.Biomes["Desert"]
			# tropical:
			# values are reduce by a factor
			elif lat < tropic:
				if t.precip > parameters.forest_precip * 0.5:
					t.biome = Globals.Biomes["Rainforest"]
				elif t.precip > parameters.grassland_precip * 0.5:
					t.biome = Globals.Biomes["Grassland"]
				else:
					t.biome = Globals.Biomes["Desert"]
			elif lat < dry_s:
				if t.precip > parameters.forest_precip * 1.2:
					t.biome = Globals.Biomes["Woods"]
				elif t.precip > parameters.grassland_precip * 1.2:
					t.biome = Globals.Biomes["Grassland"]
				else:
					t.biome = Globals.Biomes["Desert"]
			elif lat < temp_s:
				if t.precip > parameters.forest_precip:
					t.biome = Globals.Biomes["Woods"]
				elif t.precip > parameters.grassland_precip:
					t.biome = Globals.Biomes["Grassland"]
				else:
					t.biome = Globals.Biomes["Desert"]
			elif lat < pol_s:
				t.biome = Globals.Biomes["Polar"]
			t.update()
	print("calculating biomes complete")


func adjust_biomes():
	print("adjusting")
	for t:Tile in tiles:
		
		var neighbours = t.get_overlapping_areas()
		match t.biome[BIOME_ID]:
			Globals.Biome_ID.WOODS:
				var polar = neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.POLAR)
				if polar.size() > 0:
					t.biome = Globals.Biomes["Taiga"]
			#grassland -> steppe
			#any forest near desert -> scrubland
			#ocean -> sea ice
		t.update()
	print("adjusting complete")


func generate_terrain_old(current:Tile):
	var allow_desert = true
	var allow_forests = true
	var neighbours:Array = current.get_overlapping_areas()
	var adjacent_terrain:Array = []
	var terrain_chance:Array = []
	# find all of the surrounding terrain
	for t in neighbours:
		adjacent_terrain.append(t.biome[BIOME_ID])
	if adjacent_terrain.has(1):
		allow_forests = false
	if adjacent_terrain.has(4):
		allow_desert = false
	if adjacent_terrain.has(5):
		allow_desert = false
	# determine the current tile's terrain based on the surrounding terrain
	# undetermined tiles don't contribute to the calculation
	for at in adjacent_terrain:
		match at:
			Globals.Biome_ID.DEFAULT: # Don't add anything. Because the initial tile has a non-default biome, at least one neighbour must have
				# a legitimate tile ID
				pass
			Globals.Biome_ID.GRASSLAND: #Grassland: Grassland(65%), Desert(10%), Ocean(5%), Mountain(5%), Forest(15%)
				terrain_chance.append_array([0,0,0,0,0,0,0,0,0,0,0,0,0])
				if allow_desert:
					terrain_chance.append_array([1,1])
				else:
					terrain_chance.append_array([0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3])
				if allow_forests:
					terrain_chance.append_array([4,4,4])
			Globals.Biome_ID.DESERT: #Desert: Grassland(15%), Desert(60%), Ocean(5%), Mountain(20%)
				terrain_chance.append_array([0,0,0])
				if allow_desert:
					terrain_chance.append_array([1,1,1,1,1,1,1,1,1,1,1,1])
				else:
					terrain_chance.append_array([0,0,0,2,3,3,3,3,0,0,3,3])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3,3,3])
			Globals.Biome_ID.OCEAN: #Ocean: Grassland(5%), Desert(5%), Ocean(75%), Mountain(5%), Woods(5%), Rainforest(5%),
				terrain_chance.append_array([0])
				if allow_desert:
					terrain_chance.append_array([1])
				else:
					terrain_chance.append_array([0])
				terrain_chance.append_array([2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2])
				terrain_chance.append_array([3])
				if allow_forests:
					terrain_chance.append_array([4])
				else:
					terrain_chance.append_array([0])
			Globals.Biome_ID.MOUNTAIN: #Mountain: Grassland(5%), Desert(10%), Ocean(5%), Mountain(60%), Forest(10%),
				if allow_desert:
					terrain_chance.append_array([1,1])
				else:
					terrain_chance.append_array([0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3,3,3,3,3,3,3,3,3,3,3])
				if allow_forests:
					terrain_chance.append_array([4,4])
				else:
					terrain_chance.append_array([0,0])
			Globals.Biome_ID.WOODS: #Woods: Grassland(10%), Desert(0), Ocean(5%), Mountain(10%), Forest(75%)
				terrain_chance.append_array([0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3])
				if allow_forests:
					terrain_chance.append_array([4,4,4,4,4,4,4,4,4,4,4,4,4,4])
			Globals.Biome_ID.RAINFOREST: #Rainforest: Grassland(15%), Desert(0), Ocean(5%), Mountain(10%), Forest(70%)
				terrain_chance.append_array([0,0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3])
				if allow_forests:
					terrain_chance.append_array([5,5,5,5,5,5,5,5,5,5,5,5,5,5])
			Globals.Biome_ID.POLAR: #Polar: 
				terrain_chance.append_array([0,0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3])
				if allow_forests:
					terrain_chance.append_array([4])
				#terrain_chance.append_array([6,6,6,6,6,6,6,6,6,6,6,6,6])
			_:
				pass
	var picked_biome = terrain_chance.pick_random()
	if picked_biome == 5 and (current.id.y < (parameters.dimensions.y/3.0) or current.id.y > (parameters.dimensions.y / 3.0 * 2.0)):
		picked_biome = 4
	elif picked_biome == 4 and (current.id.y > (parameters.dimensions.y/3.0) and current.id.y < (parameters.dimensions.y / 3.0 * 2.0)):
		picked_biome = 5
	if picked_biome != 2 and (current.id.y < (parameters.dimensions.y/6.0) or current.id.y > (parameters.dimensions.y / 6.0 * 5.0)):
		picked_biome = 6
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
		6:
			key = "Polar"
	current.biome = Globals.Biomes[key]
	current.update()
	for t in neighbours:
		if t.biome[BIOME_ID] == -1:
			generate_terrain_old(t)
	

#func get_neighbours(current:Tile):
	#var neighbours:Array = []
	#if current.id.x % 2:
		#pass
	#else:
		#for t in tiles:
			#if t.id.x 
