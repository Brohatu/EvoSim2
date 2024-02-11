extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass




func get_overlapping_tiles() -> Array:
	#var tiles = get_overlapping_areas().filter(func(t): return t.collision_layer == 1)
	return get_overlapping_areas()
