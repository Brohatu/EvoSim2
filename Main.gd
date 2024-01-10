extends Node2D


var world:World
var terrain_done:bool = false

func _ready():
	world = $World as World
	world.generate_new_world()

#func _process(_delta):
	#if !terrain_done:
		#world.generate_world_terrain()
		#terrain_done = true


func _on_button_pressed():
	world.generate_world_terrain()
