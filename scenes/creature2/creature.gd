extends Node2D


#Stats
	#Mass 
	#speed
	#perception
	#
	#food need
	#water need
	#love need
var genes = {
	"Size" : 50,
	"Speed" : 10,
	"Senses" : 10,
	"Diet" : 10,
	"Maturity" : 50
}

var age:int = 0

const FOOD = 0
const WATER = 1
const LOVE = 2
var needs = [0,0,0]
var food_need:int = 0
var water_need:int = 0
var love_need:int = 0

var sexual_maturity:bool = false


#baseActivityLevel = speed^1.5
#activityLevel = baseActivityLevel + perception
#
#baseMetabolicRate = mass^(0.75)
#normaliser = 9000
#metabolicRate = baseMetabolicRate * activityLevel / normaliser
#
#dietModifier = #carnivores get hungry slower
#
#food need = y per tick
#water need = 2 * food need

var base_activity_level
var activity_level

var base_metabolic_rate
var normaliser = 9000
var metabolic_rate

var diet_modifier:float
var food_increment:float
var water_increment:float


func _ready():
	base_activity_level = pow(genes["speed"], 1.5)
	activity_level = base_activity_level + genes["Perception"]
	
	base_metabolic_rate = pow(genes["Size"], 0.75)
	metabolic_rate = base_metabolic_rate * activity_level / normaliser
	
	diet_modifier = calculate_diet_modifier()
	food_increment = metabolic_rate/diet_modifier
	water_increment = food_increment * 2.0
	
	needs = [food_need, water_need, love_need]


func _process(delta):
	pass

func process_turn():
	if food_need > 100.0 or water_need > 100.0:
		die()
	else:
		age += 1
		
		if age == genes["Maturity"]:
			sexual_maturity = true
		
		if sexual_maturity:
			love_need += 1
		else:
			if age == genes["Maturity"]:
				sexual_maturity = true
		
		food_need += food_increment
		water_need += water_increment
		
		var action = determine_needs_priority()
		
		
	

# 1.0 for herbivores, 0.5 for carnivores (over 70% meat diet)
func calculate_diet_modifier() -> float:
	
	return 1.0

func determine_needs_priority() -> int:
	if needs[FOOD] > needs[WATER] and needs[FOOD] > needs[LOVE]:
		return FOOD
	elif needs[WATER] > needs[LOVE]:
		return WATER
	else:
		return LOVE

func die():
	pass
