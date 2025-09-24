extends Node3D

var speed: float = 0

func _process(delta: float) -> void:
	rotation_degrees += Vector3(0, speed, 0) * delta
