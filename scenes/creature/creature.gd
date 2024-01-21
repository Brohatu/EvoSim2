extends Area2D

class_name Creature

signal creature_data(creature)
signal birth(parent)

const BIOME_ID = 0

@export var genes:Genes
var location:Tile:
	set(val):
		location = val
		global_position = val.global_position
var hunger:float = 50.0
@export var age:int = 0
var highlighted:bool = false

func _ready():
	genes = Genes.new()

func _process(_delta):
	if Input.is_action_just_pressed("select") and highlighted:
		creature_data.emit(self)

func process_turn():
	age += 1
	if hunger > 100.0:
		die()
	if age >= genes.lifespan:
		die()
	if age >= genes.sexual_maturity and hunger < 30:
		reproduce()
		
	if hunger > 10.0:
		eat()
	move_random()


func reproduce():
	var chance = randi_range(0, 100)
	if chance <= 2:
		birth.emit(self)
		hunger += 50

func die():
	location.carrion += 110.0 - hunger
	queue_free()

func move_random():
	var coin_flip = randi_range(0,1)
	if coin_flip:
		var move_options = location.get_overlapping_areas().filter(func(option:Tile): return option.biome[BIOME_ID] != Globals.Biome_ID.OCEAN and option.biome[BIOME_ID] != Globals.Biome_ID.MOUNTAIN)
		location = move_options.pick_random()
		hunger += 2
	else:
		hunger += 0.5


func move_old(target:Vector2):
	var move_dir:Vector2 = target - global_position
	move_dir = move_dir.normalized()
	#move_and_slide()

func move():
	var options = location.get_overlapping_areas()
	var target = options.pick_random()
	location = target
	position = location.global_position

func eat():
	var available = location.vegetation
	var eaten = min(available, 5.0)
	if eaten > 0.0:
		location.vegetation -= eaten
		hunger -= eaten
	



func _on_mouse_entered():
	highlighted = true


func _on_mouse_exited():
	highlighted = false
