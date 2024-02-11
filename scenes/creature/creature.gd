class_name Creature
extends Area2D

### Signals
signal creature_data(creature)
signal birth(baby,loc)


### Enums
enum Action {
	EAT,
	DRINK,
	MATE,
	MOVE,
	REST,
	DEBUG
}


### Constants
const BIOME_ID = 0

const FOOD = 0
const WATER = 1
const LOVE = 2
const REST = 3


### Export variables
# equations are balanced around 100 being the average value
@export var genes = {
	"Size" : 100, 
	"Speed" : 100,
	"Senses" : 100,
	"Stealth" : 100,
	"Fertility" : 100,
	"Diet" : Diet.new(),
	"Maturity" : 50,
	"Lifespan" : 1000,
	"Female" : true
}


### Public variables
var location:Tile:
	set(val):
		location = val
		global_position = val.global_position

# Scent: Species, Age, Sex, isPregnant, 
var scent = {
	#species
	"Age" : 0,
	"Female" : true,
	"Pregnant" : false,
	"Strength" : 10
}

var age:int = 0

## Needs ##
# for food, 50 hunger is turning point between "gaining" and "losing" weight
# 	in the context of meat dropped
var food_need:float = 50.0
var water_need:float = 30.0
var love_need:float = 0.0



### Private variables
## Metabolism ##
var _food_increment
var _water_increment

## Reproduction ##
var _ptn_mates:Array
var pregnant = [false, 0, null]

## Turn processing ##
var need
var _action:Action
var _move_target

## State ##
var _highlighted:bool = false



###############################################################################
### Built-in methods
## Object creation methods ##
func _ready():
	genes["Female"] = bool(randi_range(0,1))
	scent["Age"] = age
	scent["Female"] = genes["Female"]
	scent["Pregnant"] = false
	
	var base_activity_level = pow(genes["Speed"], 1.5) # baseline: 100^1.5 = 1000
	var activity_level = base_activity_level + genes["Senses"] # baseline: 1000 + 100 = 1100
	
	var normaliser = 9000
	
	var base_metabolic_rate = pow(genes["Size"], 0.75) # baseline: 100^0.75 = 31.6
	var metabolic_rate = base_metabolic_rate * activity_level / normaliser # baseline: 31.6 * 1100 / 9000 = 3.87
	
	var diet_modifier = _calculate_diet_modifier()
	_food_increment = metabolic_rate/diet_modifier
	_water_increment = _food_increment * 2.0



## Runtime methods ##
func _process(_delta):
	if Input.is_action_just_pressed("select") and _highlighted:
		creature_data.emit(self)




###############################################################################
### Public methods
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
	# check death conditions
	_check_death()
	location.scent_list.append(scent)
	age += 1
	
	if age >= genes["Maturity"]:
		if genes["Female"]:
			if !pregnant[0]:
				love_need = min(20, love_need + 1)
			else:
				if pregnant[1] > 0:
					if food_need > 70:
						pregnant[0] = false
						pregnant[1] = 0
						pregnant[2] = 0
					else:
						pregnant[1] -= 1
				else:
					birth.emit(pregnant[2],location)
					food_need += 20
					pregnant[0] = false
		else:
			love_need = min(20, love_need + 1)
	else:
		scale = genes["Size"] * Vector2.ONE * (age/float(genes["Maturity"])) * Globals.scale_factor
	
	
	
	need = _determine_needs()
	_action = _execute_action()
	
	match _action:
		Action.EAT:
			_eat()
		Action.DRINK:
			_drink()
		Action.MATE:
			_mate()
		Action.MOVE:
			_move()
	
	food_need += _food_increment
	water_need += _water_increment




###############################################################################
### Private methods
## Turn stages ##
func _determine_needs() -> int:
	if water_need > food_need and water_need > love_need and water_need > 40:
		return WATER
	elif food_need > love_need and food_need > 40:
		return FOOD
	elif love_need > 10:
		return LOVE
	else:
		return REST


func _sense():
	
	pass


func _execute_action():
	
	pass




func _sense_old():
	var targets = location.get_overlapping_tiles().filter(func(t): return t.biome[BIOME_ID] != Globals.Biome_ID.OCEAN and t.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN)
	if not targets:
		return location
	
	var target
	
	if need == FOOD:
		var food_targets = targets.filter(func(t): return t.vegetation > location.vegetation)
		if food_targets:
			target = food_targets.pick_random()
			return target
		return targets.pick_random()
	
	if need == WATER:
		var water_targets = targets.filter(func(t): return t.water_access > location.water_access)
		if water_targets:
			target = water_targets.pick_random()
			return target
		return targets.pick_random()
		
	#if need == LOVE:
		#if genes["Female"]:
			#targets.sort_custom(func(t1, t2): return t1.scent_male > t2.scent_male)
			#targets = targets.filter(func(t): return t.scent_male == targets[0].scent_male)
		#else:
			#targets.sort_custom(func(t1, t2): return t1.scent_female > t2.scent_female)
			#targets = targets.filter(func(t): return t.scent_female == targets[0].scent_female)
		#target = targets.pick_random()
		#return target
	if need == LOVE:
		var love_targets:Array = targets.filter(func(t:Tile): return t.scent_list.filter(func(s:Scent): return s["Female"] ))
		# if any neighbouring tiles have an appropriate scent
		if love_targets:
			for l_target:Tile in love_targets:
				# compare the next target with the current target
				if target:
					if l_target.scent_list.back()["Strength"] > target.scent_list.back()["Strength"]:
						target = l_target.scent_list.back()
				# no target has been picked yet, so this is the best option so far
				else:
					target = l_target.scent_list.back()
				
			return target
		return targets.pick_random()
		
	return location


