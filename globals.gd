## Rainfall: https://earthobservatory.nasa.gov/biome/biograssland.php
##


extends Node

const POLAR_N = 0.1
const POLAR_S = 0.9

const TEMPERATE_N = 0.3
const TEMPERATE_S = 0.7

const DRY_N = 0.4
const DRY_S = 0.6

#const TROPICAL = 0.6

const BIOME_ID = 0
const BIOME_NAME = 1
const BIOME_COLOR = 2


const scale_factor = 0.01

const MALE = 0
const FEMALE = 1

var river_counter = 0

# Id, Name, Color, Base_Food,
var Biomes = {
	"Default" : [-1, "Default", Color(1, 1, 1, 1), 0.0],
	"Grassland" : [0, "Grassland", Color.OLIVE, 100],
	"Desert" : [1, "Desert", Color(0.94, 0.89, 0.69, 1), 1],
	"Ocean" : [2, "Ocean", Color(0.15, 0.29, 0.60, 1), 0],
	"Mountain" : [3, "Mountain", Color(0.5, 0.5, 0.5, 1), 1], 
	"Woods" : [4, "Woods", Color(0.0, 0.5, 0.25, 1), 100.0],
	"Rainforest" : [5, "Rainforest", Color(0.0, 0.35, 0.0, 1), 100],
	"Polar": [6, "Polar", Color(1.0, 1.0, 1.0, 1), 1],
	"Steppe": [7, "Steppe", Color(0.56, 0.61, 0.41, 1), 70],
	"Swamp": [8, "Swamp", Color(0.24, 0.38, 0.13, 1), 70],
	"Taiga" : [9, "Taiga", Color.SEA_GREEN, 20],
	"Scrubland" : [10, "Scrubland", Color(0,0.8,0.4, 1), 20],
	"Floodplain" : [11, "Floodplain", Color(0.94, 0.89, 0.69, 1), 70],
	"Sea Ice" : [12, "Sea Ice", Color.LIGHT_SKY_BLUE, 0],
	"Savannah" : [13, "Savannah", Color(0.46, 0.81, 0.24, 1), 100],
	"TempRainforest" : [14, "TempRainforest", Color.FOREST_GREEN, 100]
}

# Base_Food currently exists at several distinct levels
# Trivial access (100.0) - vegetation is abundant: Woods, Rainforest, Grassland
# Easy access (70.0) - poor quality vegetation is abundant, or high quality vegetation is patchy: Steppe, Swamp, Floodplain
# Middling access (40.0)- vegetation exists, but isn't great quality: Taiga, Scrubland 
# Difficult access (10.0) - vegetation is scarce: Desert, Polar, Mountain

var Regions_base_temp = {
	"Polar" : -10,
	"Temperate" : 15,
	"Dry" : 15,
	"Tropic" : 20
}


enum Biome_ID {
	DEFAULT = -1,
	GRASSLAND,
	DESERT,
	OCEAN,
	MOUNTAIN,
	WOODS,
	RAINFOREST,
	POLAR,
	STEPPE,
	SWAMP,
	TAIGA,
	SCRUBLAND,
	FLOODPLAIN
}

#var Biome = {
	#ID: 
#}


func coin_flip():
	return true if randi_range(0,1) else false
