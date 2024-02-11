class_name World
extends Node2D



@export var dimensions:Vector2i = Vector2i(10,10):
	set(val):
		dimensions = val
@export var noise:FastNoiseLite


var tile_scene:PackedScene = preload("res://scenes/tile2/tile.tscn")


const BIOME_ID = 0
const BIOME_NAME = 1
const BIOME_COLOR = 2

## Latitude ratios
const POLAR_N = 0.1
const POLAR_S = 1.0
const TEMPERATE_N = 0.3
const TEMPERATE_S = 0.9
const DRY_N = 0.4
const DRY_S = 0.7
const TROPICAL = 0.6

var pol_n 
var temp_n 
var dry_n 
var tropic 
var dry_s 
var temp_s 
var pol_s 


## Generation parameters
var continent_spread = 3
var land_seeds = 5

## Tile groups
var tiles:Array
var land:Array
var ocean:Array


func generate_world_tiles():
	var offset:bool = false
	for j in dimensions.y:
		for i in dimensions.x:
			var tile = tile_scene.instantiate() as Tile
			tile.global_position.x = 150 + i * 225 
			if offset:
				tile.global_position.y = 130 + j * 260
			else:
				tile.global_position.y = 260 + j * 260
			tile.id = Vector2i(i,j)
			tile.w_dimensions = dimensions
			$Tiles.add_child(tile)
			offset = !offset
	$Tiles.scale = Vector2(0.5, 0.5)
	tiles = $Tiles.get_children()

func reset():
	for t in tiles:
		t.reset()
	#land.clear()
	#ocean.clear()
	#mountains.clear()
	#rivers.clear()
	#river_sources.clear()


func update_tiles():
	for t in tiles:
		t.update()


func generate_world_terrain():
	
	# 1) Create mountains
	for t in tiles:
		t.reset()
	_generate_elevation()
	_generate_rivers()
	
	for t in tiles:
		t.generate()
	
	
	#_generate_temps()
	
	#_generate_precipitation()
	
	#_generate_biomes()
	
	update_tiles()


func _generate_elevation():
	print("calculating elevation")
	var val
	for t in tiles:
		#t.altitude = adjusted_elevation(t, val)
		
		t.altitude = raw_elevation(t,val)
		if t.altitude < 0:
			t.collision_layer += 4
			t.biome = Globals.Biomes["Ocean"]
		
	for t in tiles:
		t.calc_downhill()
	print("elevation complete")

func adjusted_elevation(t, val):
		# normalise raw noise values
		return (noise.get_noise_2dv(t.id * 5) + 1) * 500

func raw_elevation(t, val):
	return noise.get_noise_2dv(t.id * 5) * 1000


func _generate_rivers():
	print("calculating rivers")
	var tiles_elevation = tiles.duplicate()
	tiles_elevation.sort_custom(func(a,b): return a.altitude > b.altitude)
	for t in tiles_elevation:
		t.river_flow()
	#var tiles_river_size = tiles.duplicate()
	#tiles_river_size.sort_custom(func(a,b): return a.water_access > b.water_access)
	#for i in range(0,5):
		#for t in tiles_river_size:
			#if t.altitude == 0:
				#t.equalise_water_levels()
	print("rivers complete")



func _generate_temps():
	print("calculating temperature")
	for t in tiles:
		t.calc_temp()
	
	print("temperatures complete")


func _generate_precipitation():
	print("calculating precipitation")
	for t in tiles:
		t.calc_precip()
	
	print("precipitation complete")


func _generate_biomes():
	print("calculating biomes")
	for t in tiles:
		t.calc_biome()
