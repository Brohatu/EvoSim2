extends CharacterBody2D




func move(target:Vector2):
	var move_dir:Vector2 = target - global_position
	move_dir = move_dir.normalized()
	move_and_slide()

func eat():
	pass
