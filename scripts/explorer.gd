extends Node3D

@onready var sun: Node3D = $Sun/Planets
var extensions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/extensions.json"))
var planets: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/planets.json"))
var dir: DirAccess = DirAccess.open("C:")
var spiral_index: int = 0  # Track position in spiral

func _ready() -> void:
	update_explorer()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query)
		
		if result:
			on_item_clicked(result.collider)
		else:
			print("no.")

func on_item_clicked(item: Area3D) -> void:
	if item.get_meta("type", "file") == "folder":
		var error: Error = dir.change_dir(item.get_meta("path", "C:"))
		if error == OK:
			update_explorer()
		else:
			print("Error while navigating: " + error_string(error))
	else:
		var error: Error = OS.shell_open(item.get_meta("path", "C:"))
		if error != OK:
			print("Error while opening file: " + error_string(error))

func process_item(item: Dictionary) -> void:
	var planet: Dictionary = planets[hash(item["category"]) % len(planets)]
	var palettes: PackedColorArray = []
	seed(item["created"])
	
	# Golden spiral positioning
	var golden_angle: float = 137.5  # Golden angle in degrees
	var angle: float = spiral_index * golden_angle
	var radius: float = sqrt(spiral_index) * 0.8 + 1.5  # Adjust multiplier to control spacing
	var speed: float = randf_range(1, 5)
	
	for _i in range(len(planet["colours"])):
		palettes.append(Color(randf_range(0, 1), randf_range(0, 1), randf_range(0, 1)))
	
	var parent: Node3D = Node3D.new()
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var model: SphereMesh = SphereMesh.new()
	mesh.mesh = model
	var file_size: int = max(item["size"], 1)
	var size: float = lerp(0.3, 1.5, clamp(log(file_size) / log(1000000000), 0.0, 1.0))
	model.radius = size / 2
	model.height = size
	var material: ShaderMaterial = ShaderMaterial.new()
	var shader: Shader = Shader.new()
	shader.code = FileAccess.get_file_as_string("res://assets/shaders/palette.gdshader")
	material.shader = shader
	material.set_shader_parameter(&"base_texture", load(planet["path"]))
	material.set_shader_parameter(&"colours_from", planet["colours"])
	material.set_shader_parameter(&"colours_to", palettes)
	material.set_shader_parameter(&"active_swaps", len(palettes))
	material.set_shader_parameter(&"thresholds", planet["thresholds"])
	model.material = material
	var body: Area3D = Area3D.new()
	var collider: CollisionShape3D = CollisionShape3D.new()
	var shape: SphereShape3D = SphereShape3D.new()
	collider.shape = shape
	shape.radius = size / 1.5
	body.input_ray_pickable = true
	body.input_capture_on_drag = true
	body.monitorable = true
	body.monitoring = true
	body.collision_layer = 2
	body.collision_mask = true
	body.set_meta("path", item["path"])
	body.set_meta("type", item["type"])
	var text: Label3D = Label3D.new()
	text.text = item["name"]
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.add_child(text)
	text.position = Vector3(0, size / 2 + 0.2, 0)
	text.rotation_degrees = Vector3(-90, -90, 0)
	body.add_child(collider)
	parent.add_child(body)
	body.add_child(mesh)
	
	# Position using spiral coordinates
	body.position = Vector3(
		cos(deg_to_rad(angle)) * radius, 
		0, 
		sin(deg_to_rad(angle)) * radius
	)
	
	parent.set_script(load("res://scripts/spin.gd"))
	parent.speed = speed
	sun.add_child(parent)
	spiral_index += 1

func clear_list() -> void:
	for child in sun.get_children():
		child.queue_free()
	spiral_index = 0  # Reset spiral position

func update_explorer() -> void:
	if dir:
		clear_list()
		
		if dir.dir_exists(".."):
			# TODO add this
			pass
		
		var items: Array[Dictionary] = []
		var curr: String = dir.get_current_dir()
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var path: String = curr.path_join(file_name)
			var extension: String = ""
			var size: int = 0
			if "." in file_name:
				extension = file_name.split(".")[-1]
			
			if dir.current_is_dir():
				var sizecheck: DirAccess = DirAccess.open(path)
				if sizecheck:
					size = sizecheck.get_directories().size() * 1000 + sizecheck.get_files().size() * 700
			else:
				size = FileAccess.get_size(path)
			
			var item: Dictionary = {
				"type": "folder" if dir.current_is_dir() else "file",
				"name": file_name,
				"path": path,
				"category": extensions.get(extension, "unknown"),
				"size": size,
				"created": FileAccess.get_modified_time(path) # replace with correct method when you figure out how
			}
			items.append(item)
			file_name = dir.get_next()
		
		items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["name"] < b["name"])
		
		for item in items:
			process_item(item)
		
		$UI.update_path(curr)
	else:
		print("error")
