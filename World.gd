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

# all tiles on the map
var tiles:Array
# all land tiles
var land:Array
# all sea tiles
var ocean:Array
# mountain tiles
@export var mountains:Array
# river objects
@export var rivers:Array
@export var river_sources:Array


var pol_n 
var temp_n 
var dry_n 
var tropic 
var dry_s 
var temp_s 
var pol_s 

func reset():
	for t in tiles:
		t.reset()
	land.clear()
	ocean.clear()
	mountains.clear()
	rivers.clear()
	river_sources.clear()
	
	#generate_new_world()
	#generate_world_terrain()




func generate_world_tiles():
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
	land = []
	# all tiles are ocean tiles at generation start
	ocean = tiles.duplicate()
	# 1) determine whether tile is land or ocean
	print("placing landmasses")
	generate_continents()
	print("placing landmasses complete")
	
	# 2) determine temperature region borders
	pol_n = parameters.dimensions.y * POLAR_N # eg 20 * 0.1 = 2
	temp_n = parameters.dimensions.y * TEMPERATE_N
	dry_n = parameters.dimensions.y * DRY_N
	tropic = parameters.dimensions.y * TROPICAL
	dry_s = parameters.dimensions.y * DRY_S
	temp_s = parameters.dimensions.y * TEMPERATE_S
	pol_s = parameters.dimensions.y
	
	# 3) determine height of land tiles
	print("generating mountains")
	generate_mountains()
	print("generating mountains complete")
	# 4) determine precipitation levels and rivers
	print("generating rivers")
	generate_rivers()
	print("generating rivers complete")
	print("generating rainfall")
	generate_precipitation()
	print("generating rainfall complete")
	
	## 5) apply appropriate terrain based on precipitation and latitude
	print("calculating biomes")
	generate_biomes()
	print("calculating biomes complete")
	## 6) adjust biomes according rivers etc
	print("adjusting")
	adjust_biomes()
	print("adjusting complete")



func spread_land(count:int, tile:Tile):
	print("Spread level: ", count)
	if tile.id.x > 0 and tile.id.x < parameters.dimensions.x - 1:
		tile.biome = Globals.Biomes["Default"]
		tile.update()
		land.append(tile)
		ocean.erase(tile)
		var neighbours = tile.get_overlapping_areas()
		# check size of neighbours when trimming
		var trim:int = randi_range(0,min(3,neighbours.size()))
		
		for j in range(trim):
			var remove = neighbours.pick_random()
			neighbours.erase(remove)
		# for t in neighbours
			# t.biome is land
		if neighbours.size()>0:
			for t in neighbours:
				if t.biome[BIOME_ID] == Globals.Biome_ID.OCEAN:
					t.biome = Globals.Biomes["Default"]
					t.update()
					land.append(t)
					var new_count = count - 1
					if new_count > 0:
						spread_land(new_count,t) # double check how decrementing is working


func generate_continents():
	var count = parameters.continent_spread
		# select x random tiles
	for i in range(0, parameters.land_seeds):
		var land_seed:Tile = tiles.pick_random() as Tile
		while land_seed.biome[BIOME_ID] != Globals.Biome_ID.OCEAN or (land_seed.id.x <= 0):
			land_seed = tiles.pick_random() as Tile
		# x.biome = land
		ocean.erase(land_seed)
		spread_land(count, land_seed)
		
		#land_seed.biome = Globals.Biomes["Default"]
		#land_seed.update()
		#build_arr.append(land_seed)
		#
		## get x neighbours
		#var neighbours = land_seed.get_overlapping_areas()
		#var trim:int = randi_range(0,2)
		#for j in range(trim):
			#var remove = neighbours.pick_random()
			#neighbours.erase(remove)
		## for t in neighbours
			## t.biome is land
		#for t in neighbours:
			#t.biome = Globals.Biomes["Default"]
			#t.update()
			#build_arr.append(t)


## Mountain ranges are created by seeding a given number of tiles and walking 
## from tile to tile for a given number of steps.
## If they walk onto an ocean tile, turn the ocean tile into a default tile.
func generate_mountains():
	var counter:int
	for i in range(0, parameters.mountain_seeds):
		counter = randi_range(2,5)
		var mountain_seed = land.pick_random() as Tile
		while mountain_seed.biome[BIOME_ID] != Globals.Biome_ID.DEFAULT:
			mountain_seed = land.pick_random() as Tile
		mountain_seed.biome = Globals.Biomes["Mountain"]
		mountain_seed.update()
		mountains.append(mountain_seed)
		if counter > 0:
			walk_mountain(mountain_seed, counter)


