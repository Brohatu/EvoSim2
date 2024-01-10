extends Node2D

class_name World

var tile_scene:PackedScene = preload("res://scenes/tile/tile.tscn")

const BIOME_ID = 0
const BIOME_NAME = 1
const BIOME_COLOR = 2
const BIOME_BASE_FOOD = 3
const BIOME_RAINFALL = 4

@export var parameters:WorldParameters

var tiles:Array

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
	
	var initial = tiles.pick_random() as Tile
	
	initial.random_biome()
	var neighbours:Array = initial.get_overlapping_areas()
	for t in neighbours:
		generate_terrain(t)
		
	#generate_terrain(initial)


func generate_terrain(current:Tile):
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
			-1: # Don't add anything. Because the initial tile has a non-default biome, at least one neighbour must have
				# a legitimate tile ID
				pass
			0: #Grassland: Grassland(65%), Desert(10%), Ocean(5%), Mountain(5%), Forest(15%)
				terrain_chance.append_array([0,0,0,0,0,0,0,0,0,0,0,0,0])
				if allow_desert:
					terrain_chance.append_array([1,1])
				else:
					terrain_chance.append_array([0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3])
				if allow_forests:
					terrain_chance.append_array([4,4,4])
			1: #Desert: Grassland(15%), Desert(60%), Ocean(5%), Mountain(20%)
				terrain_chance.append_array([0,0,0])
				if allow_desert:
					terrain_chance.append_array([1,1,1,1,1,1,1,1,1,1,1,1])
				else:
					terrain_chance.append_array([0,0,0,2,3,3,3,3,0,0,3,3])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3,3,3])
			2: #Ocean: Grassland(5%), Desert(5%), Ocean(75%), Mountain(5%), Woods(5%), Rainforest(5%),
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
			3: #Mountain: Grassland(5%), Desert(10%), Ocean(5%), Mountain(60%), Forest(10%),
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
			4: #Woods: Grassland(10%), Desert(0), Ocean(5%), Mountain(10%), Forest(75%)
				terrain_chance.append_array([0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3])
				if allow_forests:
					terrain_chance.append_array([4,4,4,4,4,4,4,4,4,4,4,4,4,4])
			5: #Rainforest: Grassland(15%), Desert(0), Ocean(5%), Mountain(10%), Forest(70%)
				terrain_chance.append_array([0,0,0])
				terrain_chance.append_array([2])
				terrain_chance.append_array([3,3])
				if allow_forests:
					terrain_chance.append_array([5,5,5,5,5,5,5,5,5,5,5,5,5,5])
	var picked_biome = terrain_chance.pick_random()
	if picked_biome == 5 and (current.id.y < (parameters.dimensions.y/3.0) or current.id.y > (parameters.dimensions.y / 3.0 * 2.0)):
		picked_biome = 4
	elif picked_biome == 4 and (current.id.y > (parameters.dimensions.y/3.0) and current.id.y < (parameters.dimensions.y / 3.0 * 2.0)):
		picked_biome = 5
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
	for t in neighbours:
		if t.biome[BIOME_ID] == -1:
			generate_terrain(t)
	

#func get_neighbours(current:Tile):
	#var neighbours:Array = []
	#if current.id.x % 2:
		#pass
	#else:
		#for t in tiles:
			#if t.id.x 
