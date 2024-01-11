extends Node2D


var world:World
var terrain_done:bool = false


func _ready():
	world = $World as World
	#world.position = Vector2(-world.parameters.dimensions.x/2.0, -world.parameters.dimensions.y/2.0) * 100
	world.generate_new_world()

#func _process(_delta):
	#if !terrain_done:
		#world.generate_world_terrain()
		#terrain_done = true


func _on_control_generate():
	world.generate_world_terrain()
	

