extends DirectionalLight3D

@export var speed := 1

func _process(delta: float) -> void:
	rotation_degrees.x += delta * speed

func _input(event):
	if event.is_action_pressed("ui_up"):
		speed += 1
	if event.is_action_pressed("ui_down"):
		speed -= 1
	if event.is_action_pressed("ui_accept"):
		toggle_speed()

func toggle_speed():
	if speed != 0:
		speed = 0
	else:
		speed = 1