func walk_mountain(mountain:Tile, counter:int):
	counter -= 1
	var neighbours = mountain.get_overlapping_areas()
	var next_mountain = neighbours.pick_random()
	if next_mountain.biome[BIOME_ID] == Globals.Biome_ID.OCEAN:
		next_mountain.biome = Globals.Biomes["Default"]
		land.append(next_mountain)
		ocean.erase(next_mountain)
		next_mountain.update()
	elif next_mountain.biome[BIOME_ID] == Globals.Biome_ID.MOUNTAIN:
		pass
	else:
		next_mountain.biome = Globals.Biomes["Mountain"]
		mountains.append(next_mountain)
		ocean.erase(next_mountain)
		next_mountain.update()
	
	if counter > 0:
		walk_mountain(next_mountain, counter)



func generate_rivers():
	if mountains:
		for i in range(0, mountains.size()/2):
			var m = mountains.pick_random()
			while m.has_river:
				m = mountains.pick_random()
			var new_river = River.new()
			var valid_river = new_river.begin(m)
			if valid_river:
				rivers.append(new_river)
				for t:Tile in new_river.river_tiles:
					t.has_river = true
					if t.river_sources:
						for src in t.river_sources:
							src.river_sink = t
					else:
						river_sources.append(t)
					t.update()
	
	for src:Tile in river_sources:
		src.river_volume = 5.0
		if src.river_sink:
			src.river_sink.update_river()
		src.update()



func generate_rivers_old():
	for i in range(0, parameters.mountain_seeds):
		var m = mountains.pick_random()
		while m.has_river:
			m = mountains.pick_random()
		var neighbours = m.get_overlapping_areas()
		if neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN):
			var new_river = River.new()
			new_river.step_2(m,null)
			rivers.append(new_river)
	for r:River in rivers:
		for t:Tile in r.river_tiles:
			
			t.update()

func walk_river(current:Tile):
	var neighbours = current.get_overlapping_areas()
	var river_out:Tile = neighbours.pick_random()
	while river_out.biome[BIOME_ID] == Globals.Biome_ID.MOUNTAIN:
		neighbours.erase(river_out)
		if neighbours.size() > 0:
			river_out = tiles.pick_random() as Tile
	if river_out == null:
		pass
	elif river_out.biome[BIOME_ID] == Globals.Biome_ID.OCEAN:
		pass
	else:
		river_out.has_river = true
		#river_out.river_size += 1
		river_out.update()
		walk_river(river_out)


func generate_precipitation():
	print("generating ocean rainfall")
	# get a copy of all tiles to assign rainfall
	var rain_tiles = tiles.duplicate()
	
	# give ocean tiles 100% rainfall and remove them from rain_tiles
	# remove mountains from rain_tiles
	for t:Tile in tiles:
		if t.biome[BIOME_ID] == Globals.Biome_ID.OCEAN:
			t.precip = 100.0
			t.update()
			rain_tiles.erase(t)
		elif t.biome[BIOME_ID] == Globals.Biome_ID.MOUNTAIN:
			t.precip = 0.0
			t.update()
			rain_tiles.erase(t)
	print("generating ocean rainfall complete")
	
	# get coastal precip
	print("generating coastal rainfall")
	var neighbours:Array
	for t:Tile in tiles:
		if t.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN and t.biome[BIOME_ID] != Globals.Biome_ID.OCEAN:
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
	print("generating coastal rainfall complete")
	
	# get precip for inner layers from coast
	print("generating inland rainfall")
	while rain_tiles.size() > 0:
		for t:Tile in rain_tiles:
			var precip_val = 0.0
			neighbours = t.get_overlapping_areas()
			for n:Tile in neighbours:
				precip_val += n.precip * parameters.rain_dropoff
			t.precip_temp = precip_val
		for t:Tile in tiles:
			if rain_tiles.has(t):
				if t.precip_temp != 0:
					t.precip += t.precip_temp
					#t.precip_temp = 0
					rain_tiles.erase(t)
				elif not neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN):
					rain_tiles.erase(t)
				t.update()
				
	print("generating inland rainfall complete")


