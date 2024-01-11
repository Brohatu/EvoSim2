## Rainfall: https://earthobservatory.nasa.gov/biome/biograssland.php
##
##
##
##
##


extends Node

# Id, Name, Color, Base_Food, Avg_Rainfall(mm)
var Biomes = {
	"Default" : [-1, "Default", Color(0,0,0), 0.0, 0.0],
	"Grassland" : [0, "Grassland", Color(0.46, 0.81, 0.24), 100.0, 700.0],
	"Desert" : [1, "Desert", Color(0.94, 0.89, 0.69), 10.0, 250.0],
	"Ocean" : [2, "Ocean", Color(0.15, 0.29, 0.60), 50.0, 0.0],
	"Mountain" : [3, "Mountain", Color(0.5, 0.5, 0.5), 50.0, 600.0], 
	"Woods" : [4, "Woods", Color(0.0, 0.5, 0.25), 100.0, 1000.0],
	"Rainforest" : [5, "Rainforest", Color(0.0, 0.35, 0.0), 100.0, 6000.0],
	"Polar": [6, "Polar", Color(1.0, 1.0, 1.0), 10.0, 0.0],
	# steppe: grassland next to polar
	# swamp: grassland next to lots of water or rainforest
	# taiga: woods next to polar
	"Taiga" : [9, "Taiga", Color(1.0,1.0,1.0), 60.0, 1000.0]
}

enum Biome_ID {
	DEFAULT = -1,
	GRASSLAND,
	DESERT,
	OCEAN,
	MOUNTAIN,
	WOODS,
	RAINFOREST,
	POLAR
}

#var Biome = {
	#ID: 
#}
