extends Camera2D

var zoom_min = Vector2(0.4, 0.4)
var zoom_max = Vector2(1.5,1.5)
var zoom_speed = Vector2(0.21,0.21)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("zoom_out") and zoom > zoom_min:
		zoom -= zoom_speed
	if Input.is_action_just_pressed("zoom_in") and zoom < zoom_max:
		zoom += zoom_speed 

