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
	"Diet" : 10
}

var food_need:float
var water_need:float
var love_need:float


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


func _ready():
	base_activity_level = pow(genes["speed"], 1.5)
	activity_level = base_activity_level + genes["Perception"]
	
	base_metabolic_rate = pow(genes["Size"], 0.75)
	metabolic_rate = base_metabolic_rate * activity_level / normaliser
	
	diet_modifier = calculate_diet_modifier()
	pass

func _process(delta):
	pass

func process_turn():
	pass

# 1.0 for herbivores, 0.5 for carnivores (over 70% meat diet)
func calculate_diet_modifier() -> float:
	
	return 1.0