func _execute_action_old() -> Action:
	match need:
		FOOD:
			if location.vegetation > 0:
				return Action.EAT
			else:
				_move_target = _sense()
				if _move_target == location:
					return Action.EAT
				else:
					return Action.MOVE
		WATER:
			if location.water_access > water_need:
				return Action.DRINK
			else:
				_move_target = _sense()
				if _move_target:
					return Action.DRINK
				else:
					return Action.MOVE
		LOVE:
			return Action.MOVE
			
			
			#region
			#if not genes["Female"]:
				##_ptn_mates = location.get_creatures().filter(func(c:Creature): return c.genes["Female"] and c.love_need > 10)
				#if _ptn_mates:
					#return Action.MATE
				#else:
					#_move_target = _sense()
					#if _move_target == location:
						#return Action.REST
					#else:
						#return Action.MOVE
			#else:
				#_ptn_mates = location.get_creatures().filter(func(c:Creature): return !c.genes["Female"] and c.love_need > 10)
				#if _ptn_mates:
					## Only males initiate mating code. Interested females will wait in position.
					## This makes mating code more consistent
					#return Action.REST
				#else:
					#_move_target = _sense()
					#if _move_target == location:
						#return Action.REST
					#else:
						#return Action.MOVE
			#endregion
		REST:
			return Action.REST
		_: 
			return Action.DEBUG



## Move methods ##
func _move():
	location = _move_target



## Food methods ##
func _calculate_diet_modifier() -> float:
	return 1.0


func _drink():
	var available = location.water_access
	var drank = min(available, water_need)
	if drank:
		water_need -= drank


func _eat():
	var available = location.vegetation
	var eaten = min(available, food_need)
	if eaten:
		location.vegetation -= eaten
		food_need -= eaten



## Reproduction methods ##
func _mate():
	if _ptn_mates:
		var c:Creature = _ptn_mates.pick_random()
		love_need -= 10
		c.love_need = 0
		impregnate(c)


func impregnate(c:Creature):
	c.pregnant[0] = true
	c.pregnant[1] = 10	#TODO: add gestation period to genes
	var baby_genes = genes
	baby_genes = _mix_parents(c.genes, genes)
	_mutate(baby_genes)
	c.pregnant[2] = baby_genes


func _mix_parents(mum, dad):
	var baby_genes = {
		"Size" : 20,
		"Speed" : 50,
		"Senses" : 50,
		"Diet" : 10,
		"Maturity" : 50,
		"Female" : true,
		"Lifespan" : 1000
	}
	var keys = baby_genes.keys()
	for key in keys:
		baby_genes[key] = mum[key] if randi_range(0,1) else dad[key]
	return baby_genes


func _mutate(g):
	var keys = g.keys()
	for key in keys:
		if key == "Female":
			pass
		else:
			var chance = randi_range(0,2)
			if not chance:
				g[key] += randi_range(-3,3)





## Death methods ##
func _check_death():
	if food_need > 100.0:
		_die()
	if water_need > 100:
		_die()
	if age > genes["Lifespan"]:
		_die()


func _die():
	location.meat += genes["Size"] * (1.0 - food_need) / 100
	queue_free()



## Mouse methods ##
func _on_mouse_entered():
	_highlighted = true


func _on_mouse_exited():
	_highlighted = false





###############################################################################
### Deprecated methods
# energy consumption rules:
#	existing costs 1 hunger per turn
#	moving costs 2 hunger per turn
#	mating costs 1 hunger per turn
#	being pregnant costs 1 hunger per turn
func consume_energy_old():
	var used = 1
	if _action == Action.MOVE:
		used += 2
	if _action == Action.MATE:
		used += 1
	if pregnant:
		used += 1
	food_need += used


func _move_random():
	var coin_flip = randi_range(0,1)
	if coin_flip:
		var move_options = location.get_overlapping_tiles().filter(func(option): return option.biome[BIOME_ID] != Globals.Biome_ID.OCEAN and option.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN)
		location = move_options.pick_random()
		food_need += 2
	else:
		food_need += 1


func _move_old():
	var options = location.get_overlapping_tiles()
	var target = options.pick_random()
	location = target
	position = location.global_position


func eat_old():
	var available = location.vegetation
	var eaten = min(available, 5)
	if eaten > 0:
		location.vegetation -= eaten
		food_need -= eaten


func _reproduce_old():
	var chance = randi_range(0, 100)
	if chance <= 2:
		birth.emit(self)
		food_need += 50


