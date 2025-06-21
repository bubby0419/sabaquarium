extends Node

const SAVE_PATH := "user://save_game.json"

func save_game(state: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.ModeFlags.WRITE)
	if file:
		file.store_string(JSON.stringify(state))
		file.close()
	else:
		push_error("SaveManager: couldn’t open %s for writing" % SAVE_PATH)

func load_game() -> Dictionary:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.ModeFlags.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var res = JSON.parse_string(text)
			if res is Dictionary:
				return res
			push_error("SaveManager: JSON parse error: %s" % res.error_string)
		else:
			push_error("SaveManager: couldn’t open %s for reading" % SAVE_PATH)
	return {}
	
func clear_save() -> void:
	save_game({})