func generate_biomes():
	for t:Tile in land:
		if t.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN:
			var lat = t.id.y
			
			# polar: polar, taiga
			if lat < pol_n:
				if t.water_access >= parameters.forest_precip * 1.5:
					t.biome = Globals.Biomes["Taiga"]
				else:
					t.biome = Globals.Biomes["Polar"]
			
			
			# temperate: woods, grassland, steppe, desert, (swamp, floodplains)
			elif lat < temp_n:
				if t.precip > parameters.forest_precip:
					t.biome = Globals.Biomes["Woods"]
				elif t.precip > parameters.grassland_precip:
					t.biome = Globals.Biomes["Grassland"]
				elif t.precip > parameters.desert_precip:
					t.biome = Globals.Biomes["Steppe"]
				else:
					t.biome = Globals.Biomes["Desert"]
			
			
			# dry: scrubland, grassland, desert, floodplains
			elif lat < dry_n:
				if t.precip > parameters.forest_precip * parameters.dry_factor:
					t.biome = Globals.Biomes["Scrubland"]
				elif t.precip > parameters.grassland_precip * parameters.dry_factor:
					t.biome = Globals.Biomes["Steppe"]
				else:
					t.biome = Globals.Biomes["Desert"]
			
			
			# tropical: rainforest, swamp, grassland
			elif lat < tropic:
				if t.precip > parameters.forest_precip * parameters.tropic_factor:
					t.biome = Globals.Biomes["Rainforest"]
				elif t.precip > parameters.grassland_precip * parameters.tropic_factor:
					if t.water_access > parameters.forest_precip * parameters.tropic_factor:
						t.biome = Globals.Biomes["Swamp"]
					else:
						t.biome = Globals.Biomes["Grassland"]
				elif t.precip > parameters.desert_precip * parameters.tropic_factor:
					t.biome = Globals.Biomes["Scrubland"]
				else:
					t.biome = Globals.Biomes["Steppe"]
			
			
			
			# dry: scrubland, grassland, desert, floodplains
			elif lat < dry_s:
				if t.precip > parameters.forest_precip * parameters.dry_factor:
					t.biome = Globals.Biomes["Scrubland"]
				elif t.precip > parameters.grassland_precip * parameters.dry_factor:
					t.biome = Globals.Biomes["Steppe"]
				#elif t.precip > parameters.desert_precip * parameters.dry_factor:
						#t.biome = Globals.Biomes["Desert"]
				else:
					t.biome = Globals.Biomes["Desert"]
			
			
			# temperate: woods, grassland, steppe, desert, (swamp, floodplains)
			elif lat < temp_s:
				if t.precip > parameters.forest_precip:
					t.biome = Globals.Biomes["Woods"]
				elif t.precip > parameters.grassland_precip:
					t.biome = Globals.Biomes["Grassland"]
				elif t.precip > parameters.desert_precip:
					t.biome = Globals.Biomes["Steppe"]
				else:
					t.biome = Globals.Biomes["Desert"]
			
			
			# polar: polar, taiga
			elif lat < pol_s:
				if t.water_access >= parameters.forest_precip * 1.5:
					t.biome = Globals.Biomes["Taiga"]
				else:
					t.biome = Globals.Biomes["Polar"]
		t.update()

func generate_biomes_old():
	var lat:float
	for t:Tile in land:
		if t.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN:
			lat = t.id.y
			
			# polar: 
			# always polar biome
			if lat < pol_n:
				#t.determine_biome()
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
				if t.precip > parameters.forest_precip * parameters.dry_factor:
					t.biome = Globals.Biomes["Woods"]
				elif t.precip > parameters.grassland_precip * parameters.dry_factor:
					t.biome = Globals.Biomes["Grassland"]
				else:
					if t.water_access > parameters.grassland_precip * parameters.dry_factor:
						t.biome = Globals.Biomes["Scrubland"]
					else:
						t.biome = Globals.Biomes["Desert"]
			# tropical:
			# values are reduce by a factor
			elif lat < tropic:
				if t.precip > parameters.forest_precip * parameters.tropic_factor:
					t.biome = Globals.Biomes["Rainforest"]
				elif t.precip > parameters.grassland_precip * parameters.tropic_factor:
					t.biome = Globals.Biomes["Grassland"]
				else:
					t.biome = Globals.Biomes["Desert"]
			elif lat < dry_s:
				if t.precip > parameters.forest_precip * parameters.dry_factor:
					t.biome = Globals.Biomes["Woods"]
				elif t.precip > parameters.grassland_precip * parameters.dry_factor:
					t.biome = Globals.Biomes["Grassland"]
				else:
					if t.water_access > parameters.grassland_precip * parameters.dry_factor:
						t.biome = Globals.Biomes["Scrubland"]
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

func adjust_biomes():
	for t:Tile in tiles:
		
		#var neighbours = t.get_overlapping_areas()
		match t.biome[BIOME_ID]:
			#Globals.Biome_ID.WOODS:
				#var polar = neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.POLAR)
				#if polar.size() > 0:
					#t.biome = Globals.Biomes["Taiga"]
				#
				#var desert = neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.DESERT)
				#if desert.size() > 0:
					#t.biome = Globals.Biomes["Scrubland"]
			#grassland -> steppe
			#Globals.Biome_ID.GRASSLAND:
				#var polar = neighbours.filter(func(neighbour) : return neighbour.biome[BIOME_ID] == Globals.Biome_ID.POLAR)
				#if polar.size() > 0:
					#t.biome = Globals.Biomes["Steppe"]
			
			Globals.Biome_ID.DESERT:
				if t.has_river:
					t.biome = Globals.Biomes["Floodplain"]
			
			Globals.Biome_ID.STEPPE:
				if t.has_river:
					t.biome = Globals.Biomes["Grassland"]
			#any forest near desert -> scrubland
			#Globals.Biome_ID.Desert:
				
			#ocean -> sea ice
		t.update()




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
