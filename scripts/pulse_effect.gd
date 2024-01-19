extends MeshInstance3D

var distance := 0.0
var is_running := false

@export var max_distance := 20.0
@export var speed := 2.0

@onready var _SHADER:ShaderMaterial = get_active_material(0)
@onready var camera: Camera3D = $".."


func _process(delta: float) -> void:
	if is_running:
		distance += delta * speed
		if distance > max_distance:
			is_running = false
			distance = 0.0
		_SHADER.set_shader_parameter("radius", distance)
	
	if Input.is_action_just_pressed("ui_accept"):
		_SHADER.set_shader_parameter("start_point", camera.global_transform.origin)
		is_running = true
		distance = 0.0
