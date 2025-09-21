extends Node3D

func _process(delta: float) -> void:
	rotation_degrees += Vector3(0, 10, 0) * delta
