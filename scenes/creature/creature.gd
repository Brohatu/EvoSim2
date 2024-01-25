extends Area2D

class_name Creature

signal creature_data(creature)
signal birth(baby,loc)

const BIOME_ID = 0

enum Need {
	NONE,
	WATER,
	FOOD,
	SEX
}

enum Action {
	EAT,
	DRINK,
	MATE,
	MOVE,
	REST
}

@export var genes:Genes
var location:Tile:
	set(val):
		location = val
		global_position = val.global_position

# energy consumption rules:
#	existing costs 1 hunger per turn
#	moving costs 2 hunger per turn
#	mating costs 1 hunger per turn
#	being pregnant costs 1 hunger per turn
var hunger:int = 50
var thirst:int = 50

var horniness:int = 0
var ptn_mates:Array
var pregnant = [false, 0, null]

var need:Need
var action:Action
var move_target:Tile

@export var age:int = 0
var highlighted:bool = false

func _ready():
	genes = Genes.new()
	genes.female = bool(randi_range(0,1))

func _process(_delta):
	if Input.is_action_just_pressed("select") and highlighted:
		creature_data.emit(self)


#Turn start:
	#determine highest priority need (water, food, sex)
	#if water:
		#if river or coast:
			#drink()
		#else:
			#target = check_adjacent(water)
			#move(target)
	#elif food:
		#if food_available:
			#eat()
		#else:
			#target = check_adjacent(food)
			#move(target)
	#elif sex:
		#signal_available()
		#if mate_available:
			#mate()
		#else:
			#target = check_adjacent(signal)
			#move(signal)

func process_turn():
	age += 1
	
	if age >= genes.sexual_maturity:
		if genes.female:
			location.scent_female += 10
			if !pregnant[0]:
				horniness = min(100, horniness + 1)
			else:
				if pregnant[1] > 0:
					pregnant[1] -= 1
				else:
					birth.emit(pregnant[2],location)
					pregnant[0] = false
		else:
			location.scent_male += 10
			horniness = min(100, horniness + 1)
	else:
		scale = Vector2(0.3,0.3) * age/genes.sexual_maturity
	
	# check death conditions
	check_death()
	
	need = determine_needs()
	action = execute_action()
	
	match action:
		Action.EAT:
			eat()
		Action.MATE:
			mate()
		Action.MOVE:
			move()
		
	consume_energy()
	



func check_death():
	if hunger > 100.0:
		die()
	if age >= genes.lifespan:
		die()


func determine_needs() -> Need:
	# ignore thirst for now
	if hunger > 10:
		return Need.FOOD
	elif horniness > 20:
		return Need.SEX
	return Need.NONE


func execute_action() -> Action:
	match need:
		Need.FOOD:
			if location.vegetation > hunger:
				return Action.EAT
			else:
				move_target = sense()
				if move_target == location:
					return Action.EAT
				else:
					return Action.MOVE
		Need.SEX:
			if not genes.female:
				ptn_mates = location.get_creatures().filter(func(c:Creature): return c.genes.female and c.horniness > 20)
				if ptn_mates:
					return Action.MATE
				else:
					move_target = sense()
					if move_target == location:
						return Action.REST
					else:
						return Action.MOVE
			else:
				ptn_mates = location.get_creatures().filter(func(c:Creature): return !c.genes.female and c.horniness > 20)
				if ptn_mates:
					# Only males initiate mating code. Interested females will wait in position.
					# This makes mating code more consistent
					return Action.REST
				else:
					move_target = sense()
					if move_target == location:
						return Action.REST
					else:
						return Action.MOVE
		_: 
			return Action.REST


func sense() -> Tile:
	var targets = location.get_overlapping_tiles().filter(func(t): return t.biome[BIOME_ID] != Globals.Biome_ID.OCEAN and t.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN)
	var target:Tile
	
	if need == Need.FOOD:
		var food_targets = targets.filter(func(t): return t.vegetation > location.vegetation)
		if food_targets:
			target = food_targets.pick_random()
			return target
		return targets.pick_random()
		
	if need == Need.SEX:
		if genes.female:
			targets.sort_custom(func(t1, t2): return t1.scent_male > t2.scent_male)
			targets = targets.filter(func(t): return t.scent_male == targets[0].scent_male)
		else:
			targets.sort_custom(func(t1, t2): return t1.scent_female > t2.scent_female)
			targets = targets.filter(func(t): return t.scent_female == targets[0].scent_female)
		target = targets.pick_random()
		return target
	return location


func impregnate(c:Creature):
	c.pregnant[0] = true
	c.pregnant[1] = 10	#TODO: add gestation period to genes
	var baby_genes = Genes.new()
	baby_genes.mix_parents(c.genes, genes)
	baby_genes.mutate()
	c.pregnant[2] = baby_genes


func mate():
	var c:Creature = ptn_mates.pick_random()
	horniness -= 20
	c.horniness = 0
	impregnate(c)


func reproduce_old():
	var chance = randi_range(0, 100)
	if chance <= 2:
		birth.emit(self)
		hunger += 50

func die():
	location.carrion += 110.0 - hunger
	queue_free()


func move():
	location = move_target


func move_random():
	var coin_flip = randi_range(0,1)
	if coin_flip:
		var move_options = location.get_overlapping_tiles().filter(func(option:Tile): return option.biome[BIOME_ID] != Globals.Biome_ID.OCEAN and option.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN)
		location = move_options.pick_random()
		hunger += 2
	else:
		hunger += 1

func move_old():
	var options = location.get_overlapping_tiles()
	var target = options.pick_random()
	location = target
	position = location.global_position

# energy consumption rules:
#	existing costs 1 hunger per turn
#	moving costs 2 hunger per turn
#	mating costs 1 hunger per turn
#	being pregnant costs 1 hunger per turn
func consume_energy():
	var used = 1
	if action == Action.MOVE:
		used += 2
	if action == Action.MATE:
		used += 1
	if pregnant:
		used += 1
	hunger += used


func eat_old():
	var available = location.vegetation
	var eaten = min(available, 5)
	if eaten > 0:
		location.vegetation -= eaten
		hunger -= eaten

func eat():
	var available = location.vegetation
	var eaten = min(available, hunger)
	if eaten:
		location.vegetation -= eaten
		hunger -= eaten


func _on_mouse_entered():
	highlighted = true


func _on_mouse_exited():
	highlighted = false
