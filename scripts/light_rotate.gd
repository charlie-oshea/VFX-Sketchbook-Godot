extends DirectionalLight3D

@export var speed := 2.0

func _process(delta: float) -> void:
	rotation_degrees.x += delta * speed
