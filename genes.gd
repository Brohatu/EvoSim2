extends Resource

class_name Genes

# TODO: make genes a dictionary
@export var genes = {
	"Size" : 50,
	"Speed" : 10,
	"Senses" : 10,
	"Diet" : 10,
	"Maturity" : 50
}
var size:int
#0 is obligate herbivore, 99 is obligate carnivore
@export_range(0, 99) var diet:int = 0
var fertility:int
var senses:int
var food_need:int
var lifespan:int = 1000
var sexual_maturity:int = 150
var female:bool = true
var speed:int = 20



func mix_parents(mum, dad):
	size = mum.size if randi_range(0,1) else dad.size
	fertility = mum.fertility if randi_range(0,1) else dad.fertility
	senses = mum.senses if randi_range(0,1) else dad.senses
	lifespan = mum.lifespan if randi_range(0,1) else dad.lifespan
	sexual_maturity = mum.sexual_maturity if randi_range(0,1) else dad.sexual_maturity
	female = true if randi_range(0,1) else false


func mutate():
	var mutate_chances = []
	mutate_chances.resize(8)
	for i in range(0,8):
		mutate_chances[i] = randi_range(0,2)
	if mutate_chances[0]:
		if randi_range(0,1):
			size += 0.1
		else:
			size -= 0.1
	if mutate_chances[1]:
		if randi_range(0,1):
			diet = min(99, diet+1)
		else:
			diet = max(0, diet-1)
	if mutate_chances[2]:
		if randi_range(0,1):
			fertility *= (4.0/3.0)
		else:
			fertility *= (2.0/3.0)
	if mutate_chances[3]:
		if randi_range(0,1):
			senses += 1
		else:
			senses -= 1
	if mutate_chances[4]:
		if randi_range(0,1):
			lifespan += randi_range(1,10)
		else:
			lifespan -= randi_range(1,10)
	if mutate_chances[5]:
		if randi_range(0,1):
			sexual_maturity += randi_range(1,3)
		else:
			sexual_maturity -= randi_range(1,3)
