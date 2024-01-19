extends Node3D

@onready var animation_player = $AnimationPlayer

func ready():
	animation_player.play("explode")
