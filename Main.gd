extends Node2D


var world:World
var terrain_done:bool = false


func _ready():
	world = $World as World
	#world.position = Vector2(-world.parameters.dimensions.x/2.0, -world.parameters.dimensions.y/2.0) * 100
	world.generate_new_world()
	for t:Tile in get_tree().get_nodes_in_group("Tiles"):
		t.connect("move_camera", on_tile_move_camera)

#func _process(_delta):
	#if !terrain_done:
		#world.generate_world_terrain()
		#terrain_done = true
	#if Input.CURSOR_DRAG
	


func _on_control_generate():
	world.reset()
	world.generate_world_terrain()

func on_tile_move_camera(pos):
	$MainCamera.position = pos
