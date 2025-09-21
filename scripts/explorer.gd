extends Node3D


@onready var files: VBoxContainer = VBoxContainer.new()
var dir: DirAccess = DirAccess.open("C:/")

func _ready() -> void:
	update_explorer()

func _on_item_clicked(name) -> void:
	var error: Error = dir.change_dir(name)
	if error == OK:
		update_explorer()
	else:
		print("Error " + error_string(error))

func process_item(item: Dictionary) -> void:
	print(item["name"])

func clear_list() -> void:
	for child in files.get_children():
			child.queue_free()

func update_explorer() -> void:
	if dir:
		clear_list()
		
		if dir.dir_exists(".."):
			var node: Button = Button.new()
			node.text = "(parent directory)"
			node.pressed.connect(_on_item_clicked.bind(".."))
			files.add_child(node)
		
		var items: Array[Dictionary] = []
		var curr: String = dir.get_current_dir()
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var item: Dictionary = {
				"type": "folder" if dir.current_is_dir() else "file",
				"name": file_name,
				"path": curr.path_join(file_name)
			}
			items.append(item)
			file_name = dir.get_next()
		
		items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["name"] < b["name"])
		
		for item in items:
			process_item(item)
	else:
		print("error")
