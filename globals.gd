extends Node

func save_to_file(location: String, content):
	var file = FileAccess.open("user://%s.dat" % location, FileAccess.WRITE)
	file.store_string(content)

func load_from_file(location: String):
	var file = FileAccess.open("user://%s.dat" % location, FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	return content
