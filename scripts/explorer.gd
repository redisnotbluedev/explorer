extends Control


@onready var files: VBoxContainer = $Scroll/Files
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
	var node: Button = Button.new()
	node.text = ("F: " if item["type"] == "file" else "D: ") + item["name"]
	if item["type"] == "folder":
		node.pressed.connect(_on_item_clicked.bind(item["name"]))
	else:
		node.pressed.connect(OS.shell_open.bind(item["path"]))
	files.add_child(node)

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
		for file in dir.get_files():
			items.append({"type": "file", "name": file, "path": curr.path_join(file)})
		for folder in dir.get_directories():
			items.append({"type": "folder", "name": folder, "path": curr.path_join(folder)})
		items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["name"] < b["name"])
		
		for item in items:
			process_item(item)
	else:
		print("error")
