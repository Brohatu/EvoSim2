extends Node2D

var creature_scene:PackedScene = preload("res://scenes/creature/creature.tscn")

var world:World
var terrain_done:bool = false
var turn:int = 0
var creature:Creature
var new_creatures:Array = []


func _ready():
	world = $World as World
	#world.position = Vector2(-world.parameters.dimensions.x/2.0, -world.parameters.dimensions.y/2.0) * 100
	generate_world()
	

func _process(_delta):
	#if Input.is_action_pressed("centre_camera"):
		#move_camera(get_global_mouse_position())
	if Input.is_action_pressed("camera_up"):
		move_camera(Vector2.UP)
	if Input.is_action_pressed("camera_left"):
		move_camera(Vector2.LEFT)
	if Input.is_action_pressed("camera_right"):
		move_camera(Vector2.RIGHT)
	if Input.is_action_pressed("camera_down"):
		move_camera(Vector2.DOWN)


func add_new_creature(loc):
	var new_creature = creature_scene.instantiate() as Creature
	new_creature.location = loc  
	new_creature.scale = Vector2(0.3,0.3) * ((new_creature.age+1)/new_creature.genes.sexual_maturity)
	new_creature.connect("creature_data", display_creature_data)
	new_creature.connect("birth", reproduce)
	$Creatures.add_child(new_creature)
	return new_creature

func reproduce(baby_genes:Genes, parent_location):
	var baby:Creature = add_new_creature(parent_location)
	baby.genes = baby_genes
	baby.scale = Vector2(0.3,0.3) * (baby.age+1)/baby.genes.sexual_maturity
	

func generate_world():
	world.generate_world_tiles()
	for t:Tile in get_tree().get_nodes_in_group("Tiles"):
		t.connect("place_creature", add_new_creature)
		t.connect("tile_data", display_tile_data)


func display_creature_data(c:Creature):
	$UI.display_creature(c)


func display_tile_data(t:Tile):
	$UI.display_tile(t)



func _on_control_generate():
	world.reset()
	for c in $Creatures.get_children():
		c.queue_free()
	world.generate_world_terrain()
	$UI.reset()
	$TurnTimer.paused = false
	$TurnTimer.stop()
	turn = 0

func move_camera(pos):
	$MainCamera.position += pos * 10




func _on_turn_timer_timeout():
	for child in world.tiles:
		child.process_turn()
	for child in $Creatures.get_children():
		child.process_turn()
	$UI.update()
	turn += 1
	$UI/Header/TurnCounter.text = str("Turn: ", turn)




func _on_control_pause(paused):
	$TurnTimer.paused = paused


func _on_control_start():
	$TurnTimer.start()
