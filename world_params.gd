extends Resource

class_name WorldParameters

@export var dimensions:Vector2i = Vector2i(30,20):
	set(val):
		dimensions = val

@export var land_seeds:int = 5
@export var continent_spread = 3
@export var mountain_seeds:int = 5
@export var rain_dropoff:float = 0.18
@export var forest_precip = 20.0
@export var grassland_precip = 10
@export var desert_precip = 3
@export var tropic_factor = 0.5
@export var dry_factor = 1.3
