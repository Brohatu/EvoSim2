extends Resource

class_name Genes


@export var size:float = 1
#0.0 is obligate herbivore, 10.0 is obligate carnivore
@export_range(0.0, 10.0) var diet:float = 1.0
@export var fertility:float
@export var senses:float
@export var food_need:float
@export var lifespan:int = 1000
@export var sexual_maturity:int = 150



func mutate():
	pass
